#!/bin/bash

# awscript.sh - Check if domains/IPs resolve to Amazon AWS and export results to CSV

INPUT="$1"
OUTPUT="${2:-aws_results.csv}"  # Default output file if not specified

# Usage/help message
if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
  echo "Usage: $0 <input_file> [output_file]" >&2
  exit 1
fi

total=$(wc -l < "$INPUT")
count=0

# Write CSV header
echo "Input,Resolved Hostname,Matches AmazonAWS" > "$OUTPUT"

while IFS= read -r item || [[ -n "$item" ]]; do
  count=$((count + 1))
  echo -ne "[$count/$total] Processing: $item\r"

  # Resolve domain or IP
  if [[ "$item" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # IP address: reverse lookup
    result=$(host "$item" 2>/dev/null)
    hostname=$(echo "$result" | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
  else
    # Domain name: forward lookup
    result=$(host "$item" 2>/dev/null)
    hostname=$(echo "$result" | awk '/has address/ {print $4}')
  fi

  # Check if it's AWS
  if [[ "$result" == *"amazonaws"* ]]; then
    match="YES"
  else
    match="NO"
  fi

  echo "\"$item\",\"$hostname\",\"$match\"" >> "$OUTPUT"
done < "$INPUT"

echo -e "\nDone. Results saved to: $OUTPUT"
