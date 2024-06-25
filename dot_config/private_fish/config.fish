
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# sunlong add for spaceship.rs
starship init fish | source

# fzf_key_bindings

fish_add_path -g ~/.local/bin

zoxide init fish | source
