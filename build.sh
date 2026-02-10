#!/bin/bash
set -e

# 1. Configuration - Use manual link as base
# If no URL is provided, we use the one the user gave us
DEFAULT_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.16.5-6703236727046144/linux-x64/Antigravity.tar.gz"
DOWNLOAD_URL="${1:-$DEFAULT_URL}"

echo "Using download URL: $DOWNLOAD_URL"

# Extract version from URL if possible
# Example URL: .../stable/1.15.8-5724687216017408/linux-x64/...
VERSION=$(echo "$DOWNLOAD_URL" | grep -oP 'stable/\K[^/]+' || echo "latest")

# 2. Download and extract
PROJECT_ROOT=$(pwd)
mkdir -p build
cd build

if [ -f "$PROJECT_ROOT/Antigravity.tar.gz" ]; then
  echo "Using local Antigravity.tar.gz"
  cp "$PROJECT_ROOT/Antigravity.tar.gz" antigravity.tar.gz
else
  wget -q --show-progress "$DOWNLOAD_URL" -O antigravity.tar.gz
fi

rm -rf Antigravity.AppDir
mkdir -p Antigravity.AppDir
tar -xzf antigravity.tar.gz -C Antigravity.AppDir --strip-components=1

# 3. Create AppRun
echo "Creating AppRun in $(pwd)/Antigravity.AppDir/AppRun"
cat <<EOF > Antigravity.AppDir/AppRun
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export LD_LIBRARY_PATH="\${HERE}:\${LD_LIBRARY_PATH}"
export PATH="\${HERE}:\${PATH}"
# Antigravity is based on VS Code / Code OSS
exec "\${HERE}/antigravity" "\$@"
EOF
if [ ! -f "Antigravity.AppDir/AppRun" ]; then
    echo "CRITICAL: Failed to create AppRun!"
    exit 1
fi
chmod +x Antigravity.AppDir/AppRun
ls -l Antigravity.AppDir/AppRun

# 4. Create Desktop File
echo "Creating desktop file"
cp "$PROJECT_ROOT/app.desktop" Antigravity.AppDir/antigravity.desktop
# Ensure the Exec name matches and is simple
sed -i 's/^Exec=.*/Exec=antigravity %F/' Antigravity.AppDir/antigravity.desktop
echo "X-AppImage-Version=$VERSION" >> Antigravity.AppDir/antigravity.desktop
ls -l Antigravity.AppDir/antigravity.desktop

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
export VERSION

if [ -z "$GITHUB_REPOSITORY" ]; then
  # Try to infer from local git
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
  if [[ $REMOTE_URL == *"github.com"* ]]; then
    REPO_PATH=$(echo $REMOTE_URL | sed -E 's/.*github.com[:\/](.*)\.git/\1/')
    REPO_OWNER=$(echo $REPO_PATH | cut -d'/' -f1)
    REPO_NAME=$(echo $REPO_PATH | cut -d'/' -f2)
  fi
else
  REPO_OWNER=$(echo $GITHUB_REPOSITORY | cut -d'/' -f1)
  REPO_NAME=$(echo $GITHUB_REPOSITORY | cut -d'/' -f2)
fi

# Use absolute paths for everything to avoid path resolution errors in different environments
BUILD_DIR=$(readlink -f .)
FULL_APP_DIR=$(readlink -f Antigravity.AppDir)
OUTPUT_APPIMAGE="$BUILD_DIR/Antigravity-x86_64.AppImage"

echo "Building AppImage version: $VERSION"

if [ ! -z "$REPO_OWNER" ] && [ ! -z "$REPO_NAME" ]; then
  # ZSync update info for GitHub Releases
  UPDATE_INFO="gh-releases-zsync|${REPO_OWNER}|${REPO_NAME}|latest|Antigravity-x86_64.AppImage.zsync"
  echo "Adding update info: $UPDATE_INFO"
  ./appimagetool -u "$UPDATE_INFO" "$FULL_APP_DIR" "$OUTPUT_APPIMAGE"
else
  # Local build without update info
  ./appimagetool "$FULL_APP_DIR" "$OUTPUT_APPIMAGE"
fi

if [ -f "$OUTPUT_APPIMAGE" ]; then
  echo "Build complete: build/Antigravity-x86_64.AppImage"
  # Mirror to root for convenience in local testing
  if [ -z "$GITHUB_REPOSITORY" ]; then
    cp "$OUTPUT_APPIMAGE" "$PROJECT_ROOT/Antigravity-x86_64.AppImage"
  fi
else
  echo "Error: AppImage file was not created!"
  exit 1
fi
