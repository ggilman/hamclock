#!/bin/bash
set -e

# Default to 0 (root) if PUID/PGID are not passed
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

echo "Starting HamClock..."
echo "User ID: $USER_ID"
echo "Group ID: $GROUP_ID"

if [ "$USER_ID" -ne 0 ]; then
    # Modify the internal hamuser to match the requested IDs
    groupmod -o -g "$GROUP_ID" hamuser
    usermod -o -u "$USER_ID" hamuser

    # Ensure the config volume is writable by this user
    chown -R hamuser:hamuser /config
    chown -R hamuser:hamuser /home/hamuser

    # Execute as hamuser
    exec su-exec hamuser "$@"
else
    # Execute as root (Legacy Mode)
    exec "$@"
fi
