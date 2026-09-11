#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/backup.conf"

log="$SCRIPT_DIR/log/data-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$log") 2>&1

for src in "${DATA_SOURCES[@]}"; do
    # Expand ~
    src="${src/#\~/$HOME}"
    [[ -d "$src" ]] || { echo "WARN: $src does not exist, skipping"; continue; }

    # Check size
    size_mb=$(du -sm "$src" | cut -f1)
    if [[ $size_mb -gt $SIZE_LIMIT_MB ]]; then
        echo "SKIP: $src is ${size_mb}MB > ${SIZE_LIMIT_MB}MB limit"
        continue
    fi

    dest="$DATA_DEST$src"
    mkdir -p "$(dirname "$dest")"

    # rsync: -a preserves symlinks as symlinks (default), -v for verbose
    # We also add --delete to mirror deletions (optional; toggle via config)
    rsync -av --progress --delete --exclude-from=<(printf "%s\n" "${DATA_EXCLUDE[@]}") "$src/" "$dest/"
done
