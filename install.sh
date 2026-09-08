#!/usr/bin/env bash
set -e

REPO="Sadowski-Krystian/Blue-Archive-Arona-L2D-KDE"
echo "Fetching latest release of Blue Archive Live2D Wallpaper..."

DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases/tag/latest" \
  | grep "browser_download_url.*plasmoid" \
  | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find a release plasmoid."
    exit 1
fi

TMP_FILE="/tmp/l2d.arona.plana.bluearchive"
echo "Downloading from: $DOWNLOAD_URL"
curl -L -o "$TMP_FILE" "$DOWNLOAD_URL"

echo "Installing wallpaper package..."
kpackagetool6 --type Plasma/Wallpaper --upgrade "$TMP_FILE" 2>/dev/null || \
kpackagetool6 --type Plasma/Wallpaper --install "$TMP_FILE"

rm -f "$TMP_FILE"

echo "Done! You can now select the wallpaper in your Desktop Settings."
echo "Remember to change your desktop 'Layout' from 'Folder View' to 'Desktop'"