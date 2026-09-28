#!/bin/bash

set -e # Exit on Error

cd "$HOME" || exit
echo -e "BEEP BOOP. Setting up..."
set -x # Log Executions
#homebrew
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_BIN="$(command -v brew || true)"
if [ -z "$BREW_BIN" ]; then
    for candidate in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$candidate" ]; then
            BREW_BIN="$candidate"
            break
        fi
    done
fi

if [ -z "$BREW_BIN" ]; then
    echo "Homebrew installation failed" >&2
    exit 1
fi

eval "$($BREW_BIN shellenv)"
if ! grep -Fq 'brew shellenv' "$HOME/.bashrc"; then
    printf '\n%s\n' "eval \"\$($BREW_BIN shellenv)\"" >> "$HOME/.bashrc"
fi

"$BREW_BIN" install neovim

# npm deliberately NOT in APT_PKGS: distro npm drags node 18.x (pi needs >=22.19).
# node comes from NodeSource below; its deb Conflicts/Provides distro npm.
APT_PKGS=(openssh-server curl git ripgrep \
              tmux xclip build-essential \
              unzip fd-find keepassxc)

# wl-clipboard: only needed under WSL — WSLg bridges the Windows clipboard via
# Wayland (wl-paste), which pi uses as its primary clipboard read path.
# Skip on native Linux: X11 desktops and headless boxes are covered by xclip;
# native Wayland desktops can add it manually if desired.
if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
    APT_PKGS+=(wl-clipboard)
fi

sudo apt update
sudo apt install "${APT_PKGS[@]}" -y
# sudo apt upgrade -y  # skipped: full system upgrade not appropriate for install script

# node 24 LTS via NodeSource apt repo (pi requires >=22.19; distro node is 18.x on 24.04).
# Auditable apt-source setup, not curl|bash. Re-run safe: NodeSource's nodejs deb
# declares Conflicts/Provides on distro npm, so apt auto-removes any leftover
# npm from older runs of this script without manual cleanup.
if ! command -v node >/dev/null 2>&1 || \
   [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null)" -lt 24 ]; then
    sudo install -dm 755 /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
        | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
    sudo apt update
fi
sudo apt install -y nodejs

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "leosunsl@outlook.com"
    eval "$(ssh-agent -s)"
    ssh-add
    chmod 0700 ~/.ssh
    set +x
    echo -e 'Copy to https://github.com/settings/ssh/new'
    echo -e "\033[32m"; cat ~/.ssh/id_ed25519.pub; echo -e "\033[0m"
    read -p 'Press any key to continue...'
fi
[ -d "$HOME/.config/nvim" ] || git clone git@github.com:breakersun/starter ~/.config/nvim

brew install fzf
brew install starship
brew install zoxide
brew install trzsz-go

# Install chezmoi
set -x
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:breakersun/dotfiles.git

# KeePassXC vault: one-time pull from WebDAV.
# Password is entered manually each bootstrap — never stored, never logged.
KDBX="$HOME/.config/keepassxc/keepass-xc.kdbx"
if [ -f "$KDBX" ]; then
    echo "vault already present — skipping WebDAV download"
else
    mkdir -p "$(dirname "$KDBX")"
    set +x  # secrets zone: xtrace would echo $WEBDAV_PASS expanded
    read -rsp "WebDAV password for leo@webdav.888521.top: " WEBDAV_PASS; echo
    # creds go via stdin config (-K -), not -u: argv is world-readable in ps
    if printf 'user = "leo:%s"\n' "$WEBDAV_PASS" | \
        curl -fsSL -K - -o "$KDBX" https://webdav.888521.top/keepass-xc/keepass-xc.kdbx \
        && [ "$(head -c4 "$KDBX" | od -An -tx1 | tr -d ' \n')" = "03d9a29a" ]; then
        chmod 600 "$KDBX"
        echo "vault downloaded OK"
    else
        rm -f "$KDBX"   # no partial/garbage file left behind
        echo "WARN: vault download failed (bad password? offline?) — skipping, rerun install.sh to retry" >&2
    fi
    unset WEBDAV_PASS
    set -x
fi

# SSH keys: export from vault to ~/.ssh
# keepassxc-cli attachment-export <database> <entry> <attachment_name> <export_file>
if [ -f "$KDBX" ]; then
    keepassxc-cli attachment-export "$KDBX" "github:leosunsl@outlook.com" leosunsl.pub "$HOME/.ssh/leosunsl.pub"
    keepassxc-cli attachment-export "$KDBX" "github:leosunsl@outlook.com" leosunsl "$HOME/.ssh/leosunsl"
    keepassxc-cli attachment-export "$KDBX" "github:sunlong@tcl.com" sunlong.pub "$HOME/.ssh/sunlong.pub"
    keepassxc-cli attachment-export "$KDBX" "github:sunlong@tcl.com" sunlong "$HOME/.ssh/sunlong"
    chmod 600 "$HOME/.ssh/leosunsl" "$HOME/.ssh/sunlong"
fi

# pi coding agent (config managed by chezmoi; providers/skills via cc-switch; npm packages auto-install on first pi launch)
# system node from NodeSource lives in /usr -> global installs need sudo (same as workstation)
if ! command -v pi >/dev/null 2>&1; then
    sudo npm install -g @earendil-works/pi-coding-agent
fi

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh --mirror Aliyun
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
