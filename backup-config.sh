#!/usr/bin/env bash
# Backup config files – absolute paths only, repo mirrors /
# Skips unchanged files, prints colorful summary.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/backup.conf"

CONFIG_REPO="$HOME/.bc/configs"
CONFIG_FILELIST="$CONFIG_REPO/tracked-files.txt"

cd "$CONFIG_REPO" || { echo "ERROR: cannot cd to $CONFIG_REPO"; exit 1; }

log="$SCRIPT_DIR/log/config-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$log")"
exec > >(tee -a "$log") 2>&1

# -------- ANSI color definitions --------
ORANGE='\033[38;5;208m'
BLUE='\033[94m'
GREEN='\033[32m'
RED='\033[31m'
WHITE='\033[37m'
YELLOW='\033[93m'
YELLOW_BG='\033[43;30m'          # yellow background, black text
LIGHTER_BLUE_BG='\033[44m'        # light blue background
DARK_BLUE_BG='\033[48;5;17m'      # very dark blue background (global)
GRAY='\033[90m'
RESET='\033[0m'

header() {
    local text="=== Config backup started $(date +'%I:%M:%S%p %m.%d.%Y') ======================="
    echo -e "${LIGHTER_BLUE_BG}${text}${RESET}"
    # Switch to dark blue background for the rest of the content
    echo -e "${DARK_BLUE_BG}"
}

footer() {
    local msg="$1"
    # Reset background before printing the light blue footer
    echo -e "${RESET}"
    if [[ -n "$msg" ]]; then
        # Print message on dark blue background (we are still in dark blue mode if we don't reset)
        # Actually we already reset, so we need to reapply dark blue for the message if any
        # But we want the message to appear on dark blue background. So we print it before reset.
        # Let's restructure: we will print the message while still in dark blue mode,
        # then reset and print footer.
        echo -e "${DARK_BLUE_BG}${msg}${RESET}"
    fi
    # Now print light blue footer
    local text="=== Config backup finished ======================="
    echo -e "${LIGHTER_BLUE_BG}${text}${RESET}"
}

# Function to push to multiple remotes (space-separated list)
push_to_remotes() {
    if [[ -z "$GIT_REMOTES" ]]; then
        echo -e "${YELLOW_BG}No remotes configured – push skipped${RESET}"
        return
    fi
    for remote in $GIT_REMOTES; do
        if git remote get-url "$remote" &>/dev/null; then
            if git push "$remote" HEAD 2>/dev/null; then
                echo -e "Pushed to ${BLUE}$remote${RESET}"
            else
                echo -e "${YELLOW_BG}Push to $remote failed${RESET}"
            fi
        else
            echo -e "${YELLOW_BG}Remote '$remote' not configured – push skipped${RESET}"
        fi
    done
}

changed_files=()
missing_files=()

header   # prints light blue header and switches background to dark blue

# Print an empty line to show dark blue bar (optional)
echo

while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    if [[ "$line" != /* ]]; then
        echo -e "${YELLOW_BG}WARN: '$line' is not absolute (must start with /)${RESET}"
        continue
    fi

    src="$line"
    dest="$CONFIG_REPO$line"

    if [[ -d "$src" ]]; then
        echo -e "${YELLOW_BG}WARN: $src is a directory (only files allowed)${RESET}"
        continue
    fi
    if [[ -L "$src" ]] && [[ -d "$src" ]]; then
        echo -e "${YELLOW_BG}WARN: $src is a symlink to a directory${RESET}"
        continue
    fi

    if [[ ! -e "$src" ]]; then
        repo_rel_path="${dest#$CONFIG_REPO/}"
        last_git_info=$(git log -1 --oneline -- "$repo_rel_path" 2>/dev/null | head -1)
        if [[ -n "$last_git_info" ]]; then
            echo -e "${YELLOW}MS${RESET} ${ORANGE}${src}${RESET}  ${GRAY}(last known: ${last_git_info})${RESET}"
        else
            echo -e "${YELLOW}MS${RESET} ${ORANGE}${src}${RESET}"
        fi
        missing_files+=("$src")
        continue
    fi

    mkdir -p "$(dirname "$dest")"

    if [[ -f "$dest" ]] || [[ -L "$dest" ]]; then
        if cmp -s "$src" "$dest" 2>/dev/null; then
            continue
        fi
    fi

    cp -p "$src" "$dest" 2>/dev/null
    echo -e "${GREEN}+${RESET} ${ORANGE}${src}${RESET}"
    changed_files+=("$src")
done < "$CONFIG_FILELIST"

if [[ ${#changed_files[@]} -eq 0 && ${#missing_files[@]} -eq 0 ]]; then
    # No changes: print the message and then footer (footer will reset and print light blue)
    footer " No file changes happened."
    exit 0
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    commit_msg="Auto config backup $(date +'%Y-%m-%d %H:%M:%S')"
    commit_hash=$(git commit -m "$commit_msg" 2>&1 | grep -oE '[0-9a-f]{7,40}' | head -1)
    if [[ -n "$commit_hash" ]]; then
        echo -e "Committed as ${BLUE}${commit_hash}${RESET}"
    else
        echo "Committed (no hash captured)"
    fi
else
    echo -e "${GRAY}No file changes happened.${RESET}"
fi

# Push to all configured remotes
push_to_remotes

# Final footer (will reset and print light blue)
footer ""
