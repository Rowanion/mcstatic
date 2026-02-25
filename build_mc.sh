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

# we need to circumvent linuxdeploy's fallback to a terminal icon
# 1. Create the directory where linuxdeploy expects to find system icons 
mkdir -p AppDir/usr/share/icons/hicolor/32x32/apps/

# 2. Copy your mc.png to that location, but RENAME it to utilities-terminal.png
# (Assuming mc.png is in your current directory)
cp /mc.png AppDir/usr/share/icons/hicolor/32x32/apps/utilities-terminal.png

# Use linuxdeploy to bundle dependencies
# We tell it to ignore 'glibc' because Steam Deck has its own.
linuxdeploy --appdir AppDir \
            -i /mc.png \
            -d mc.desktop \
            -e AppDir/usr/bin/mc \
            --output appimage

echo "Done! Your AppImage is in the build folder."
