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
# 3. 终极大招：偷梁换柱 (覆盖法)
# =========================================================
# 既然删不掉，那就不删了。
# 我们直接把"源码自带的好包"强制复制到"feeds目录的坏包"位置。
# 这样无论编译器读哪一个，读到的都是兼容的源码版。

echo "Overwriting conflicting feeds with internal source..."

# 1. 定义源码自带的路径 (这是绝对兼容的好版本)
GOOD_HOSTAPD="package/network/services/hostapd"
GOOD_WPAD="package/network/services/hostapd" # wpad 通常和 hostapd 在一起

# 2. 找到 feeds 里捣乱的路径 (全盘扫描)
# 只要是 feeds 目录下叫 hostapd 的目录，全部用好版本覆盖掉
find feeds -type d -name "hostapd" | while read -r BAD_DIR; do
    echo "Replacing bad dir: $BAD_DIR"
    rm -rf "$BAD_DIR"       # 先清空坏的
    cp -rf "$GOOD_HOSTAPD" "$BAD_DIR" # 把好的填进去
done

find feeds -type d -name "wpad" | while read -r BAD_DIR; do
    echo "Replacing bad dir: $BAD_DIR"
    rm -rf "$BAD_DIR"
    cp -rf "$GOOD_WPAD" "$BAD_DIR"
done

# 3. 强制更新索引，让编译系统认可这次"掉包"
./scripts/feeds install -p packages -f hostapd
./scripts/feeds install -p packages -f wpad

echo "Replacement complete. Compiler has been tricked."

# =========================================================
# 4. Golang 官方最新版自动对接
# =========================================================
# 保持自动获取逻辑，这部分没问题

GO_MAKEFILE=$(find feeds/packages/lang/ -name "Makefile" | grep "/golang/")

if [ -f "$GO_MAKEFILE" ]; then
    echo "Querying Go Official Latest Version..."
    LATEST_GO=$(curl -sL --connect-timeout 5 https://go.dev/VERSION?m=text | head -n1)
    
    if [[ -z "$LATEST_GO" || "$LATEST_GO" != go* ]]; then
        LATEST_GO="go1.25.3"
    fi
    
    GO_VERSION="${LATEST_GO#go}"
    echo "Detected Target Go Version: $GO_VERSION"
    
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
