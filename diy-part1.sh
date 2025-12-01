#!/bin/bash

# 添加 OpenClash 源
echo "src-git openclash https://github.com/vernesong/OpenClash.git" >> feeds.conf.default

# 添加 Passwall 源
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git passwall_luci https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default

# 添加 LinkEase 源 (ddnsto依赖)
echo "src-git nas_packages https://github.com/linkease/nas-packages.git;master" >> feeds.conf.default
echo "src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main" >> feeds.conf.default
