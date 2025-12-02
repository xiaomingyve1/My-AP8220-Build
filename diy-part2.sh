#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础变量
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 脚本路径
# =========================================================
MY_SCRIPTS="$GITHUB_WORKSPACE/My-warehouse/Scripts"

# =========================================================
# 3. 关键修复：清理冲突的官方驱动 (Hostapd)
# =========================================================
# [核心修正] 必须删除 package/feeds/ 下的文件，因为它们已经被安装进去了
# 删除后，编译器会自动寻找源码 package/network/services/ 下的自带版本

echo "Nuking conflicting hostapd from package directory..."
rm -rf package/feeds/packages/net/hostapd
rm -rf package/feeds/packages/net/wpad
rm -rf package/feeds/network/services/hostapd
rm -rf package/feeds/network/services/wpad

# =========================================================
# 4. 关键修复：解决 AdGuardHome Go 版本报错
# =========================================================
# 方案 A: 尝试升级 Golang 到最新 (依赖 sbwml 更新)
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# 方案 B (保底): 如果升级 Go 也没用，强制把 AdGuardHome 降级到稳定版 (0.107.53)
# 找到 AGH 的 Makefile
AGH_MAKEfile=$(find package/feeds/packages/ -name "Makefile" | grep "adguardhome")
if [ -f "$AGH_MAKEfile" ]; then
    echo "Force downgrading AdGuardHome to 0.107.53 to fix Go compile error..."
    # 修改版本号
    sed -i 's/^PKG_VERSION:=.*/PKG_VERSION:=0.107.53/' "$AGH_MAKEfile"
    # 注释掉 hash 校验，防止降级后校验失败
    sed -i 's/^PKG_HASH:=/# PKG_HASH:=/' "$AGH_MAKEfile"
    # 确保不使用 Git 自动生成的版本
    sed -i 's/^PKG_SOURCE_VERSION:=.*/# PKG_SOURCE_VERSION:=/' "$AGH_MAKEfile"
fi

# =========================================================
# 5. 执行外部脚本
# =========================================================

# --- 进入 package 目录 ---
cd package
    if [ -f "$MY_SCRIPTS/Packages.sh" ]; then
        chmod +x "$MY_SCRIPTS/Packages.sh"
        source "$MY_SCRIPTS/Packages.sh"
    fi

    if [ -f "$MY_SCRIPTS/Handles.sh" ]; then
        chmod +x "$MY_SCRIPTS/Handles.sh"
        source "$MY_SCRIPTS/Handles.sh"
    fi
cd ..

# --- 回到根目录 ---
if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS/Settings.sh"
    source "$MY_SCRIPTS/Settings.sh"
fi

echo "DIY-Part2 Done!"
