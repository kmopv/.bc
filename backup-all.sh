#!/usr/bin/env bash
INVOKING_USER="${SUDO_USER:-$USER}"
INVOKING_HOME=$(getent passwd "$INVOKING_USER" | cut -d: -f6)
"$INVOKING_HOME/.bc/backup-data.sh"
"$INVOKING_HOME/.bc/backup-config.sh"
