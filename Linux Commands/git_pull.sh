#!/bin/bash

# Use the provided argument or default to the current directory
DIRECTORY=${1:-$(pwd)}

# Find .git directories and perform the operations
find "$DIRECTORY" -type d -name '.git' -execdir sh -c 'git --git-dir="{}" remote get-url origin && git --git-dir="{}" pull' \;
