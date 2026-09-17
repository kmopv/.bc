#!/usr/bin/env bash
# TUI for enabling/disabling schedules, setting hours, triggering backups

BACKUP_CONF="$HOME/.bc/etc/backup.conf"
source "$BACKUP_CONF"

# Functions to enable/disable systemd timers
toggle_timer() {
    local timer=$1
    if systemctl is-enabled "$timer" &>/dev/null; then
        sudo systemctl disable --now "$timer"
    else
        sudo systemctl enable --now "$timer"
    fi
}

menu() {
    dialog --clear --title "Backup Control" \
        --menu "Choose action" 15 60 5 \
        1 "Run backup now" \
        2 "Toggle config timer (every 10min)" \
        3 "Toggle data on-boot" \
        4 "Toggle data on-shutdown" \
        5 "Set data hourly (cron-like)" \
        6 "Toggle overwrite confirmation" \
        7 "Exit" 2> /tmp/choice
    case $(< /tmp/choice) in
        1) "$HOME/.bc/bin/backup-all.sh" ;;
        2) toggle_timer backup-config.timer ;;
        # ... etc
    esac
}

while true; do menu; done