// clanking.ts — pi extension that turns agent activity into sound cues.
//
// Option A port of the Claude Code plugin in breakersun/clanking: this file only
// translates pi events into the same stdin payloads the CC plugin feeds
// `clanking hook`. The Go binary, daemon, synth, grid, and stereo panning are
// reused unchanged. Daemon spawns itself on first cue; nothing long-lived here.
//
// pi event                          -> CC hook payload                    -> cue
// ---------------------------------------------------------------------------------
// tool_execution_start (top-level)  -> PreToolUse {tool_name}             -> tick
//   toolName === "subagent"         -> SubagentStart                      -> spawn
// tool_execution_end (subagent)     -> SubagentStop                       -> return
// ui_prompt_start kind=confirm      -> PermissionRequest                  -> permission
// ui_prompt_start kind=other        -> PreToolUse {AskUserQuestion}       -> ask
// message_start (assistant)         -> MessageDisplay {index:0}           -> reply
// agent_before_settle completed      -> Stop                               -> done
// agent_before_settle error         -> StopFailure                        -> failed
// agent_before_settle aborted       -> (nothing; Esc needs no sound)
//
// Known gaps vs CC (accepted): no TaskCreated/TaskCompleted in pi; async
// subagent children start/stop outside this session's tool events, so only the
// "subagent" tool call itself is heard. Nested codemode tool calls are filtered
// via parentToolCallId so one model-visible call ticks once, like CC.

import { spawn } from "node:child_process";
import { execFile } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const BIN = process.env.CLANKING_BIN || "clanking";

// Fire-and-forget: spawn the CLI, hand it a CC-shaped hook payload, never let a
// sound failure touch the session. detached+unref so pending cues survive a
// quick pi exit, mirroring CC's async hook execution.
function cue(event: string, cwd: string, extra?: Record<string, unknown>): void {
	try {
		const child = spawn(BIN, ["hook"], { stdio: ["pipe", "ignore", "ignore"], detached: true });
		child.on("error", () => {});
		child.stdin.on("error", () => {});
		child.stdin.end(JSON.stringify({ hook_event_name: event, cwd, ...extra }));
		child.unref();
	} catch {
		// never break the session over a sound
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_execution_start", (event, ctx) => {
		if (event.parentToolCallId) return; // nested calls: one tick per model-visible call
		if (event.toolName === "subagent") {
			cue("SubagentStart", ctx.cwd);
			return;
		}
		cue("PreToolUse", ctx.cwd, { tool_name: event.toolName });
	});

	pi.on("tool_execution_end", (event, ctx) => {
		if (event.parentToolCallId || event.toolName !== "subagent") return;
		cue("SubagentStop", ctx.cwd);
	});

	pi.on("ui_prompt_start", (event, ctx) => {
		if (event.kind === "confirm") {
			cue("PermissionRequest", ctx.cwd);
		} else {
			cue("PreToolUse", ctx.cwd, { tool_name: "AskUserQuestion" });
		}
	});

	pi.on("message_start", (event, ctx) => {
		if (event.message.role !== "assistant") return;
		cue("MessageDisplay", ctx.cwd, { index: 0 });
	});

	pi.on("agent_before_settle", (event, ctx) => {
		if (event.outcome === "completed") cue("Stop", ctx.cwd);
		else if (event.outcome === "error") cue("StopFailure", ctx.cwd);
		// aborted: user pressed Esc; they are present, stay quiet
	});

	pi.registerCommand("clank", {
		description: "Clanking soundscape: /clank [status|toggle|mute|unmute|volume <db>|tempo <bpm>|root <midi>]",
		handler: async (args, ctx) => {
			const argv = (args || "status").trim().split(/\s+/).filter(Boolean);
			await new Promise<void>((resolve) => {
				execFile(BIN, argv, { timeout: 5000 }, (err, stdout, stderr) => {
					const out = (stdout || stderr || (err ? String(err) : "")).trim();
					ctx.ui.notify(out || "clanking: (no output)", err ? "warning" : "info");
					resolve();
				});
			});
		},
	});
}
