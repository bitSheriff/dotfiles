if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input.mp3> <metadata.txt> <output.mp3>"
    exit 1
fi

# 1: input.mp3
# 2: metadata.txt
# 3: output.mp3

ffmpeg -i "$1" -i "$2" -map_metadata 1 -codec copy -id3v2_version 3 -write_id3v1 1 "$3"