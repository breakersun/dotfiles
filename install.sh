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

sudo apt update
sudo apt install openssh-server \
                curl git ripgrep \
                tmux npm xclip build-essential \
                unzip fd-find -y
sudo apt upgrade -y

ssh-keygen -t ed25519 -C "leosunsl@outlook.com"
eval "$(ssh-agent -s)"
ssh-add
chmod 0700 ~/.ssh # Ensure correct permissions
set +x
echo -e 'Copy to https://github.com/settings/ssh/new'
echo -e "\033[32m" ;cat ~/.ssh/id_ed25519.pub; echo -e "\033[0m"
read -p 'Press any key to continue...'
git clone git@github.com:breakersun/starter ~/.config/nvim || echo "Encountered error during git pull. Skipping..."

brew install fzf
brew install starship
brew install zoxide

# Install chezmoi
set -x
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:breakersun/dotfiles.git

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh --mirror Aliyun
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
