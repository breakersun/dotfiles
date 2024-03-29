#!/bin/bash

set -e # Exit on Error

cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
set -x # Log Executions
sudo apt-add-repository ppa:fish-shell/release-3
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install openssh-server fish neovim curl git ripgrep tmux -y
sudo apt upgrade -y
# ssh-keygen -t ed25519 -C "admin@tseknet.com"
# eval `ssh-agent -s`
# ssh-add
# chmod 0700 ~/.ssh # Ensure correct permissions
# set +x
# echo -e 'Copy to https://github.com/settings/ssh/new'
# echo -e "\033[32m" ;cat ~/.ssh/id_ed25519.pub; echo -e "\033[0m"
# read -p 'Press any key to continue...'

# Install chezmoi
set -x
cd ~

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply breakersun
# export PATH=$HOME/bin:$PATH
# chezmoi init --apply --verbose https://github.com/breakersun/dotfiles.git

git clone https://github.com/breakersun/nvim ./.config/nvim

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
