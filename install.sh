#!/bin/bash

set -e # Exit on Error
set -o pipefail # curl|bash-style pipes must not fail silently

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
# keepassxc: headless boxes only need keepassxc-cli (vault export); Ubuntu ships
# no cli-only package, the GUI libs ride along unused. (operator decision 2026-09-28)
# git-delta/gh/git-lfs: referenced by the applied .gitconfig — absent = git log/diff break.
APT_PKGS=(openssh-server curl git ripgrep \
              tmux build-essential \
              unzip fd-find keepassxc git-delta gh git-lfs)

# Clipboard tooling is environment-specific:
# - WSL: wl-clipboard only (WSLg bridges the Windows clipboard via Wayland;
#   pi uses wl-paste as its primary read path)
# - desktop Linux (DISPLAY present): xclip
# - headless servers: neither — nothing to clip into
if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
    APT_PKGS+=(wl-clipboard)
elif [ -n "${DISPLAY:-}" ]; then
    APT_PKGS+=(xclip)
fi

# Tencent Cloud images point apt at mirrors.tencentyun.com — an internal-only
# name that returns NXDOMAIN when transparent-proxy DNS hijack is active
# (queries leave the internal resolver). Fall back to the public mirror.
if grep -rq "mirrors.tencentyun.com" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null \
   && ! getent hosts mirrors.tencentyun.com >/dev/null 2>&1; then
    echo "mirrors.tencentyun.com unreachable — switching apt to mirrors.cloud.tencent.com"
    sudo sed -i.bak "s|mirrors.tencentyun.com|mirrors.cloud.tencent.com|g" \
        /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null
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

# Tencent images seed ~/.npmrc with the internal-only mirrors.tencentyun.com
# registry — NXDOMAIN under transparent-proxy DNS hijack (same failure class as
# the apt mirror above; sudo npm reads the same file). Point user + root at the
# public npmmirror registry when the internal one is configured.
if npm config get registry 2>/dev/null | grep -q tencentyun; then
    npm config set registry https://registry.npmmirror.com
    sudo npm config set registry https://registry.npmmirror.com
fi

# ── Vault-first: github identity comes from the KeePassXC vault ──
# The vault's leosunsl key IS breakersun's github key (fingerprint-verified).
# Everything below that touches git@github.com depends on it, so vault setup
# must succeed before any clone. No throwaway id_ed25519, no manual pubkey paste.
KDBX="$HOME/.config/keepassxc/keepass-xc.kdbx"
if [ ! -f "$KDBX" ]; then
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
        unset WEBDAV_PASS
        set -x
        echo "FATAL: vault download failed (bad password? offline?) — github steps cannot proceed" >&2
        exit 1
    fi
    unset WEBDAV_PASS
    set -x
fi

# SSH keys: export from vault to ~/.ssh, then load the github key into the agent.
# keepassxc-cli attachment-export <database> <entry> <attachment_name> <export_file>
if [ ! -f "$HOME/.ssh/leosunsl" ] || [ ! -f "$HOME/.ssh/sunlong" ]; then
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    keepassxc-cli attachment-export "$KDBX" "github:leosunsl@outlook.com" leosunsl.pub "$HOME/.ssh/leosunsl.pub"
    keepassxc-cli attachment-export "$KDBX" "github:leosunsl@outlook.com" leosunsl "$HOME/.ssh/leosunsl"
    keepassxc-cli attachment-export "$KDBX" "github:sunlong@tcl.com" sunlong.pub "$HOME/.ssh/sunlong.pub"
    keepassxc-cli attachment-export "$KDBX" "github:sunlong@tcl.com" sunlong "$HOME/.ssh/sunlong"
    chmod 600 "$HOME/.ssh/leosunsl" "$HOME/.ssh/sunlong"
fi
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/leosunsl" || echo "WARN: ssh-add failed — git will prompt for the key on use" >&2

[ -d "$HOME/.config/nvim" ] || git clone git@github.com:breakersun/starter ~/.config/nvim

brew install fzf
brew install starship
brew install zoxide
brew install trzsz-go
brew install difftastic # provides `difft` for .gitconfig diff.external (not in Ubuntu apt)

# Install chezmoi
set -x
cd ~
# Re-runs: chezmoi init does NOT fetch on an existing source dir — pull explicitly
# (the ssh-agent loaded above makes this interactive for passphrase-protected keys).
if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
    git -C "$HOME/.local/share/chezmoi" pull --ff-only \
        || echo "WARN: dotfiles pull failed — applying possibly stale dotfiles" >&2
fi
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:breakersun/dotfiles.git

# pi coding agent (config managed by chezmoi; providers/skills via cc-switch; npm packages auto-install on first pi launch)
# system node from NodeSource lives in /usr -> global installs need sudo (same as workstation)
if ! command -v pi >/dev/null 2>&1; then
    sudo npm install -g @earendil-works/pi-coding-agent
fi

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# docker: skip where already present (e.g. servers provisioned out-of-band);
# the convenience script would still swap apt sources (--mirror Aliyun).
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh --mirror Aliyun
    rm -f get-docker.sh
fi
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
