os.setenv("CLAUDE_CODE_NEW_INIT", "1")

-- Load secrets from separate file (not versioned)
local script_dir = debug.getinfo(1, "S").source:match("^@(.*)[\\/]")
local secrets_path = script_dir .. "\\secrets.lua"
local secrets = dofile(secrets_path) or {}

local profiles = {
    ['turing'] = {
        url    = "https://live-turing.cn.llm.tcljd.com/api",
        key    = secrets.turing,
        sonnet = "claude-sonnet-4-6",
        haiku  = "claude-haiku-4-5",
        opus   = "claude-opus-4-8"
    },
    ['tencent'] = {
        url    = "https://tokenhub.tencentmaas.com/plan/anthropic",
        key    = secrets.tencent,
        sonnet = "glm-5.1",
        haiku  = "deepseek-v4-pro",
        opus   = "glm-5"
    },
    ['mimo'] = {
        url    = "https://token-plan-cn.xiaomimimo.com/anthropic",
        key    = secrets.mimo,
        sonnet = "mimo-v2.5",
        haiku  = "mimo-v2.5",
        opus   = "mimo-v2.5-pro"
    },
    ['tencent-personal'] = {
        url    = "https://api.lkeap.cloud.tencent.com/plan/anthropic",
        key    = secrets.tencent_personal,
        sonnet = "kimi-k2.5",
        haiku  = "minimax-m2.7",
        opus   = "glm-5.1"
    },
}

local function apply_profile(name)
    local prof = profiles[name]
    if not prof then
        print("[-] Unknown profile. Choice: anthropic, openrouter, deepseek")
        return
    end
    os.setenv("ANTHROPIC_BASE_URL", prof.url)
    os.setenv("ANTHROPIC_TARGET_API_URL", prof.url)
    os.setenv("ANTHROPIC_AUTH_TOKEN", prof.key)
    os.setenv("ANTHROPIC_DEFAULT_SONNET_MODEL", prof.sonnet)
    os.setenv("ANTHROPIC_DEFAULT_HAIKU_MODEL", prof.haiku)
    os.setenv("ANTHROPIC_DEFAULT_OPUS_MODEL", prof.opus)
    print("[+] Switched to [" .. name .. "]")
end

local function show_current_profile()
    local key = os.getenv("ANTHROPIC_AUTH_TOKEN") or ""
    local masked = #key > 12 and (key:sub(1, 8) .. "..." .. key:sub(-4)) or "(not set)"

    print(string.format([=[
Active Claude Code Environment:
  URL:    %s
  KEY:    %s
  SONNET: %s
  HAIKU:  %s
  OPUS:   %s]=],
        os.getenv("ANTHROPIC_BASE_URL") or "(native default)",
        masked,
        os.getenv("ANTHROPIC_DEFAULT_SONNET_MODEL") or "(not set)",
        os.getenv("ANTHROPIC_DEFAULT_HAIKU_MODEL") or "(not set)",
        os.getenv("ANTHROPIC_DEFAULT_OPUS_MODEL") or "(not set)"
    ))
end

local function start_headroom()
    local backend_url = os.getenv("ANTHROPIC_TARGET_API_URL")
    print("[+] backend: " .. backend_url)
    os.execute('headroom proxy --port 8787' .. ' --backend anthropic --anthropic-api-url "' .. backend_url .. '"')
end

local function use_headroom()
    os.setenv("ANTHROPIC_BASE_URL", "http://localhost:8787")
    print("[+] ANTHROPIC_BASE_URL set to http://localhost:8787")
    print("[!] Ensure headroom is running: start-headroom")
end

local set_parser = clink.arg.new_parser():set_arguments({ "anthropic", "openrouter", "deepseek" })
clink.arg.register_parser("set-claude-env", set_parser)
clink.arg.register_parser("show-claude-env", clink.arg.new_parser())
clink.arg.register_parser("start-headroom", clink.arg.new_parser())
clink.arg.register_parser("use-headroom", clink.arg.new_parser())

clink.onendedit(function(line)
    local set_cmd, profile = line:match("^%s*(set%-claude%-env)%s+(%S+)")
    if set_cmd then apply_profile(profile) return end

    if line:match("^%s*show%-claude%-env%s*$") then show_current_profile() return end

    if line:match("^%s*start%-headroom%s*$") then start_headroom() return end

    if line:match("^%s*use%-headroom%s*$") then use_headroom() return end

    local superclaude_args = line:match("^%s*superclaude%s*(.*)$")
    if superclaude_args then
        local cmd = 'claude --dangerously-skip-permissions ' .. (superclaude_args or '')
        print("[+] Starting superclaude: " .. cmd)
        os.execute(cmd)
        return
    end
end)
