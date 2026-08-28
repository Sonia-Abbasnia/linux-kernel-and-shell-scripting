#!/bin/bash
# Simple command-line calculator
#
# Usage: ./calculator.sh

read -p "Enter first number: " num1
read -p "Enter operator (+, -, *, /): " op
read -p "Enter second number: " num2

case $op in
    +)
        result=$((num1 + num2))
        echo "Result: $result"
        ;;
    -)
        result=$((num1 - num2))
        echo "Result: $result"
        ;;
    \*)
        result=$((num1 * num2))
        echo "Result: $result"
        ;;
    /)
        if [ "$num2" -eq 0 ]; then
            echo "Error: Division by zero"
        else
            result=$((num1 / num2))
            echo "Result: $result"
        fi
        ;;
    *)
        echo "Error: invalid operator"
        ;;
esac
