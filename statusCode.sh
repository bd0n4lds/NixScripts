#!/usr/bin/env bash
#
# http-info.sh – Fetch status, size, redirect target, and <title> for many hosts.
# Author: bd0n4lds 
# Version: 2025-06-09

set -euo pipefail

###############################################################################
# Defaults
###############################################################################
LIST_FILE=""
THREADS=5
STATUS_FILTER=""
OUTPUT_FILE=""
PATH_SUFFIX=""
USE_COLOR=true
VERSION="2025-06-09"

###############################################################################
# Colour helpers
###############################################################################
COL_GREEN=$'\e[32m'; COL_BLUE=$'\e[34m'; COL_RED=$'\e[31m'; COL_RESET=$'\e[0m'

colour() {                # colour <text>
  $USE_COLOR || { printf '%s' "$1"; return; }
  case $1 in
    2*) printf '%s%s%s' "$COL_GREEN" "$1" "$COL_RESET" ;;
    3*) printf '%s%s%s' "$COL_BLUE"  "$1" "$COL_RESET" ;;
    4*) printf '%s%s%s' "$COL_RED"   "$1" "$COL_RESET" ;;
    *) printf '%s' "$1" ;;
  esac
}

###############################################################################
# Usage
###############################################################################
usage() {
  cat <<EOF
$0 – Query HTTP endpoints.
Options:
  -l FILE   List of domains/IPs (required)
  -t NUM    Threads (default: 5)
  -s CODE   Only show lines whose status starts with CODE (e.g. 200, 30, 4)
  -o FILE   Save raw results (no colours) to FILE
  -p PATH   Extra path (e.g. /robots.txt)
  -n        No colour output
  -v        Show version
  -h        Show this help

Example:
  $0 -l hosts.txt -t 20 -o results.txt -s 200
EOF
}

###############################################################################
# Argument parsing
###############################################################################
while getopts ":l:t:s:o:p:nvh" opt; do
  case $opt in
    l) LIST_FILE=$OPTARG      ;;
    t) THREADS=$OPTARG        ;;
    s) STATUS_FILTER=$OPTARG  ;;
    o) OUTPUT_FILE=$OPTARG    ;;
    p) PATH_SUFFIX=$OPTARG    ;;
    n) USE_COLOR=false        ;;
    v) echo "$VERSION"; exit 0 ;;
    h) usage; exit 0          ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    *) echo "Unknown option: -$OPTARG"             >&2; exit 1 ;;
  esac
done

[[ -z $LIST_FILE ]] && { echo "Error: -l FILE is required." >&2; usage; exit 1; }
[[ ! -r $LIST_FILE ]] && { echo "Error: cannot read $LIST_FILE" >&2; exit 1; }

###############################################################################
# Core worker
###############################################################################
fetch_info() {             # fetch_info <host>
  local host=$1
  local path="${PATH_SUFFIX#/}"           # trim leading slash if present
  [[ -n $path ]] && path="/$path"

  # Get status code, final URL, bytes, redirect target (4 values)
  local curl_line
  curl_line=$(curl -sk --connect-timeout 10 -o /dev/null \
    -w "%{http_code} %{url_effective} %{size_download} %{redirect_url}\n" \
    "$host$path" 2>/dev/null)

  # Early exit if we couldn’t connect
  [[ -z $curl_line ]] && return

  # Extract <title>
  local title
  title=$(curl -sk --connect-timeout 10 "$host$path" | \
          grep -iPo '(?<=<title>)(.*)(?=</title>)' | head -n1)

  local status_code=${curl_line%% *}      # first field
  local coloured
  coloured=$(colour "$status_code")

  # Status filtering
  if [[ -z $STATUS_FILTER || $status_code == "$STATUS_FILTER"* ]]; then
    printf '%s %s [%s]\n' "$coloured" "${curl_line#* }" "$title"
  fi

  # Raw output to file (always uncoloured)
  [[ -n $OUTPUT_FILE ]] && printf '%s [%s]\n' "$curl_line" "$title" >> "$OUTPUT_FILE"
}

export -f fetch_info colour PATH_SUFFIX STATUS_FILTER OUTPUT_FILE USE_COLOR
export COL_GREEN COL_BLUE COL_RED COL_RESET

###############################################################################
# Kick off
###############################################################################
if (( THREADS > 1 )); then
  xargs -a "$LIST_FILE" -I{} -P "$THREADS" -- bash -c 'fetch_info "$@"' _ {}
else
  while IFS= read -r host; do fetch_info "$host"; done < "$LIST_FILE"
fi
