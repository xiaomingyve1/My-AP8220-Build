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
# 3. 终极修复：使用官方命令卸载冲突包 (替换掉 find 删除)
# =========================================================
# 之前的 find 删除可能删不干净软链接或缓存
# 使用 uninstall 命令会让编译系统"正式"移除这些包的索引
# 这样它就绝对不可能再去编译 feeds 里的 hostapd 了

echo "Uninstalling official hostapd/wpad via feeds script..."
./scripts/feeds uninstall hostapd
./scripts/feeds uninstall wpad
./scripts/feeds uninstall hostapd-openssl
./scripts/feeds uninstall wpad-openssl

# 为了双重保险，卸载后再把源文件目录改成不可读或删除
# 这样就算有漏网之鱼想重装也找不到源
rm -rf feeds/packages/net/hostapd
rm -rf feeds/packages/net/wpad

echo "Official WiFi drivers uninstalled. Using internal source drivers."

# =========================================================
# 4. Golang 官方最新版自动对接
# =========================================================
# 保持你认可的自动获取逻辑

GO_MAKEFILE=$(find feeds/packages/lang/ -name "Makefile" | grep "/golang/")

if [ -f "$GO_MAKEFILE" ]; then
    echo "Querying Go Official Latest Version..."
    
    # 获取官方最新版
    LATEST_GO=$(curl -sL --connect-timeout 5 https://go.dev/VERSION?m=text | head -n1)
    
    if [[ -z "$LATEST_GO" || "$LATEST_GO" != go* ]]; then
        echo "Network Error. Fallback to 1.25.3"
        LATEST_GO="go1.25.3"
    fi
    
    GO_VERSION="${LATEST_GO#go}"
    echo "Target Go Version: $GO_VERSION"
    
    # 修改 Makefile
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$GO_VERSION/" "$GO_MAKEFILE"
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/' "$GO_MAKEFILE"
    
    echo "Golang Makefile updated."
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
