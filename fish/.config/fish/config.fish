if status is-interactive
    fish_vi_key_bindings
    atuin init fish | source
    starship init fish | source

    function fzf-complete-from-tmux
        tmux capture-pane -pS -100 | \
            tail -r | \
            rg -o "[\w\d_\-\./]+" | \
            awk 'length($0) >= 5 && !seen[$0]++ { print }' | \
            fzf --height=40% --no-sort --exact +i
    end

    function fzf_complete_tmux
        set -l result (fzf-complete-from-tmux 2>/dev/null)
        if test $status -eq 0
            commandline -i "$result"
            commandline -f repaint
        end
    end

    bind \cT fzf_complete_tmux
    bind \cT -M insert fzf_complete_tmux
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/maxim/.cache/lm-studio/bin
# End of LM Studio CLI section

