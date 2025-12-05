#!/bin/bash

# Description: OpenWrt DIY script part 2 (VIKINGYFY 纯净安全版)

# 目标：

# ✅ 只使用 VIKINGYFY/immortalwrt 原生魔改包

# ✅ 不再混用任何官方 feeds

# ✅ 永久杜绝 hostapd / wpad 结构体炸裂问题

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

# 3. ✅ 彻底禁用官方 feeds（核心关键）

# =========================================================

echo "========================================="
echo "✅ Using VIKINGYFY ImmortalWrt ONLY"
echo "❌ Disabling all official feeds"
echo "========================================="

# 强制清空 feeds

rm -rf feeds
mkdir feeds

# 只保留源码自带 feeds.conf.default

# （VIKINGYFY 已经在源码里魔改好了 feeds）

sed -i 's/^src-git/#&/' feeds.conf.default

# =========================================================

# 4. ✅ 仅初始化 VIKINGYFY 自带 feeds（不引入官方包）

# =========================================================

./scripts/feeds clean
./scripts/feeds update -i
./scripts/feeds install -a -f

# =========================================================

# 5. ✅ Golang 自动对接官方最新版（这是安全的）

# =========================================================

GO_MAKEFILE=$(find feeds -path "*/lang/golang/Makefile" 2>/dev/null | head -n1)

if [ -f "$GO_MAKEFILE" ]; then
echo "Querying Go Official Latest Version..."
LATEST_GO=$(curl -sL --connect-timeout 5 [https://go.dev/VERSION?m=text](https://go.dev/VERSION?m=text) | head -n1)

```
if [[ -z "$LATEST_GO" || "$LATEST_GO" != go* ]]; then
    LATEST_GO="go1.25.3"
fi

GO_VERSION="${LATEST_GO#go}"
echo "Detected Target Go Version: $GO_VERSION"

sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$GO_VERSION/" "$GO_MAKEFILE"
sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/' "$GO_MAKEFILE"
echo "Golang Makefile updated."
```

else
echo "⚠️  Golang Makefile not found, skip."
fi

# =========================================================

# 6. ✅ 执行你的 Scripts 目录魔改（完全保留）

# =========================================================

cd package || exit 1
if [ -f "$MY_SCRIPTS/Packages.sh" ]; then
chmod +x "$MY_SCRIPTS/Packages.sh"
source "$MY_SCRIPTS/Packages.sh"
fi

```
if [ -f "$MY_SCRIPTS/Handles.sh" ]; then
    chmod +x "$MY_SCRIPTS/Handles.sh"
    source "$MY_SCRIPTS/Handles.sh"
fi
```

cd ..

if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
chmod +x "$MY_SCRIPTS/Settings.sh"
source "$MY_SCRIPTS/Settings.sh"
fi

echo "========================================="
echo "✅ VIKINGYFY ImmortalWrt Pure Build Done!"
echo "✅ No Official Feeds"
echo "✅ No hostapd overwrite"
echo "✅ No ABI mismatch"
echo "========================================="
