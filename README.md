# Dotfiles 🛠

## Installing

Below are the commands you can run to get started with my dotfiles.

⚠ Be sure to review the code before executing random scripts on the internet. TL;DR can be found in [install.ps1](install.ps1) Comment-Based Help.

### Windows

Run the following command in PowerShell as administrator:

```powershell
iex ((New-Object Net.WebClient).DownloadString('https://git.io/JSSoD'))
```

```bash
bash <(curl -s https://raw.githubusercontent.com/breakersun/dotfiles/main/install.sh)
```

## Usage

```bash
chezmoi init --apply --verbose https://github.com/breakersun/dotfiles.git
# OR
chezmoi init --apply --verbose git@github.com:breakersun/dotfiles.git
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Troubleshooting Notes

### pi-agent 图片粘贴 (Alt+V / Ctrl+V) 不生效

- **先查窗口管理器**：GlazeWM（含其它全局热键工具：YASB、PowerToys、AutoHotkey、中文输入法）会全局拦截 `Alt+字母`，按键到不了终端里的 pi。GlazeWM 默认就占用了 `Alt+V`。
- **诊断**：在终端里跑 `cat -v`，按 `Alt+V` —— 无输出说明被 Windows 侧截胡（显示 `^[v` 则按键已送达）。
- **现状**（2026-09）：Windows Terminal 已放行 `Ctrl+V`（解除绑定），pi 的 `~/.pi/agent/keybindings.json` 绑定 `["ctrl+v", "alt+v"]`。若未来又失效，优先检查 GlazeWM 配置或 IME 状态。
- **剪贴板链路**（WSL）：`wl-paste`（需 `wl-clipboard`，install.sh 仅在 WSL 时安装）→ `xclip` → PowerShell `Get-Clipboard` 兑底；Node 进程需 `NODE_USE_ENV_PROXY=1`（已在 `.bashrc`）。

## License

[MIT](https://choosealicense.com/licenses/mit/)
