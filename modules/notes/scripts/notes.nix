{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "notes";
  runtimeInputs = [
    pkgs.fd
    pkgs.fzf
    pkgs.ripgrep
    pkgs.glow
    pkgs.gnused
    pkgs.gawk
    pkgs.findutils
    pkgs.coreutils
  ];
  text = ''
    # Ensure NOTES_DIR is set
    if [[ -z "''${NOTES_DIR:-}" ]]; then
        echo "Error: NOTES_DIR is not set. Please set it to the directory where your notes are stored."
        exit 1
    fi

    editor="nvim" # default editor, override with -e/--editor

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -e | --editor)
            if [[ -z "''${2:-}" ]]; then
                echo "Error: $1 requires an argument." >&2
                exit 1
            fi
            editor="$2"
            shift 2
            ;;
        -h | --help)
            echo "Usage: notes [-e|--editor PROGRAM]"
            echo "  -e, --editor PROGRAM  Program to open the selected note with (default: nvim)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'" >&2
            exit 1
            ;;
        esac
    done

    # Search notes by file name first (fuzzy, highest priority) and fall back
    # to full-text content matches when the query doesn't hit a file name.
    # fd/rg already respect .gitignore and skip dotdirs, but the Obsidian
    # trash/config dirs are excluded explicitly to be safe either way.
    _notes_search() {
        local query="$1"
        local fd_opts=(--type f --extension md --exclude .trash --exclude .obsidian)

        if [[ -z "$query" ]]; then
            fd "''${fd_opts[@]}"
            return
        fi

        local name_matches content_matches
        name_matches="$(fd "''${fd_opts[@]}" | fzf -f "$query" 2>/dev/null || true)"
        content_matches="$(rg --files-with-matches --smart-case \
            --glob '!.trash/**' --glob '!.obsidian/**' \
            -- "$query" 2>/dev/null || true)"

        # name matches come first, then content matches, deduped
        printf '%s\n%s\n' "$name_matches" "$content_matches" | awk 'NF && !seen[$0]++'
    }
    export -f _notes_search

    (
        cd "$NOTES_DIR" || exit 1 # Exit if NOTES_DIR cannot be changed to

        # fzf's reload() bind spawns "$SHELL -c", make sure that's bash so
        # the exported function above is visible to it.
        SHELL="$(command -v bash)"
        export SHELL

        file="$(fzf \
            --disabled \
            --bind 'start:reload(_notes_search {q})' \
            --bind 'change:reload(sleep 0.1; _notes_search {q})' \
            --preview 'glow -s dark {}' \
            --preview-window 'right:60%:wrap' \
            || true)"

        # Trim and sanitize the file name
        if [[ -n "$file" ]]; then
            sanitized_file=$(echo "$file" | sed 's/[{}]//g' | xargs)
            if [[ -f "$sanitized_file" ]]; then
                # Use the editor to open the selected file
                "$editor" "$sanitized_file"
            else
                echo "Error: No valid file selected or file does not exist."
            fi
        fi
    )
  '';
}
