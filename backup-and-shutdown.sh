#!/usr/bin/env bash
INVOKING_USER="${SUDO_USER:-$USER}"
INVOKING_HOME=$(getent passwd "$INVOKING_USER" | cut -d: -f6)
"$INVOKING_HOME/.bc/backup-all.sh" && sudo shutdown -h now
