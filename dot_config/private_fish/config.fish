
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# sunlong add for spaceship.rs
starship init fish | source

fzf_key_bindings

set -Ua fish_user_paths /home/leo/.local/bin
set -Ua fish_user_paths /home/leo/bin
