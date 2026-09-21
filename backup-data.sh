#!/usr/bin/env bash
INVOKING_USER="${SUDO_USER:-$USER}"
INVOKING_HOME=$(getent passwd "$INVOKING_USER" | cut -d: -f6)
export HOME="$INVOKING_HOME"
source "$INVOKING_HOME/.bc/backup.conf"

log="$INVOKING_HOME/.bc/log/data-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$log")"
exec > >(tee -a "$log") 2>&1

exclude_args=()
for pat in "${DATA_EXCLUDE[@]}"; do
    exclude_args+=(--exclude "$pat")
done

# --- UNCAPPED sources ---
for src in "${DATA_SOURCES[@]}"; do
    src="${src/#\~/$INVOKING_HOME}"
    [[ -d "$src" ]] || { echo "WARN: $src does not exist, skipping"; continue; }
    dest="$DATA_DEST$src"
    mkdir -p "$(dirname "$dest")"
    rsync -av --delete "${exclude_args[@]}" "$src/" "$dest/"
done

# --- CAPPED sources ---
for src in "${DATA_SOURCES_CAPPED[@]}"; do
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

[[ -n "$SUDO_USER" ]] && chown -R "$INVOKING_USER:$INVOKING_USER" "$INVOKING_HOME/.bc/log" 2>/dev/null
