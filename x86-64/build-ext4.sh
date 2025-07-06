#!/bin/bash

# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting build-ext4.sh at $(date)" >> $LOGFILE

echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"
echo "构建EXT4版本固件"

echo "Create pppoe-settings"
mkdir -p /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译EXT4版本..."

# 定义所需安装的包列表（移除您不需要的两个包）
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
# 服务——FileBrowser 用户名admin 密码admin
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
#24.10
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
# 增加几个必备组件 方便用户安装iStore
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 修改配置以支持EXT4
echo "$(date '+%Y-%m-%d %H:%M:%S') - 配置EXT4文件系统..."

# 备份原始配置
cp .config .config.backup

# 修改文件系统配置
sed -i 's/CONFIG_TARGET_ROOTFS_SQUASHFS=y/# CONFIG_TARGET_ROOTFS_SQUASHFS is not set/' .config
echo "CONFIG_TARGET_ROOTFS_EXT4FS=y" >> .config
echo "CONFIG_TARGET_EXT4_RESERVED_PCT=0" >> .config
echo "CONFIG_TARGET_EXT4_BLOCKSIZE_4K=y" >> .config
echo "CONFIG_TARGET_EXT4_BLOCKSIZE=4096" >> .config

# 确保EFI支持
echo "CONFIG_GRUB_EFI_IMAGES=y" >> .config
echo "CONFIG_EFI_IMAGES=y" >> .config
echo "CONFIG_TARGET_IMAGES_GZIP=y" >> .config

# 显示修改后的配置
echo "EXT4相关配置:"
grep -E "(ROOTFS|EXT4|EFI)" .config

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building EXT4 image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: EXT4 Build failed!"
    echo "显示构建日志的最后50行:"
    tail -50 /tmp/openwrt-build.log 2>/dev/null || echo "无法找到构建日志"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - EXT4 Build completed successfully."
