#!/bin/bash

# V Rising ARM64 Container Init Script
# Runs as root to fix permissions, then drops to vrising user

set -e

echo "--- V Rising Init Script ---"
echo "--- Running as: $(whoami) (UID: $(id -u)) ---"

TARGET_UID=1000
TARGET_GID=1000
TARGET_USER="vrising"

# Fix ownership of /data directory (and all subdirectories)
# This is necessary because Docker volumes are often created with root ownership
if [ -d "/data" ]; then
    echo "--- Fixing ownership of /data for user $TARGET_USER ---"
    chown -R $TARGET_UID:$TARGET_GID /data
fi

# Ensure the required directories exist with correct ownership
mkdir -p /data/server /data/save-data /data/wine-prefix
chown -R $TARGET_UID:$TARGET_GID /data

echo "--- Permissions fixed. Dropping to user $TARGET_USER ---"

# Execute the main start script as the vrising user
exec gosu $TARGET_USER /usr/local/bin/start.sh "$@"
