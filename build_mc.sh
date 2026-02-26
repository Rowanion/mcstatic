#!/bin/bash
set -e

MC_VERSION="4.8.33"
export APPIMAGE_EXTRACT_AND_RUN=1

# 1. Download MC
echo "Downloading MC $MC_VERSION..."
wget -q http://ftp.midnight-commander.org/mc-${MC_VERSION}.tar.xz
tar xf mc-${MC_VERSION}.tar.xz
cd mc-${MC_VERSION}

# 2. Configure & Build
# We use minimal flags for the Steam Deck
echo "Configuring MC..."
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --libexecdir=/usr/libexec \
            --with-screen=ncurses \
            --enable-vfs-sftp \
            --enable-vfs-smb \
            --disable-debug \
            --without-x

make -j$(nproc)
make install DESTDIR=/build/AppDir

# 3. Create AppImage structure
echo "Packaging AppImage..."
cd /build

# --- SKIN FIX START ---
# Ensure the skins and help files are bundled from the build output
mkdir -p AppDir/usr/share/mc
cp -r /build/mc-${MC_VERSION}/misc/skins AppDir/usr/share/mc/

# Create a custom AppRun to tell MC where its data is located inside the AppImage
cat > /my_custom_apprun.sh <<'EOF'
#!/bin/bash
# Find the directory where the AppRun is located
HERE="$(dirname "$(readlink -f "${0}")")"

# Set the MC Data directory to internal paths
export MC_DATADIR="$HERE/usr/share/mc"

# Explicitly point to the skins folder 
export MC_SKINSDIR="$HERE/usr/share/mc/skins"  

# Point to the library files (where the default menus/etc live) 
export MC_LIBDIR="$HERE/usr/share/mc"

# This forces MC to look inside the AppImage for the 'syntax' folder
export XDG_DATA_HOME="$HERE/usr/share"

# Ensure common colors are supported
export COLORTERM=truecolor

# Run the bundled MC
exec "$HERE/usr/bin/mc" -u "$@"
EOF
chmod +x /my_custom_apprun.sh
# --- SKIN FIX END ---

# Create a dummy desktop file so linuxdeploy doesn't complain
cat > mc.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Midnight Commander
Exec=mc
Icon=utilities-terminal
Categories=System;
Terminal=true
EOF

# Icon Fix
mkdir -p AppDir/usr/share/icons/hicolor/32x32/apps/
cp /mc.png AppDir/usr/share/icons/hicolor/32x32/apps/utilities-terminal.png

# Use linuxdeploy to bundle dependencies
# We tell it to ignore 'glibc' because Steam Deck has its own.
linuxdeploy --appdir AppDir \
            -i /mc.png \
            -d mc.desktop \
            -e AppDir/usr/bin/mc \
            --custom-apprun /my_custom_apprun.sh \
            --output appimage

echo "Done! Your AppImage is in the build folder."
