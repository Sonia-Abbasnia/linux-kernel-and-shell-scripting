#!/bin/bash
# Reads a file line by line and checks each line as both:
#   - an IPv4 address
#   - an Iranian mobile phone number (e.g. 09121234567 or +989121234567)
#
# Usage: ./ip_phone_validator.sh <input_file>

INPUT_FILE="$1"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "File not found!"
    exit 1
fi

while IFS= read -r line; do
    # --- IPv4 check ---
    if [[ "$line" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r a b c d <<< "$line"
        if (( a >= 0 && a <= 255 && b >= 0 && b <= 255 && c >= 0 && c <= 255 && d >= 0 && d <= 255 )); then
            echo "$line: Valid IP"
        else
            echo "$line: Invalid IP"
        fi
    else
        echo "$line: Invalid IP"
    fi

    # --- Iranian phone number check ---
    if [[ "$line" =~ ^09[0-9]{9}$ || "$line" =~ ^\+989[0-9]{9}$ ]]; then
        echo "$line: Valid Phone"
    else
        echo "$line: Invalid Phone"
    fi

done < "$INPUT_FILE"
