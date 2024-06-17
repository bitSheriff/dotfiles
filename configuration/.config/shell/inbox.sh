#!/bin/bash

# Preamble of the Memo
INBOX_PRE=""
INBOX_POST=""

# Journal File where the memo gets added
INBOX_FILE=~/notes/Inbox/Inbox.md

# decide if the input was given as a positional argument or parsed into (stdin)
if [ $# -gt 0 ]; then
  # If there are arguments, join them into a single string and process
  input="$*"
  echo -e "\n$input\n" >> "$INBOX_FILE"
else
  # Otherwise, read from stdin
  
  # line conter
  count=0

  while IFS= read -r line; do

    # just print the preamble on the first line
    if [ $count -eq 0 ]; then
      # Process the first line differently
      echo -e "\n$line" >> "$INBOX_FILE"

    else
      # Process the remaining lines
      echo -e "$line" >> "$INBOX_FILE"
    fi

    # Increment the counter
    count=$((count + 1))
  done
  echo -e "\n" >> "$INBOX_FILE"

fi
