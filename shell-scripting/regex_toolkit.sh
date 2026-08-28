#!/bin/bash
# Simple regex-based text processing menu, built on top of `sed`.
#
# Usage: ./regex_toolkit.sh

read -p "Enter your file name: " filename

if [[ ! -f "$filename" ]]; then
    echo "File not found!"
    exit 1
fi

while true; do
    echo "Menu: please choose"
    echo "1) Show lines matching a regex pattern"
    echo "2) Search & replace text matching a regex pattern"
    echo "3) Count lines matching a regex pattern"
    echo "4) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            read -p "Enter regex to search: " regex_search
            echo "Lines matching your regex:"
            sed -n "/$regex_search/p" "$filename"
            ;;
        2)
            read -p "Enter your regex pattern: " search_pattern
            read -p "Enter replacement text: " replace_text
            sed -i "s/$search_pattern/$replace_text/g" "$filename"
            echo "Changes applied to your file."
            ;;
        3)
            read -p "Enter your regex pattern: " regex_to_count
            matching_lines_count=$(sed -n "/$regex_to_count/p" "$filename" | wc -l)
            echo "Matching lines: $matching_lines_count"
            ;;
        4)
            echo "Bye"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
done
