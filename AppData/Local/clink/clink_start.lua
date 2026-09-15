os.setenv("CLAUDE_CODE_NEW_INIT", "1")

os.setenv("MCP_OCR_PROVIDER", "custom")

-- Load secrets from separate file (not versioned)
local script_dir = debug.getinfo(1, "S").source:match("^@(.*)[\\/]")
local secrets_path = script_dir .. "\\secrets.lua"
local secrets = dofile(secrets_path) or {}

os.setenv("MCP_OCR_API_KEY", secrets.ocr)
os.setenv("MCP_OCR_BASE_URL", "https://api.lkeap.cloud.tencent.com/plan/v3")
os.setenv("MCP_OCR_MODEL", "kimi-k2.5")

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

local _headroom_job = nil

local function start_headroom()
    local backend_url = os.getenv("ANTHROPIC_TARGET_API_URL")
    if not backend_url or backend_url == "" then
        print("[-] No backend URL. Run: set-claude-env <profile>")
        return
    end
    print("[+] backend: " .. backend_url)

    -- 检查是否已在运行
    local check = io.popen('tasklist /fi "imagename eq headroom.exe" 2>nul | find /c "headroom"')
    if check then
        local count = tonumber(check:read("*a")) or 0
        check:close()
        if count > 0 then
            print("[!] headroom already running. Run: stop-headroom first")
            return
        end
    end

    -- start /b 后台运行
    local cmd = string.format('start /b "" headroom proxy --port 8787 --backend anthropic')
    os.execute(cmd)
    print("[+] headroom started on port 8787")
end

local function stop_headroom()
    local f = io.popen('taskkill /f /im headroom.exe 2>nul')
    local output = f:read("*a") or ""
    f:close()

    if output:find("SUCCESS") or output:find("成功") then
        print("[+] headroom stopped")
    else
        print("[-] headroom not running")
    end
end

local function headroom_status()
    local f = io.popen('tasklist /fi "imagename eq headroom.exe" 2>nul')
    local output = f:read("*a") or ""
    f:close()

    if output:find("headroom") then
        print("[+] headroom is running")
        -- 检查端口
        local port_check = io.popen('netstat -ano | findstr :8787 2>nul')
        if port_check then
            local port_out = port_check:read("*a") or ""
            port_check:close()
            if port_out ~= "" then
                print("[+] port 8787 is listening")
            else
                print("[!] port 8787 not listening")
            end
        end
    else
        print("[-] headroom is not running")
    end
end

local function use_headroom()
    -- os.setenv("ANTHROPIC_BASE_URL", "http://localhost:8787")
    -- print("[+] ANTHROPIC_BASE_URL set to http://localhost:8787")

    os.setenv("ANTHROPIC_BASE_URL", "http://10.84.4.67:8788/")
    print("[+] ANTHROPIC_BASE_URL set to http://10.84.4.67:8788")
    print("[!] Ensure headroom is running: start-headroom")
end

local set_parser = clink.arg.new_parser():set_arguments({ "anthropic", "openrouter", "deepseek" })
clink.arg.register_parser("set-claude-env", set_parser)
clink.arg.register_parser("show-claude-env", clink.arg.new_parser())
clink.arg.register_parser("start-headroom", clink.arg.new_parser())
clink.arg.register_parser("stop-headroom", clink.arg.new_parser())
clink.arg.register_parser("headroom-status", clink.arg.new_parser())
clink.arg.register_parser("use-headroom", clink.arg.new_parser())

-- onfilterinput (not onendedit): returned string replaces the input line, so
-- cmd.exe never tries to execute the pseudo-command itself.
clink.onfilterinput(function(line)
    local set_cmd, profile = line:match("^%s*(set%-claude%-env)%s+(%S+)")
    if set_cmd then apply_profile(profile) return "", false end

    if line:match("^%s*show%-claude%-env%s*$") then show_current_profile() return "", false end

    if line:match("^%s*start%-headroom%s*$") then start_headroom() return "", false end

    if line:match("^%s*stop%-headroom%s*$") then stop_headroom() return "", false end

    if line:match("^%s*headroom%-status%s*$") then headroom_status() return "", false end

    if line:match("^%s*use%-headroom%s*$") then use_headroom() return "", false end

    local superclaude_args = line:match("^%s*superclaude%s*(.*)$")
    if superclaude_args then
        print("[+] Starting superclaude...")
        return 'claude --dangerously-skip-permissions ' .. superclaude_args, false
    end
end)
