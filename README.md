# Dotfiles 🛠

## Installing

Below are the commands you can run to get started with my dotfiles.

⚠ Be sure to review the code before executing random scripts on the internet. TL;DR can be found in [install.ps1](install.ps1) Comment-Based Help.

### Windows

Run the following command in PowerShell as administrator:

```powershell
iex ((New-Object Net.WebClient).DownloadString('https://git.io/JSSoD'))
```

## Usage

```bash
chezmoi init --apply --verbose https://github.com/breakersun/dotfiles.git
# OR
chezmoi init --apply --verbose git@github.com:breakersun/dotfiles.git
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)