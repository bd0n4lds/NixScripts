#!/bin/bash

# Configuration
EMAIL="your.email@address.com"
LOG_FILE="/var/log/auth.log"
SUBJECT="Failed SSH Login Attempts"
LINES=30

# Check if the log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Log file $LOG_FILE not found." >&2
    exit 1
fi

# Extract failed login attempts and send email
FAILED_LOGINS=$(tail -n "$LINES" "$LOG_FILE" | grep -i "failed")

if [[ -n "$FAILED_LOGINS" ]]; then
    echo "$FAILED_LOGINS" | mail -s "$SUBJECT" "$EMAIL"
else
    echo "No failed login attempts found in the last $LINES lines."
fi
