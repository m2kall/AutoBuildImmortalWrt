#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Log file for debugging
LOGFILE="/tmp/build-log.txt"
echo "Starting build script at $(date)" > $LOGFILE

BUILD_DIR="/home/build/immortalwrt"
CONFIG_FILE="$BUILD_DIR/.config"

echo "--- Modifying .config for EXT4 filesystem ---" >> $LOGFILE

# Disable SQUASHFS and enable EXT4 in the .config file
# This is the correct way to change the filesystem type without a full .config override
sed -i 's/CONFIG_TARGET_ROOTFS_SQUASHFS=y/# CONFIG_TARGET_ROOTFS_SQUASHFS is not set/' "$CONFIG_FILE"
echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> "$CONFIG_FILE"

echo ".config modifications complete. New config state:" >> $LOGFILE
grep 'ROOTFS' "$CONFIG_FILE" >> $LOGFILE

# Define package list
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding Docker package to the list." >> $LOGFILE
fi

# Create custom files directory
FILES_DIR="$BUILD_DIR/files"
mkdir -p "$FILES_DIR/etc/config"

# Create PPPoE settings file if enabled
if [ "$ENABLE_PPPOE" = "yes" ]; then
    cat << EOF > "$FILES_DIR/etc/config/pppoe-settings"
    enable_pppoe=${ENABLE_PPPOE}
    pppoe_account=${PPPOE_ACCOUNT}
    pppoe_password=${PPPOE_PASSWORD}
EOF
    echo "Created PPPoE config file." >> $LOGFILE
fi

echo "--- Starting image build --- " >> $LOGFILE
# Use the 'generic' profile, as the filesystem is now handled by the .config
make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="$FILES_DIR" ROOTFS_PARTSIZE="$PROFILE"

echo "Build command finished." >> $LOGFILE
