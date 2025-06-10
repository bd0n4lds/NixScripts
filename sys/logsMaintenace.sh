#!/bin/bash

# Configuration
LOG_DIR="/var/log"
ARCHIVE_DIR="$LOG_DIR/oldlogs"
OUTPUT_LOG="$LOG_DIR/oldlog_output"
DAYS_OLD=14

# Ensure the archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Change to log directory
cd "$LOG_DIR" || {
    echo "Failed to change directory to $LOG_DIR" >> "$OUTPUT_LOG"
    exit 1
}

# Find and move old .gz files
find . -iname "*.gz" -type f -atime +"$DAYS_OLD" -print0 | while IFS= read -r -d '' file; do
    mv "$file" "$ARCHIVE_DIR" >> "$OUTPUT_LOG" 2>&1
done
