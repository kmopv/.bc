#!/usr/bin/env bash
# Backup config files – absolute paths only, repo mirrors /
# Skips unchanged files, prints colorful summary.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/backup.conf"

CONFIG_REPO="$HOME/.bc/c"
CONFIG_FILELIST="$CONFIG_REPO/tracked-files.txt"

cd "$HOME/.bc" || { echo "ERROR: cannot cd to ~/.bc"; exit 1; }

log="$SCRIPT_DIR/log/config-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$log")"
exec > >(tee -a "$log") 2>&1

# -------- ANSI colors --------
HEADER_BG='\033[48;5;24m'              # dim blue
SEP_BG='\033[48;5;236m'                # dark gray separator
ORANGE='\033[38;5;208m'                # path text
DIM_ORANGE='\033[38;5;172m'            # dimmer orange (messages)
GREEN_PLUS='\033[38;5;46;48;5;22m'     # bright green on dark green bg
YELLOW='\033[38;5;220m'                # missing marker
GRAY='\033[90m'
YELLOW_BG='\033[43;30m'
RESET='\033[0m'

# Fixed-width bars
HEADER_TEXT="=== Config backup started $(date +'%I:%M:%S%p %m.%d.%Y') ======================="
FOOTER_TEXT="=== Config backup finished ======================="
WIDTH=${#HEADER_TEXT}
SEP=$(printf '%*s' "$WIDTH" '')

header() {
    echo -e "${HEADER_BG}${HEADER_TEXT}${RESET}"
    echo -e "${SEP_BG}${SEP}${RESET}"
}

footer() {
    local msg="$1"
    if [[ -n "$msg" ]]; then
        local pad=$((WIDTH - ${#msg}))
        [[ $pad -lt 0 ]] && pad=0
        printf "${SEP_BG}%s%*s${RESET}\n" "$msg" "$pad" ""
    else
        echo -e "${SEP_BG}${SEP}${RESET}"
    fi
    echo -e "${HEADER_BG}${FOOTER_TEXT}${RESET}"
}

changed=0
missing=0

header

while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    if [[ "$line" != /* ]]; then
        echo -e "${YELLOW_BG}WARN: '$line' is not absolute${RESET}"
        continue
    fi

    src="$line"
    dest="$CONFIG_REPO$line"

    if [[ -d "$src" ]]; then
        echo -e "${YELLOW_BG}WARN: $src is a directory${RESET}"
        continue
    fi

    if [[ ! -e "$src" ]]; then
        repo_rel="c$line"
        last=$(git log -1 --oneline -- "$repo_rel" 2>/dev/null | head -1)
        if [[ -n "$last" ]]; then
            echo -e "${YELLOW}MS${RESET}    ${ORANGE}${src}${RESET}  ${GRAY}(last known: ${last})${RESET}"
        else
            echo -e "${YELLOW}MS${RESET}    ${ORANGE}${src}${RESET}"
        fi
        missing=$((missing+1))
        continue
    fi

    mkdir -p "$(dirname "$dest")"

    if [[ -f "$dest" ]] && cmp -s "$src" "$dest" 2>/dev/null; then
        continue
    fi

    cp -p "$src" "$dest" 2>/dev/null
    echo -e "${GREEN_PLUS}+${RESET}     ${ORANGE}${src}${RESET}"
    changed=$((changed+1))
done < "$CONFIG_FILELIST"

if [[ $changed -eq 0 && $missing -eq 0 ]]; then
    footer " No file changes happened."
    exit 0
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    git add -A
    msg="Auto config backup $(date +'%Y-%m-%d %H:%M:%S')"
    hash=$(git commit -m "$msg" 2>&1 | grep -oE '[0-9a-f]{7,40}' | head -1)
    [[ -n "$hash" ]] && echo -e "Committed as ${DIM_ORANGE}${hash}${RESET}"
fi

if [[ -n "$GIT_REMOTES" ]]; then
    for remote in $GIT_REMOTES; do
        if git remote get-url "$remote" &>/dev/null; then
            git push "$remote" HEAD 2>/dev/null \
                && echo "Pushed to $remote" \
                || echo -e "${YELLOW_BG}Push to $remote failed${RESET}"
        else
            echo -e "${DIM_ORANGE}Remote '$remote' not configured – skipping${RESET}"
        fi
    done
else
    echo -e "${DIM_ORANGE}No remotes configured – push skipped${RESET}"
fi

footer ""
