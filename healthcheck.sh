#!/bin/bash
set -e

# Check if the UDP port 27015 is open
if nc -z -u 127.0.0.1 27015; then
    exit 0
else
    echo "Port 27015/udp not reachable"
    exit 1
fi
