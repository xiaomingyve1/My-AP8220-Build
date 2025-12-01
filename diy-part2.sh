#!/bin/bash
# ==============================================================================
# VIKINGYFY 脚本全量移植版 (整合 Packages.sh + Handles.sh + Settings.sh)
# ==============================================================================

# --- 基础设置 (请确认 WiFi 密码) ---
WRT_IP="192.168.6.1"       # 主机IP
WRT_NAME="MyRouter-0"      # 主机名
WRT_THEME="argon"          # 默认主题
WRT_SSID="My_AP8220"       # WiFi 名称
WRT_WORD="12345678"        # WiFi 密码
WRT_TARGET="QUALCOMMAX"    # 目标平台 (高通专用)

# --- 手动下载插件 (源里没有的，或者求稳的，全在这里下) ---

# [主题] Argon
git clone https://github.com/sbwml/luci-theme-argon.git package/luci-theme-argon
# [主题] KuCat (备用)
git clone https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
# [插件] MosDNS
git clone https://github.com/sbwml/luci-app-mosdns.git package/mosdns
# [插件] DiskMan (磁盘管理)
git clone https://github.com/lisaac/luci-app-diskman.git package/diskman
# [插件] EasyTier
git clone https://github.com/EasyTier/OpenWrt-EasyTier package/easytier
# [插件] UU加速器 (FW4 适配版)
git clone https://github.com/BCYDTZ/luci-app-UUGameAcc.git package/luci-app-UUGameAcc
# [插件] 你的旧版 IPK 源码 (记得修改地址，没用到就注释掉)
# git clone https://github.com/你的旧软件作者/仓库名.git package/my-old-app

# --- 编译修复与补丁 ---

# 预置 HomeProxy 数据 (防止编译报错)
if [ -d package/homeproxy ]; then
	HP_RULE="surge"
	HP_PATH="package/homeproxy/root/etc/homeproxy"
	rm -rf ./$HP_PATH/resources/*
	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ 
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../../$HP_PATH/resources/
	cd ../.. && rm -rf ./$HP_RULE/
fi

# NSS 驱动启动顺序
NSS_DRV=$(find feeds/nss_packages/ -name "qca-nss-drv.init")
[ -f "$NSS_DRV" ] && sed -i 's/START=.*/START=85/g' $NSS_DRV
NSS_PBUF="./package/kernel/mac80211/files/qca-nss-pbuf.init"
[ -f "$NSS_PBUF" ] && sed -i 's/START=.*/START=86/g' $NSS_PBUF

# 编译报错修复
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
[ -f "$TS_FILE" ] && sed -i '/\/files/d' $TS_FILE
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
[ -f "$RUST_FILE" ] && sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE
DM_FILE="./package/diskman/applications/luci-app-diskman/Makefile"
[ -f "$DM_FILE" ] && { sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE; sed -i '/ntfs-3g-utils /d' $DM_FILE; }


# ==============================================================================
# --- 系统设置 ---
# ==============================================================================

# 修改 IP / 主机名 / 默认主题
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" package/base-files/files/bin/config_generate
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" feeds/luci/collections/luci/Makefile
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改 WiFi
WIFI_SH=$(find ./target/linux/qualcommax/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
    sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
    sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
fi

# --- 高通平台专用配置 ---
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	echo "CONFIG_FEED_nss_packages=n" >> .config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> .config
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> .config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> .config
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> .config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=n" >> .config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
fi

# 强制追加主题配置
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> .config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> .config

echo "Script execution completed!"
