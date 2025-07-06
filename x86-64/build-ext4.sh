#!/bin/bash
set -e

echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"
echo "使用EXT4文件系统"

# 创建pppoe配置文件
mkdir -p /home/build/immortalwrt/files/etc/config
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

# 软件包列表
PACKAGES=""
PACKAGES="$PACKAGES curl luci-i18n-diskman-zh-cn luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server fdisk script-utils luci-i18n-samba4-zh-cn"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
fi

# 构建镜像 - 配置文件已经指定了EXT4
make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

echo "EXT4 Build completed successfully."
