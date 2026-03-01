#!/bin/bash
set -e

# Default to 0 (root) if PUID/PGID are not passed
USER_ID=${PUID:-0}
GROUP_ID=${PGID:-0}

echo "Starting HamClock..."
echo "User ID: $USER_ID"
echo "Group ID: $GROUP_ID"

# Backend Configuration
# Resolve backend URL from BACKEND_PRESET or BACKEND_URL
BACKEND_ARG=""

if [ -n "$BACKEND_URL" ]; then
    # Direct URL takes priority
    BACKEND_ARG="-b $BACKEND_URL"
    echo "Backend: $BACKEND_URL (custom)"
elif [ -n "$BACKEND_PRESET" ]; then
    # Use preset
    case "$BACKEND_PRESET" in
        hamclock)
            BACKEND_ARG="-b hamclock.com:80"
            echo "Backend: hamclock.com:80 (W4BAE's server)"
            ;;
        ohb)
            BACKEND_ARG="-b ohb.hamclock.app:80"
            echo "Backend: ohb.hamclock.app:80 (Open HamClock Backend)"
            ;;
        original)
            BACKEND_ARG="-b clearskyinstitute.com:80"
            echo "Backend: clearskyinstitute.com:80 (original - deprecated June 2026)"
            ;;
        *)
            echo "Warning: Unknown BACKEND_PRESET '$BACKEND_PRESET', using default"
            ;;
    esac
else
    echo "Backend: Using HamClock default"
fi

if [ "$USER_ID" -ne 0 ]; then
    # Modify the internal hamuser to match the requested IDs
    groupmod -o -g "$GROUP_ID" hamuser
    usermod -o -u "$USER_ID" hamuser

    # Ensure the config volume is writable by this user
    chown -R hamuser:hamuser /config
    chown -R hamuser:hamuser /home/hamuser

    # Execute as hamuser with backend arg if specified
    if [ -n "$BACKEND_ARG" ]; then
        exec su-exec hamuser "$@" $BACKEND_ARG
    else
        exec su-exec hamuser "$@"
    fi
else
    # Execute as root (Legacy Mode) with backend arg if specified
    if [ -n "$BACKEND_ARG" ]; then
        exec "$@" $BACKEND_ARG
    else
        exec "$@"
    fi
fi
