#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础设置 (变量定义)
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"

# --- WiFi 2.4G 设置 ---
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"

# --- WiFi 5G 设置 ---
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"

# --- 关键系统标识 ---
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 定义脚本路径 (你的新路径)
# =========================================================
MY_SCRIPTS_DIR="$GITHUB_WORKSPACE/My-warehouse/Scripts"

# =========================================================
# 3. 补充环境 (解决 AdGuardHome 编译报错)
# =========================================================
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# =========================================================
# 4. 调用外部脚本
# =========================================================

# (1) Packages.sh: 必须进入 package 目录执行
if [ -f "$MY_SCRIPTS_DIR/Packages.sh" ]; then
    chmod +x "$MY_SCRIPTS_DIR/Packages.sh"
    echo "Executing Packages.sh from $MY_SCRIPTS_DIR..."
    cd package
    source "$MY_SCRIPTS_DIR/Packages.sh"
    cd ..
else
    echo "ERROR: Packages.sh not found at $MY_SCRIPTS_DIR"
fi

# (2) Handles.sh: 必须在根目录执行
if [ -f "$MY_SCRIPTS_DIR/Handles.sh" ]; then
    chmod +x "$MY_SCRIPTS_DIR/Handles.sh"
    echo "Executing Handles.sh from $MY_SCRIPTS_DIR..."
    source "$MY_SCRIPTS_DIR/Handles.sh"
else
    echo "ERROR: Handles.sh not found at $MY_SCRIPTS_DIR"
fi

# (3) Settings.sh: 必须在根目录执行
if [ -f "$MY_SCRIPTS_DIR/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS_DIR/Settings.sh"
    echo "Executing Settings.sh from $MY_SCRIPTS_DIR..."
    source "$MY_SCRIPTS_DIR/Settings.sh"
else
    echo "ERROR: Settings.sh not found at $MY_SCRIPTS_DIR"
fi

echo "DIY-Part2 Done!"
