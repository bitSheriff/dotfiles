#!/bin/bash

# Preamble of the Memo
INBOX_PRE=""
INBOX_POST=""

# Journal File where the memo gets added
INBOX_FILE="$INBOX"
INBOX_DIR="$(dirname -- $INBOX_FILE)"

OPTSTRING=":cn"

create_inbox_file() {

  # line conter
  count=0
  filename=""

  while IFS= read -r line; do

    # just print the preamble on the first line
    if [ $count -eq 0 ]; then
      # the first line is the name of the file
      filename="$INBOX_DIR/$line.md"

      # write the name of the file as first Heading
      echo -e "# $line" >> "$filename"

    else
      # Process the remaining lines
      echo -e "$line" >> "$filename"
    fi

    # Increment the counter
    count=$((count + 1))
  done
}


while getopts ${OPTSTRING} opt; do
  case ${opt} in
    c) # clipboard option
      echo -e "\n$(wl-paste)" >> "$INBOX_FILE"
      exit 0
      ;;
    n) # create new file
      create_inbox_file
      exit 0;
  esac
done


# decide if the input was given as a positional argument or parsed into (stdin)
if [ $# -gt 0 ]; then
  # If there are arguments, join them into a single string and process
  input="$*"
  echo -e "\n$input\n" >> "$INBOX_FILE"
else
  # Otherwise, use gum write to get the input (stdin)
  input=$(gum write --header "Inbox" --show-line-numbers)

  # line conter
  local count=0

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
  done <<< "$input"

  echo -e "\n" >> "$INBOX_FILE"

fi
