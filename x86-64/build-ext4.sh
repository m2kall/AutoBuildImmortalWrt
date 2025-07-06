#!/bin/bash
set -e

# Log file for debugging
LOGFILE="/tmp/build-log.txt"
echo "Starting build script at $(date)" > $LOGFILE

BUILD_DIR="/home/build/immortalwrt"
CONFIG_FILE="$BUILD_DIR/.config"

echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# 创建pppoe配置文件
mkdir -p $BUILD_DIR/files/etc/config
cat << EOF > $BUILD_DIR/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "--- 修改配置支持EXT4 ---" >> $LOGFILE

# 修改配置文件支持EXT4
sed -i 's/CONFIG_TARGET_ROOTFS_SQUASHFS=y/# CONFIG_TARGET_ROOTFS_SQUASHFS is not set/' "$CONFIG_FILE"
echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> "$CONFIG_FILE"
echo "CONFIG_TARGET_EXT4_RESERVED_PCT=0" >> "$CONFIG_FILE"
echo "CONFIG_TARGET_EXT4_BLOCKSIZE_4K=y" >> "$CONFIG_FILE"

# 确保EFI支持
grep -q "CONFIG_GRUB_EFI_IMAGES=y" "$CONFIG_FILE" || echo "CONFIG_GRUB_EFI_IMAGES=y" >> "$CONFIG_FILE"
grep -q "CONFIG_EFI_IMAGES=y" "$CONFIG_FILE" || echo "CONFIG_EFI_IMAGES=y" >> "$CONFIG_FILE"

echo "配置修改完成" >> $LOGFILE
grep 'ROOTFS\|EXT4\|EFI' "$CONFIG_FILE" >> $LOGFILE

# 定义软件包列表
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding Docker package" >> $LOGFILE
fi

echo "--- 开始构建 ---" >> $LOGFILE
echo "包列表: $PACKAGES" >> $LOGFILE

# 构建镜像
make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="$BUILD_DIR/files" ROOTFS_PARTSIZE="$PROFILE"

echo "构建完成" >> $LOGFILE
