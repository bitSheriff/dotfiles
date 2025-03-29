#!/bin/bash

DIR_NAME=$(dirname "$0")

# shellcheck source=/dev/null
source "$DIR_NAME/../lib/my_lib.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../lib/logos.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../lib/cache.sh"
# shellcheck source=/dev/null
source "$DIR_NAME/../lib/distributions.sh"

FILE_UNCHANGED=0
FILE_CHANGED=1
FILE_CHECKSUM_NOT_FOUND=2
FILE_NOT_FOUND=3


create_checksum() {
    FILE_NAME=$1
    MD5_FILE="${FILE_NAME}.md5"

    md5sum "$FILE_NAME" | awk '{ print $1 }' > "$MD5_FILE"
}

check_file_checksum() {
    FILE_NAME=$1
    MD5_FILE="${FILE_NAME}.md5"

    if [[ ! -f "$FILE_NAME" ]]; then
        return $FILE_NOT_FOUND
    fi

    if [[ -f "$MD5_FILE" ]]; then
        NEW_MD5=$(md5sum "$FILE_NAME" | awk '{ print $1 }')
        OLD_MD5=$(cat "$MD5_FILE")

        if [[ "$NEW_MD5" != "$OLD_MD5" ]]; then
            return $FILE_CHANGED
        else
            return $FILE_UNCHANGED
        fi
    else
        return $FILE_CHECKSUM_NOT_FOUND
    fi
}

encrypt_file() {
    FILE_NAME=$1

    age -e -a -i "$AGE_KEY_DOTFILES" -o "$FILE_NAME.age" "$FILE_NAME"
}

decrypt_file() {
    FILE_NAME=$1

    if [[ -f "$FILE_NAME.age" ]]; then
        age -d -i "$AGE_KEY_DOTFILES" -o "$FILE_NAME" "$FILE_NAME.age"
    else
        print_warning "Warning: Encrypted file $FILE_NAME.age does not exist."
        encrypt_file "$FILE_NAME"
    fi
}

check_updates() {
    FILE_NAME=$1
    check_file_checksum "$FILE_NAME"
    result=$?

    case $result in
        "$FILE_CHANGED")
            encrypt_file "$FILE_NAME"
            create_checksum "$FILE_NAME"
            create_checksum "$FILE_NAME.age"
            print_note "File $FILE_NAME has changed."
            ;;
        "$FILE_UNCHANGED")
            decrypt_file "$FILE_NAME"
            print_note "File $FILE_NAME is unchanged."
            # now it needs to be checked if the .age file has changed -> update from the server
            if [[ -f "$FILE_NAME.age" ]]; then
                check_file_checksum "$FILE_NAME.age"
                age_result=$?
                if [[ $age_result -eq "$FILE_CHANGED" ]]; then
                    print_note "Updating $FILE_NAME.age from server..."
                    decrypt_file "$FILE_NAME"
                    create_checksum "$FILE_NAME"
                    create_checksum "$FILE_NAME.age"
                fi
            fi
            ;;
        "$FILE_CHECKSUM_NOT_FOUND")
            decrypt_file "$FILE_NAME"
            create_checksum "$FILE_NAME"
            create_checksum "$FILE_NAME.age"
            print_note "Checksum file for $FILE_NAME not found."
            ;;
        "$FILE_NOT_FOUND")
            print_note "File $FILE_NAME not found."
            decrypt_file "$FILE_NAME"
            create_checksum "$FILE_NAME"
            ;;
    esac
}

secret_main() {
    print_h1 "Secrets"

    if [[ ! -f "$AGE_KEY_DOTFILES" ]]; then
        echo "Error: Key file $AGE_KEY_DOTFILES does not exist."
        exit 1
    fi

    FILE_LIST="$DOTFILES_DIR/setup/secret_files.txt"

    if [[ ! -f "$FILE_LIST" ]]; then
        echo "Error: File list $FILE_LIST does not exist."
        exit 1
    fi

    FILES=()

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Ignore empty lines and lines starting with #
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        # Replace environment variables in the line
        eval line="$line"
        check_updates "$line"
    done < "$FILE_LIST"

}

secret_main
