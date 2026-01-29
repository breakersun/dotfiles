#!/bin/bash

set -e # Exit on Error

cd "$HOME" || return
echo -e "BEEP BOOP. Setting up..."
set -x # Log Executions
sudo apt-add-repository ppa:fish-shell/release-3 -y
sudo apt update
sudo apt install openssh-server fish neovim curl git ripgrep tmux npm xclip -y
sudo apt upgrade -y

#homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo >> /home/leo/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/leo/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

ssh-keygen -t ed25519 -C "leosunsl@outlook.com"
eval `ssh-agent -s`
ssh-add
chmod 0700 ~/.ssh # Ensure correct permissions
set +x
echo -e 'Copy to https://github.com/settings/ssh/new'
echo -e "\033[32m" ;cat ~/.ssh/id_ed25519.pub; echo -e "\033[0m"
read -p 'Press any key to continue...'
git clone git@github.com:breakersun/starter ~/.config/nvim || echo "Encountered error during git pull. Skipping..."

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

curl -sS https://starship.rs/install.sh | sh

# Install chezmoi
set -x
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:breakersun/dotfiles.git

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh --mirror Aliyun
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
