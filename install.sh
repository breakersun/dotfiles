#!/bin/bash

set -e # Exit on Error

cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
set -x # Log Executions
sudo apt-add-repository ppa:fish-shell/release-3 -y
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install openssh-server fish neovim curl git ripgrep tmux npm -y
sudo apt upgrade -y
ssh-keygen -t ed25519 -C "leosunsl@outlook.com"
eval `ssh-agent -s`
ssh-add
chmod 0700 ~/.ssh # Ensure correct permissions
set +x
echo -e 'Copy to https://github.com/settings/ssh/new'
echo -e "\033[32m" ;cat ~/.ssh/id_ed25519.pub; echo -e "\033[0m"
read -p 'Press any key to continue...'
git clone git@github.com:breakersun/nvim.git || echo "Encountered error during git pull. Skipping..."

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

curl -sS https://starship.rs/install.sh | sh

# Install chezmoi
set -x
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply breakersun

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
