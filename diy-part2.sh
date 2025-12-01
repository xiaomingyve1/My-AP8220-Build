#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 这里必须填入你要的那个旧软件的源码地址
# 举例：如果你想要旧版的某插件，把下面这行的 # 去掉并改成真实地址
# git clone https://github.com/你的旧软件作者/仓库名.git package/my-old-app

# 下载 EasyTier 源码 (P2P 异地组网神器)
git clone https://github.com/EasyTier/OpenWrt-EasyTier package/easytier
