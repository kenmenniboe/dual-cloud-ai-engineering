#!/bin/bash

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 file1 [file2 file3 ...]"
    echo "Please provide at least one file or directory name as an argument."
    exit 1
fi

# Loop through all arguments
for filename in "$@"; do
    echo "========================================="
    echo "Checking: $filename"

    # Check if the input exists
    if [ -e "$filename" ]; then
        # Check if it's a regular file
        if [ -f "$filename" ]; then
            echo "$filename is a regular file."

        # Check if it's a directory
        elif [ -d "$filename" ]; then
            echo "$filename is a directory."

        # If it exists but is neither file nor directory
        else
            echo "$filename is another type of file (not regular file or directory)."
        fi

        # Perform long listing
        echo "Long listing:"
        ls -l "$filename"

    else
        echo "File or directory does not exist, or I do not have permissions to access it."
    fi

    echo ""  # Blank line for readability
done
