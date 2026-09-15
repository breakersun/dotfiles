/**
 * brain.js — Tier 1 brain MCP integration for pi
 *
 * Patterns borrowed from the gbrain workspace design (wiki-ipc-projects-ws):
 *  - push protocol: ambient recall injected per turn (silent, budgeted, deduped)
 *  - session start: health check + recent digest (NO SILENT FAILURE)
 *  - deterministic capture: /remember /recall commands (zero LLM tokens)
 *  - fail-open: brain unreachable never blocks the conversation
 *
 * Auth & transport reuse what already exists on this machine:
 *  - server URL from ~/.pi/agent/mcp.json (mcpServers.brain)
 *  - OAuth tokens from the pi-mcp-adapter keyring store (@napi-rs/keyring),
 *    same service/account scheme the adapter itself uses — refreshed tokens
 *    are written back so the adapter and this extension stay in sync
 *  - HTTP via curl (Node fetch ignores proxy env vars; curl always honors them)
 */
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { createRequire } from "node:module";

// ── tunables ────────────────────────────────────────────────────────────────
const RECALL_MIN_PROMPT_LEN = 15;
const RECALL_QUERY_CHARS = 200;
const RECALL_TOP_K = 3;
const RECALL_BUDGET_CHARS = 1800;
const CALL_TIMEOUT_MS = 4000;
const NOTIFY_SLICE = 1200;
const KEYRING_SERVICE = "pi-mcp-adapter.oauth";
const BRAIN_SERVER_NAME = "brain";
const PI_NPM_MODULES = join(homedir(), ".pi", "agent", "npm", "node_modules");

// ── keyring access (same store pi-mcp-adapter uses) ────────────────────────
function loadKeyringEntry() {
  const requireHere = createRequire(import.meta.url);
  const candidates = [
    join(PI_NPM_MODULES, "@napi-rs", "keyring"),
    join(PI_NPM_MODULES, "@napi-rs", "keyring-linux-x64-gnu"),
  ];
  for (const c of candidates) {
    try { return new (requireHere(c).Entry)(KEYRING_SERVICE, keyringAccount()); }
    catch { /* try next */ }
  }
  return null;
}
function keyringAccount() {
  return `sha256-${createHash("sha256").update(BRAIN_SERVER_NAME, "utf8").digest("hex")}`;
}
function readBrainAuth() {
  const entry = loadKeyringEntry();
  if (!entry) return null;
  try {
    const payload = entry.getPassword();
    if (!payload) return null;
    const obj = JSON.parse(payload);
    if (obj.__piMcpAdapterOAuthChunked) return null; // chunked entries unsupported
    const t = obj?.tokens;
    if (!t?.accessToken) return null;
    return obj;
  } catch {
    return null;
  }
}
function writeBrainAuth(auth) {
  const entry = loadKeyringEntry();
  if (!entry) return false;
  try { entry.setPassword(JSON.stringify(auth)); return true; } catch { return false; }
}

// ── curl transport ──────────────────────────────────────────────────────────
function curl(args, timeoutMs) {
  return new Promise((resolve, reject) => {
    const proc = spawn("curl", args, { stdio: ["ignore", "pipe", "pipe"] });
    let out = "", err = "";
    const timer = setTimeout(() => { proc.kill("SIGKILL"); reject(new Error("timeout")); }, timeoutMs + 500);
    proc.stdout.on("data", d => { out += d; });
    proc.stderr.on("data", d => { err += d; });
    proc.on("error", e => { clearTimeout(timer); reject(e); });
    proc.on("close", code => {
      clearTimeout(timer);
      if (code !== 0) return reject(new Error(`curl exit ${code}: ${err.trim() || "failed"}`));
      resolve(out);
    });
  });
}

function splitHeadersBody(out) {
  // last header block wins (proxy CONNECT adds an earlier one)
  const idx = out.lastIndexOf("\r\n\r\n");
  return idx >= 0 ? { head: out.slice(0, idx), text: out.slice(idx + 4) } : { head: "", text: out };
}

async function mcpPost(url, token, sessionId, body, timeoutMs) {
  const args = ["-sS", "--max-time", String(Math.ceil(timeoutMs / 1000)), "-X", "POST",
    "-H", "Content-Type: application/json",
    "-H", "Accept: application/json, text/event-stream",
    "-D", "-"];
  if (token) args.push("-H", `Authorization: Bearer ${token}`);
  if (sessionId) args.push("-H", `Mcp-Session-Id: ${sessionId}`);
  args.push("--data-binary", JSON.stringify(body), url);
  const out = await curl(args, timeoutMs);
  const { head, text } = splitHeadersBody(out);
  const status = Number(/^HTTP\/[\d.]+\s+(\d+)/m.exec(head)?.[1] ?? 0);
  const sid = /^mcp-session-id:\s*(.+)$/im.exec(head)?.[1]?.trim();
  let payload = null;
  for (const line of text.split("\n")) {
    if (!line.startsWith("data:")) continue;
    try {
      const p = JSON.parse(line.slice(5).trim());
      if (p && (p.result !== undefined || p.error !== undefined)) payload = p;
    } catch { /* partial frame */ }
  }
  return { sid, status, payload };
}

// ── OAuth refresh (public client, RFC 8414 discovery) ──────────────────────
let tokenEndpointCache = null;
async function discoverTokenEndpoint(issuer, timeoutMs) {
  if (tokenEndpointCache) return tokenEndpointCache;
  for (const wellKnown of ["/.well-known/oauth-authorization-server", "/.well-known/openid-configuration"]) {
    try {
      const raw = await curl(["-sS", "--max-time", String(Math.ceil(timeoutMs / 1000)), issuer.replace(/\/$/, "") + wellKnown], timeoutMs);
      const doc = JSON.parse(raw);
      if (doc.token_endpoint) { tokenEndpointCache = doc.token_endpoint; return tokenEndpointCache; }
    } catch { /* try next */ }
  }
  throw new Error("token endpoint discovery failed");
}

async function refreshTokens(auth, timeoutMs) {
  const t = auth.tokens;
  const endpoint = await discoverTokenEndpoint(t.issuer ?? new URL(auth.serverUrl).origin, timeoutMs);
  const form = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: t.refreshToken,
    client_id: auth.clientInfo?.clientId ?? "",
  });
  const raw = await curl(["-sS", "--max-time", String(Math.ceil(timeoutMs / 1000)),
    "-H", "Content-Type: application/x-www-form-urlencoded",
    "-H", "Accept: application/json",
    "--data-binary", form.toString(), endpoint], timeoutMs);
  const grant = JSON.parse(raw);
  if (!grant.access_token) throw new Error(grant.error_description ?? grant.error ?? "refresh grant failed");
  const next = {
    ...auth,
    tokens: {
      ...t,
      accessToken: grant.access_token,
      refreshToken: grant.refresh_token ?? t.refreshToken,
      expiresAt: grant.expires_in ? Date.now() / 1000 + grant.expires_in : t.expiresAt,
      scope: grant.scope ?? t.scope,
    },
  };
  writeBrainAuth(next); // keep the adapter's copy in sync
  return next;
}

// ── brain client ────────────────────────────────────────────────────────────
function resolveBrainServer() {
  try {
    const cfg = JSON.parse(readFileSync(join(homedir(), ".pi", "agent", "mcp.json"), "utf8"));
    const entry = cfg?.mcpServers?.brain;
    if (!entry?.url) return null;
    return { url: entry.url.replace(/\/$/, "") };
  } catch {
    return null;
  }
}

export function createBrainClient() {
  const server = resolveBrainServer();
  if (!server) {
    return {
      available: false,
      async call() { throw new Error("brain server not configured in ~/.pi/agent/mcp.json"); },
    };
  }
  let sessionId = null;
  let initPromise = null;
  let auth = null;

  async function token() {
    if (auth?.tokens?.expiresAt && auth.tokens.expiresAt < Date.now() / 1000 + 30) {
      try { auth = await refreshTokens(auth, CALL_TIMEOUT_MS); } catch { /* stale token: try anyway */ }
    }
    return auth?.tokens?.accessToken ?? null;
  }

  async function initialize() {
    const { sid, status, payload } = await mcpPost(server.url, await token(), null, {
      jsonrpc: "2.0", id: 1, method: "initialize",
      params: {
        protocolVersion: "2024-11-05", capabilities: {},
        clientInfo: { name: "pi-brain-ext", version: "1.0.0" },
      },
    }, CALL_TIMEOUT_MS);
    if (status === 401) throw new Error("unauthorized (401) — brain token missing or rejected");
    if (!payload?.result) throw new Error(`MCP initialize failed (HTTP ${status})`);
    sessionId = sid ?? null;
    await mcpPost(server.url, await token(), sessionId, {
      jsonrpc: "2.0", method: "notifications/initialized",
    }, CALL_TIMEOUT_MS).catch(() => {});
    return sessionId;
  }
  function ensureSession() {
    if (sessionId) return Promise.resolve(sessionId);
    initPromise ??= initialize().finally(() => { initPromise = null; });
    return initPromise;
  }

  return {
    available: true,
    async call(tool, args = {}) {
      auth ??= readBrainAuth();
      if (!auth) throw new Error("no brain credentials in keyring (run /mcp-auth brain once)");
      await ensureSession();
      const attempt = () => mcpPost(server.url, auth.tokens.accessToken, sessionId, {
        jsonrpc: "2.0", id: 2, method: "tools/call",
        params: { name: tool, arguments: args },
      }, CALL_TIMEOUT_MS);
      let { status, payload } = await attempt();
      if (status === 401) {
        // the adapter may have refreshed meanwhile — re-read before our own refresh
        const fresh = readBrainAuth();
        if (fresh?.tokens?.accessToken && fresh.tokens.accessToken !== auth.tokens.accessToken) auth = fresh;
        else { try { auth = await refreshTokens(auth, CALL_TIMEOUT_MS); } catch { /* report below */ } }
        sessionId = null;
        await ensureSession();
        ({ status, payload } = await attempt());
      }
      if (status === 401) throw new Error("unauthorized after refresh — run /mcp-auth brain");
      if (payload?.error) throw new Error(payload.error.message ?? "MCP error");
      const result = payload?.result;
      const text = (result?.content ?? []).filter(c => c.type === "text").map(c => c.text).join("\n");
      if (result?.isError) throw new Error(text || "tool error");
      return text;
    },
  };
}

// ── helpers ─────────────────────────────────────────────────────────────────
const ID_RE = /ID:\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/gi;
function extractIds(text) {
  const ids = [];
  for (const m of text.matchAll(ID_RE)) ids.push(m[1]);
  return ids;
}
function stripIds(text) {
  return text.replace(ID_RE, "").replace(/\n{3,}/g, "\n\n").trim();
}

// ── extension ───────────────────────────────────────────────────────────────
export default function brainExtension(pi) {
  const brain = createBrainClient();
  const injectedIds = new Set();
  let recallInFlight = false;

  // 1. session start: health + recent digest (NO SILENT FAILURE)
  pi.on("session_start", async (event, ctx) => {
    if (!["startup", "resume", "fork"].includes(event.reason)) return;
    if (!brain.available) {
      ctx.ui.notify("🧠 brain: mcp.json 中无 brain 服务器配置，记忆功能未启用", "warning");
      return;
    }
    try {
      const recent = await brain.call("list_recent", { n: 3 });
      const count = extractIds(recent).length;
      ctx.ui.notify(`🧠 brain online · 最近 ${count} 条记忆已索引`, "info");
    } catch (e) {
      ctx.ui.notify(`🧠 brain 不可达: ${e.message} — 本会话记忆注入降级`, "warning");
    }
  });

  // 2. per-turn ambient recall (push protocol, silent, budgeted, deduped)
  pi.on("before_agent_start", async (event) => {
    const prompt = (event.prompt ?? "").trim();
    if (prompt.length < RECALL_MIN_PROMPT_LEN) return;
    if (prompt.startsWith("/")) return;
    if (!brain.available || recallInFlight) return;
    recallInFlight = true;
    try {
      const text = await brain.call("recall", {
        query: prompt.slice(0, RECALL_QUERY_CHARS),
        topK: RECALL_TOP_K,
      });
      if (!text || /^\s*$/.test(text) || /\(0 results\)/.test(text)) return;
      const ids = extractIds(text);
      const fresh = ids.filter(id => !injectedIds.has(id));
      if (ids.length > 0 && fresh.length === 0) return; // all seen this session
      ids.forEach(id => injectedIds.add(id));
      const content = stripIds(text).slice(0, RECALL_BUDGET_CHARS);
      if (!content) return;
      return {
        message: {
          customType: "brain-recall",
          content: `[brain ambient recall — 相关历史记忆，供参考，不必复述]\n${content}`,
          display: false, // silence contract: for the model, not the screen
        },
      };
    } catch {
      return; // fail-open (degradation is session_start's job)
    } finally {
      recallInFlight = false;
    }
  });

  // 3. deterministic capture commands (zero LLM tokens)
  pi.registerCommand("remember", {
    description: "直接存入 brain（不经 LLM）。用法: /remember 标题: 内容",
    handler: async (args, ctx) => {
      const input = (args ?? "").trim();
      if (!input) { ctx.ui.notify("用法: /remember 标题: 内容", "warning"); return; }
      const split = input.split(/[:：]/);
      const title = split.shift().trim().slice(0, 80);
      const content = split.join(":").trim() || input;
      try {
        const r = await brain.call("remember", {
          content: `${title}: ${content}`,
          tags: ["pi-extension"],
          source: "pi /remember",
        });
        const id = extractIds(r)[0] ?? "";
        ctx.ui.notify(`🧠 已存储 ${id ? id.slice(0, 8) : ""} — ${title}`, "info");
      } catch (e) {
        ctx.ui.notify(`🧠 存储失败: ${e.message}`, "error");
      }
    },
  });

  pi.registerCommand("recall", {
    description: "语义检索 brain。用法: /recall 关键词",
    handler: async (args, ctx) => {
      const query = (args ?? "").trim();
      if (!query) { ctx.ui.notify("用法: /recall 关键词", "warning"); return; }
      try {
        const r = await brain.call("recall", { query, topK: 5 });
        ctx.ui.notify(r ? r.slice(0, NOTIFY_SLICE) : "(无结果)", "info");
      } catch (e) {
        ctx.ui.notify(`🧠 检索失败: ${e.message}`, "error");
      }
    },
  });
}
