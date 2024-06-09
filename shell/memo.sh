#!/bin/bash

# Preamble of the Memo
MEMO_PRE="- **$(date +%H:%M):** "

# Journal File where the memo gets added
JOURNAL=~/notes/Journal/Entries/Daily/$(date +"%F").md

# decide if the input was given as a positional argument or parsed into (stdin)
if [ $# -gt 0 ]; then
  # If there are arguments, join them into a single string and process
  input="$*"
  echo "$MEMO_PRE" "$input" >> "$JOURNAL"
else
  # Otherwise, read from stdin
  while IFS= read -r line; do
    echo "$MEMO_PRE" "$line" >> "$JOURNAL"
  done
fi
