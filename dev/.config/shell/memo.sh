#!/bin/bash

# Preamble of the Memo
MEMO_PRE="- **$(date +%H:%M):** "
LINES_PRE="    - "

# Journal File where the memo gets added
JOURNAL=~/notes/Journal/Entries/Daily/$(date +"%F").md

# decide if the input was given as a positional argument or parsed into (stdin)
if [ $# -gt 0 ]; then
  # If there are arguments, join them into a single string and process
  input="$*"
  echo "$MEMO_PRE" "$input" >> "$JOURNAL"
else
  # Otherwise, read from stdin
  
  # line conter
  count=0

  while IFS= read -r line; do

    # just print the preamble on the first line
    if [ $count -eq 0 ]; then
      # Process the first line differently
      echo "$MEMO_PRE" "$line" >> "$JOURNAL"
    else
      # Process the remaining lines
      echo "$LINES_PRE" "$line" >> "$JOURNAL"
    fi

    # Increment the counter
    count=$((count + 1))
  done
fi