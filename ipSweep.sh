#!/bin/bash
# Usage: ./ipsweep.sh 192.168.1 [output.csv]

if [[ -z "$1" ]]; then
  echo "Usage: $0 <subnet-prefix> [output_file]" >&2
  echo "Example: $0 192.168.1 live_hosts.csv" >&2
  exit 1
fi

SUBNET="$1"
OUTPUT="${2:-live_hosts.csv}"  # Default output file
TMP_FILE=$(mktemp)

echo "IP,Hostname" > "$OUTPUT"

echo "Scanning subnet: $SUBNET.0/24 ..."
for ip in $(seq 1 254); do
  host="$SUBNET.$ip"
  (
    if ping -c 1 -W 1 "$host" &> /dev/null; then
      name=$(host "$host" 2>/dev/null | awk '/domain name pointer/ {print $5}' | sed 's/\.$//')
      [[ -z "$name" ]] && name="N/A"
      echo "$host,$name" >> "$TMP_FILE"
      echo "Host up: $host ($name)"
    fi
  ) &
done

wait

# Append to output
sort "$TMP_FILE" >> "$OUTPUT"
rm "$TMP_FILE"

echo "Scan complete. Results saved to: $OUTPUT"
