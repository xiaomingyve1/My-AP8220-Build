#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础设置 (定义变量，通过 export 传给 Settings.sh)
# =========================================================
export WRT_IP="192.168.6.1"           # 管理 IP
export WRT_NAME="MyRouter-0"          # 主机名
export WRT_THEME="argon"              # 默认主题

# --- WiFi 2.4G 设置 ---
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"

# --- WiFi 5G 设置 ---
export WRT_SSID_5G="My_AP8220"
export WRT_WORD_5G="12345678"

export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 调用外部脚本 (按顺序执行)
# =========================================================

# (1) 调用 Handles.sh (系统修复)
if [ -f "$GITHUB_WORKSPACE/Handles.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Handles.sh
    source $GITHUB_WORKSPACE/Handles.sh
fi

# (2) 调用 Packages.sh (下载插件)
if [ -f "$GITHUB_WORKSPACE/Packages.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Packages.sh
    cd package
    source $GITHUB_WORKSPACE/Packages.sh
    cd ..
fi

# (3) 调用 Settings.sh (应用设置)
if [ -f "$GITHUB_WORKSPACE/Settings.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Settings.sh
    source $GITHUB_WORKSPACE/Settings.sh
fi

# =========================================================
# 3. 补充环境 (MosDNS 编译必需)
# =========================================================
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang

echo "DIY-Part2 Done!"
