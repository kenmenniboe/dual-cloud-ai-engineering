#!/bin/bash

# Prompt the user for a file or directory name
echo "Enter the name of a file or directory:"
read filename

# Check if the input exists
if [ -e "$filename" ]; then
    # Check if it's a regular file
    if [ -f "$filename" ]; then
        echo "$filename is a regular file."

    # Check if it's a directory
    elif [ -d "$filename" ]; then
        echo "$filename is a directory."

    # If it exists but is neither file nor directory (like a special file, socket, etc.)
    else
        echo "$filename is another type of file (not regular file or directory)."
    fi

    # Perform long listing
    echo ""
    echo "Long listing:"
    ls -l "$filename"

else
    echo "File or directory does not exist, or I do not have permissions to access it."
fi






