#!/bin/bash
# ==============================================================================
# VIKINGYFY 脚本全量移植版 (整合 Packages.sh + Handles.sh + Settings.sh)
# ==============================================================================

# --- 0. 基础设置 (请确认 WiFi 密码) ---
WRT_IP="192.168.6.1"       # 主机IP
WRT_NAME="MyRouter-0"      # 主机名
WRT_THEME="argon"          # 默认主题
WRT_SSID="My_AP8220"       # WiFi 名称
WRT_WORD="12345678"        # WiFi 密码
WRT_TARGET="QUALCOMMAX"    # 目标平台 (高通专用)

# --- 用户定制区 (你的插件) ---

# [主题] KuCat
git clone https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
# [插件] EasyTier
git clone https://github.com/EasyTier/OpenWrt-EasyTier package/easytier
# [插件] UU加速器 (FW4 适配版)
git clone https://github.com/BCYDTZ/luci-app-UUGameAcc.git package/luci-app-UUGameAcc
# [插件] 你的旧版 IPK 源码
# git clone https://github.com/你的旧软件作者/仓库名.git package/my-old-app

# --- 智能包管理 (源自 Packages.sh) ---

UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)
	
	# 智能清理冲突目录
	for NAME in "${PKG_LIST[@]}"; do
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
			done <<< "$FOUND_DIRS"
		fi
	done
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" package/$PKG_NAME
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		cp -rf package/$PKG_NAME/*/* package/$PKG_NAME/ 2>/dev/null || true
	fi
}

# --- 官方插件列表 (保留核心组件) ---
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-24.10"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"

# --- 编译修复补丁 (源自 Handles.sh) ---

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

# Argon 主题颜色 (原厂青色)
if [ -d package/argon ]; then
	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" package/argon/luci-app-argon-config/root/etc/config/argon
fi

# NSS 驱动启动顺序
NSS_DRV=$(find feeds/nss_packages/ -name "qca-nss-drv.init")
[ -f "$NSS_DRV" ] && sed -i 's/START=.*/START=85/g' $NSS_DRV
NSS_PBUF="./package/kernel/mac80211/files/qca-nss-pbuf.init"
[ -f "$NSS_PBUF" ] && sed -i 's/START=.*/START=86/g' $NSS_PBUF

# Tailscale / Rust / Diskman 修复编译错误
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
[ -f "$TS_FILE" ] && sed -i '/\/files/d' $TS_FILE
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
[ -f "$RUST_FILE" ] && sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE
DM_FILE="./package/diskman/applications/luci-app-diskman/Makefile"
[ -f "$DM_FILE" ] && { sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE; sed -i '/ntfs-3g-utils /d' $DM_FILE; }

# --- 系统设置 (源自 Settings.sh) ---

# 修改 IP / 主机名 / 默认主题
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" package/base-files/files/bin/config_generate
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" feeds/luci/collections/luci/Makefile
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# [装饰] 修改 JS 文件关联 IP 和 增加编译日期显示
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
# sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$(date +%Y.%m.%d)')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

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

# --- 高通平台 (AP8220) 专用配置逻辑 ---

# 警告：这里必须写入 .config (因为云编译时 builder.config 会变成 .config)
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
    # 禁用 NSS Feed (防炸)
	echo "CONFIG_FEED_nss_packages=n" >> .config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> .config
    # 开启 NSS 插件
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> .config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> .config
    # 锁定固件版本 12.5
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> .config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=n" >> .config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> .config
fi

# 强制追加主题配置
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> .config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> .config

echo "Script execution completed!"
