#!/usr/bin/env bash
# install-aliases.sh — adds backup aliases to bash and fish rc files
# Idempotent: uses marker comments, safe to re-run.

set -e

MARKER_START="# >>> backup aliases >>>"
MARKER_END="# <<< backup aliases <<<"

BASH_RC="$HOME/.bashrc"
FISH_RC="$HOME/.config/fish/config.fish"

BASH_BLOCK=$(cat << 'EOF'
# >>> backup aliases >>>
alias backup='~/.bc/backup-all.sh'
alias backup-data='~/.bc/backup-data.sh'
alias backup-config='~/.bc/backup-config.sh'
alias bcu='~/.bc/backup-and-shutdown.sh'
alias backuptui='~/.bc/backup-tui.sh'
alias track='~/.bc/track-config'
alias untrack='~/.bc/untrack-config'
alias cdf='cd ~/.bc/c && git diff --color-words'
alias cdfl='cd ~/.bc/c && git diff --color-words HEAD~1..HEAD'
alias cdl='cd ~/.bc/c && git log --oneline --graph'
alias cds='cd ~/.bc/c && git status'
alias cdf3='cd ~/.bc/c && git log -p -3 --color=always | perl -pe "print \"\033[44m========================================\033[0m\n\" if /^commit /" | less -R'
alias cdr='_cdr() { cd ~/.bc/c && git show HEAD~$2:$1; }; _cdr'
# <<< backup aliases <<<
EOF
)

FISH_BLOCK=$(cat << 'EOF'
# >>> backup aliases >>>
alias backup='~/.bc/backup-all.sh'
alias backup-data='~/.bc/backup-data.sh'
alias backup-config='~/.bc/backup-config.sh'
alias bcu='~/.bc/backup-and-shutdown.sh'
alias backuptui='~/.bc/backup-tui.sh'
alias track='~/.bc/track-config'
alias untrack='~/.bc/untrack-config'
alias cdf='cd ~/.bc/c; and git diff --color-words'
alias cdfl='cd ~/.bc/c; and git diff --color-words HEAD~1..HEAD'
alias cdl='cd ~/.bc/c; and git log --oneline --graph'
alias cds='cd ~/.bc/c; and git status'
alias cdf3='cd ~/.bc/c; and git log -p -3 --color=always | perl -pe "print \"\033[44m========================================\033[0m\n\" if /^commit /" | less -R'
function cdr
    cd ~/.bc/c
    git show HEAD~$argv[2]:$argv[1]
end
# <<< backup aliases <<<
EOF
)

add_block() {
    local file="$1"
    local block="$2"
    local label="$3"

    # Ensure parent dir exists (fish config may not)
    mkdir -p "$(dirname "$file")"
    touch "$file"

    if grep -qF "$MARKER_START" "$file"; then
        echo "✅ $label: aliases already present (skipped)"
        return
    fi

    # Ensure file ends with a newline before appending
    [[ -s "$file" && "$(tail -c1 "$file")" != "" ]] && echo "" >> "$file"

    printf "\n%s\n" "$block" >> "$file"
    echo "✅ $label: aliases added to $file"
}

add_block "$BASH_RC" "$BASH_BLOCK" "bash"
add_block "$FISH_RC" "$FISH_BLOCK" "fish"

echo ""
echo "Reload your shell:"
echo "  bash: source ~/.bashrc"
echo "  fish: source ~/.config/fish/config.fish"
