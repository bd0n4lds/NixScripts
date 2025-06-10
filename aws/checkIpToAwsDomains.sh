#!/bin/bash

set -euo pipefail

input_file="${1:-}"

usage() {
    echo "Usage: $0 <domains_or_ips_file>" >&2
    exit 1
}

if [[ -z "$input_file" ]]; then
    usage
fi

if [[ ! -f "$input_file" ]]; then
    echo "Error: Input file '$input_file' not found." >&2
    exit 1
fi

output_file="aws_positive_results.csv"
echo "Input,Resolved IPs,AWS Match" > "$output_file"

line_count=$(wc -l < "$input_file")
current_line=1

while IFS= read -r line || [[ -n "$line" ]]; do
    printf "[%d/%d] Processing: %s\r" "$current_line" "$line_count" "$line"

    # Run host and capture output, ignore errors silently
    host_output=$(host "$line" 2>/dev/null || true)

    # Extract IP addresses from host output
    # Match lines with 'has address' or 'address' depending on response
    ips=$(echo "$host_output" | awk '/has address|address/ {print $NF}' | paste -sd "," -)

    # Check if 'amazonaws' appears anywhere in output (case-insensitive)
    if echo "$host_output" | grep -qi "amazonaws"; then
        # Output CSV line: Input,IPs,AWS Match = YES
        echo "\"$line\",\"$ips\",\"YES\"" >> "$output_file"
        echo -e "\n$line: AWS match found (IPs: $ips)"
    fi

    current_line=$((current_line + 1))
done < "$input_file"

echo -e "\nScan complete. Results saved in $output_file"
