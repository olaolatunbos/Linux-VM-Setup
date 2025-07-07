#!/bin/bash

URL="http://localhost:8080"
LOG="/var/log/app.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

status_code=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$status_code" -eq 200 ]; then
    echo "$TIMESTAMP: Healthcheck PASSED (200)" | sudo tee -a "$LOG"
else
    echo "$TIMESTAMP: Healthcheck FAILED (HTTP $status_code)" | sudo tee -a "$LOG"
fi