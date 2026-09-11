#!/usr/bin/env bash
# Runs a dry-run of data backup, checks git log, and suggests restore commands
echo "=== Data dry-run ==="
rsync -avn --dry-run "$HOME/Desktop/" "/b$HOME/Desktop/"
echo "=== Recent config commits ==="
git -C "$HOME/.bc/configs" log --oneline -5
echo "To restore a config: cp ~/.bc/configs/home/user/.bashrc ~/"