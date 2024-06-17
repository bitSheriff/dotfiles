#!/bin/bash

# Preamble of the Memo
INBOX_PRE=""
INBOX_POST=""

# Journal File where the memo gets added
INBOX_FILE=~/notes/Journal/Entries/Daily/$(date +"%F").md

# decide if the input was given as a positional argument or parsed into (stdin)
if [ $# -gt 0 ]; then
  # If there are arguments, join them into a single string and process
  input="$*"
  echo "$INBOX_PRE" "$input" "$INBOX_POST" >> "$INBOX_FILE"
else
  # Otherwise, read from stdin
  
  # line conter
  count=0

  while IFS= read -r line; do

    # just print the preamble on the first line
    if [ $count -eq 0 ]; then
      # Process the first line differently
      echo "$INBOX_PRE" "$line" "$INBOX_POST" >> "$INBOX_FILE"

    else
      # Process the remaining lines
      echo "$INBOX_PRE" "$line" "$INBOX_POST" >> "$INBOX_FILE"
    fi

    # Increment the counter
    count=$((count + 1))
  done
fi
