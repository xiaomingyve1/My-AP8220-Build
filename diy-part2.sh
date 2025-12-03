#!/bin/bash
# Description: OpenWrt DIY script part 2

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
# 3. 关键修复：无死角清理冲突的 WiFi 驱动
# =========================================================
# 使用 find 命令全盘搜索 package/feeds 目录下所有的 hostapd 和 wpad
# 不管它藏在 base 还是 packages 还是 net 目录下，全部强制删除
# 这样编译器就只能去用源码自带的 package/network/services/hostapd (兼容版)

echo "Searching and destroying conflicting hostapd/wpad..."
find package/feeds -type d -name "hostapd" -exec rm -rf {} +
find package/feeds -type d -name "wpad" -exec rm -rf {} +

echo "Conflicting drivers removed."

# =========================================================
# 4. 关键修复：原生修改 Golang 为官方最新版
# =========================================================
# 解决 AdGuardHome 报错 (Go >= 1.25.3)

GO_MAKEFILE="feeds/packages/lang/golang/Makefile"

if [ -f "$GO_MAKEFILE" ]; then
    echo "Querying official latest Go version..."
    
    # 动态获取 Go 官网最新版本号 (如 go1.25.4)
    LATEST_GO=$(curl -sL https://go.dev/VERSION?m=text | head -n1)
    
    # 保底机制：如果网络不好获取不到，就用 1.25.3
    if [ -z "$LATEST_GO" ]; then
        LATEST_GO="go1.25.3"
    fi
    
    # 去掉前缀 (go1.25.4 -> 1.25.4)
    GO_VERSION="${LATEST_GO#go}"
    
    echo "Updating System Golang to Official $GO_VERSION..."
    
    # 1. 修改版本号
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$GO_VERSION/" "$GO_MAKEFILE"
    
    # 2. 强制跳过 Hash 校验 (因为是动态版本)
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/' "$GO_MAKEFILE"
    
    echo "Done. Compiler will download $GO_VERSION from Official Source."
else
    echo "Warning: System Golang Makefile not found at $GO_MAKEFILE"
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
