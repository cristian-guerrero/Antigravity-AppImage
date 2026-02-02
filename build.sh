#!/bin/bash
set -e

# 1. Configuration - Use manual link as base
# If no URL is provided, we use the one the user gave us
DEFAULT_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.15.8-5724687216017408/linux-x64/Antigravity.tar.gz"
DOWNLOAD_URL="${1:-$DEFAULT_URL}"

echo "Using download URL: $DOWNLOAD_URL"

# Extract version from URL if possible
# Example URL: .../stable/1.15.8-5724687216017408/linux-x64/...
VERSION=$(echo "$DOWNLOAD_URL" | grep -oP 'stable/\\K[^/]+' || echo "latest")

# 2. Download and extract
mkdir -p build
cd build
wget -q --show-progress "$DOWNLOAD_URL" -O antigravity.tar.gz

mkdir -p Antigravity.AppDir
tar -xzf antigravity.tar.gz -C Antigravity.AppDir --strip-components=1

# 3. Create AppRun
cat <<EOF > Antigravity.AppDir/AppRun
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export PATH="\${HERE}/bin:\${PATH}"
# Antigravity is based on VS Code / Code OSS
exec "\${HERE}/bin/antigravity" "\$@"
EOF
chmod +x Antigravity.AppDir/AppRun

# 4. Create Desktop File
cat <<EOF > Antigravity.AppDir/antigravity.desktop
[Desktop Entry]
Name=Antigravity
Exec=antigravity %U
Terminal=false
Type=Application
Icon=antigravity
Categories=Development;IDE;
Comment=Google's Internal IDE (Antigravity)
StartupWMClass=antigravity
EOF

# 5. Icons
# Look for icons in the package
cp Antigravity.AppDir/resources/app/resources/linux/code.png Antigravity.AppDir/antigravity.png 2>/dev/null || \
find Antigravity.AppDir -name "*.png" -exec cp {} Antigravity.AppDir/antigravity.png \; -quit || true

# 6. Download appimagetool
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod +x appimagetool

# 7. Build AppImage
export ARCH=x86_64
export APPIMAGE_EXTRACT_AND_RUN=1

REPO_OWNER=$(echo $GITHUB_REPOSITORY | cut -d'/' -f1)
REPO_NAME=$(echo $GITHUB_REPOSITORY | cut -d'/' -f2)

if [ ! -z "$GITHUB_REPOSITORY" ]; then
  UPDATE_INFO="gh-releases-zsync|${REPO_OWNER}|${REPO_NAME}|latest|Antigravity-x86_64.AppImage.zsync"
  ./appimagetool -u "$UPDATE_INFO" Antigravity.AppDir Antigravity-x86_64.AppImage
else
  ./appimagetool Antigravity.AppDir Antigravity-x86_64.AppImage
fi

echo "Build complete: build/Antigravity-x86_64.AppImage"
