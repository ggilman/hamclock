#!/bin/bash

# Ensure /root/.hamclock exists
mkdir -p /root/.hamclock

# Perform an initial synchronization (from /config to /root/.hamclock)
rsync -a /config/ /root/.hamclock/

# Start a background job to continuously sync /root/.hamclock and /config every 5 seconds
while true; do
    rsync -a /root/.hamclock/ /config/
    rsync -a /config/ /root/.hamclock/
    sleep 5
done &

# Run the actual command passed as arguments to this script
exec "$@"
