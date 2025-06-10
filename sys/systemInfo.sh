#!/bin/bash

# Function to print section headers
print_section() {
    echo -e "\e[31;43m***** $1 *****\e[0m"
}

echo ""
print_section "HOSTNAME INFORMATION"
hostnamectl
echo ""

print_section "FILE SYSTEM DISK SPACE USAGE"
df -h
echo ""

print_section "FREE AND USED MEMORY"
free -h
echo ""

print_section "SYSTEM UPTIME AND LOAD"
uptime
echo ""

print_section "CURRENTLY LOGGED-IN USERS"
who
echo ""

print_section "TOP 5 MEMORY-CONSUMING PROCESSES"
ps -eo %mem,%cpu,comm --sort=-%mem | head -n 6
echo ""

echo -e "\e[1;32mDone.\e[0m"
