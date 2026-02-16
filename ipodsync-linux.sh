#!/usr/bin/env bash
set -euo pipefail
clear
echo "ipodsync-linux v1.0"
echo "A program to help with syncing classic, nano, and shuffle iPods on Linux"
echo "Tested on my iPod 4th gen grayscale"
echo "Debugging/fixing by ChatGPT, code by me"
echo
echo "Performing sanity checks..."

arch="$(uname -m)"
if [[ "$arch" != "x86_64" && "$arch" != "amd64" ]]; then
   echo "ipodsync-linux only supports x86_64/amd64 systems."
   exit 1
fi   

for cmd in gnupod_INIT mktunes perl gnupod_addsong; do
   if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: Required command '$cmd' is not installed. Please install gnupod-tools."
      exit 1
     fi
done

echo
echo "Available volumes under /media/$USER:"
ls "/media/$USER" 2>/dev/null || true
echo

read -rp "Enter your iPod volume name: " volname

mount_path="/media/$USER/$volname"

if [ ! -d "$mount_path" ]; then
   echo "The volume '$volname' is not mounted at '$mount_path'"
   exit 1
fi

if [ ! -d "$mount_path/iPod_Control" ]; then
   echo "This doesn't look like a valid iPod. (missing iPod_Control folder)."
   echo "Making this folder yourself will cause the tool to sync wrong."
   exit 1
fi

echo
if [ ! -d "$mount_path/iPod_Control/.gnupod" ]; then
   echo "GNUpod database not found. Initializing..."
   gnupod_INIT -m "$mount_path"
else
   echo "Existing GNUpod database found. Skipping initialization."
fi

echo "Rebuilding iTunesDB..."
mktunes -m "$mount_path"
echo "iTunesDB rebuilt successfully."
echo
read -rp "Enter your path to music (only .mp3 files): " songpath

if [ -d "$songpath" ]; then
    search_cmd=(find "$songpath" -type f -iname '*.mp3' -print0)
elif [ -f "$songpath" ]; then
    search_cmd=(printf '%s\0' "$songpath")
else
    echo "That path does not exist."
    exit 1
fi


echo
echo "Adding MP3 files from '$songpath'..."

found_any=false

while IFS= read -r -d '' file; do
    found_any=true
    echo "Adding: $file"
    gnupod_addsong -m "$mount_path" "$file"
done < <("${search_cmd[@]}")

if [ "$found_any" = "false" ]; then
   echo "No MP3 files found in that directory."
   exit 1
fi

echo
echo "Rebuilding iTunesDB..."
mktunes -m "$mount_path"

echo "Sync complete!"
echo "If any errors occurred, open an issue:"
echo "https://github.com/MKstarFromSwitch/ipodsync-linux"
exit 0
