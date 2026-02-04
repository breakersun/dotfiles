#!/bin/bash

set -e # Exit on Error

cd "$HOME" || exit
echo -e "BEEP BOOP. Setting up..."
set -x # Log Executions
#homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> "$HOME/.bashrc"
echo 'eval "$(brew shellenv bash)"' >> "$HOME/.bashrc"
eval "$(brew shellenv bash)"
brew install neovim

sudo apt update
sudo apt install openssh-server \
                curl git ripgrep \
                tmux npm xclip \
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
