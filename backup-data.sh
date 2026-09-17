#!/usr/bin/env bash
# Resolve invoking user's home even when run via sudo
INVOKING_USER="${SUDO_USER:-$USER}"
INVOKING_HOME=$(getent passwd "$INVOKING_USER" | cut -d: -f6)
source "$INVOKING_HOME/.bc/backup.conf"

log="$INVOKING_HOME/.bc/log/data-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$log") 2>&1

# Build --exclude args (works under sudo, no /dev/fd tricks)
exclude_args=()
for pat in "${DATA_EXCLUDE[@]}"; do
    exclude_args+=(--exclude "$pat")
done

for src in "${DATA_SOURCES[@]}"; do
    src="${src/#\~/$INVOKING_HOME}"
    [[ -d "$src" ]] || { echo "WARN: $src does not exist, skipping"; continue; }

    size_mb=$(du -sm "$src" 2>/dev/null | cut -f1)
    if [[ -n "$size_mb" && $size_mb -gt $SIZE_LIMIT_MB ]]; then
        echo "SKIP: $src is ${size_mb}MB > ${SIZE_LIMIT_MB}MB limit"
        continue
    fi

    dest="$DATA_DEST$src"
    mkdir -p "$(dirname "$dest")"

    rsync -av --delete "${exclude_args[@]}" "$src/" "$dest/"
done
