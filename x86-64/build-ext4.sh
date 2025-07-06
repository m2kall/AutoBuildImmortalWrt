#!/bin/bash
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting build script at $(date)" >> $LOGFILE
echo "Firmware size profile: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"
echo "PPPoE Enabled: $ENABLE_PPPOE"

echo "Create pppoe-settings file"
# 确保目录存在
mkdir -p /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "--- pppoe-settings content ---"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings
echo "-----------------------------"

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting build..."

# 定义所需安装的包列表
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

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 使用 "generic" profile 进行编译，ext4 文件系统通常由 .config 文件定义
# 运行action时请先查看 "List available profiles" 步骤的输出来确认正确的Profile名称
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with 'generic' profile..."
make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
