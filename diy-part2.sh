#!/usr/bin/env bash
# diy-part2.sh
# 目的：确保 nss/kmod-qca-nss-drv 包能被 feeds 或快速放到 package/ 里，增加丰富日志便于 CI 定位问题
set -euo pipefail
export PATH="$PATH:/usr/bin:/bin"

echo ">>> diy-part2.sh start: $(date) <<<"
# 如果仓库里有 openwrt 目录就进入它；否则假定当前就是 openwrt 源代码根目录
if [ -d "./openwrt" ]; then
  cd openwrt
  echo "cd into ./openwrt"
fi

WORKDIR="$(pwd)"
echo "workdir: ${WORKDIR}"

# 备份原 feeds.conf.default（如果存在）
if [ -f feeds.conf.default ]; then
  cp -f feeds.conf.default feeds.conf.default.bak || true
  echo "Backed up feeds.conf.default -> feeds.conf.default.bak"
else
  echo "Note: feeds.conf.default not found; creating a new one"
  touch feeds.conf.default
fi

# --- 确保 feeds.conf.default 包含 nss / viking 包源（只追加不重复） ---
ensure_feed() {
  local feed_line="$1"
  local marker="$2"
  if ! grep -Fq "$marker" feeds.conf.default 2>/dev/null; then
    echo "Adding feed: $feed_line"
    echo "$feed_line" >> feeds.conf.default
  else
    echo "Feed marker '$marker' already present in feeds.conf.default"
  fi
}

# 官方 nss feed（通常包含 qca nss 驱动）
ensure_feed "src-git nss_packages https://github.com/openwrt/nss_packages.git" "nss_packages"

# 可选：VIKINGYFY 的 packages（你之前提到过使用他的源）
ensure_feed "src-git viking_packages https://github.com/VIKINGYFY/packages.git" "viking_packages"

echo "=== feeds.conf.default now ==="
cat feeds.conf.default || true
echo "================================"

# 清理并更新 feeds
echo "Running ./scripts/feeds clean && ./scripts/feeds update -i"
./scripts/feeds clean || true
./scripts/feeds update -i || true

# 安装全部 feeds 中的包（强制覆盖已安装）
echo "Running ./scripts/feeds install -a -f"
./scripts/feeds install -a -f || true

# Debug 输出：列出 feeds/package 目录并搜索 qca-nss 关键字
echo "==== Debug: list top-level dirs ===="
ls -la || true
echo "==== list package and feeds dirs ===="
ls -la package || true
ls -la feeds || true

echo "==== search for qca-nss or kmod-qca in feeds/package ===="
grep -R --line-number "qca-nss" feeds package 2>/dev/null || true
grep -R --line-number "kmod-qca" feeds package 2>/dev/null || true

# 如果 package/kmod-qca-nss-drv 不存在，尝试做快速修复：克隆 openwrt/nss_packages 并提取
if [ ! -d "package/kmod-qca-nss-drv" ]; then
  echo "package/kmod-qca-nss-drv NOT found. Trying quick-clone from openwrt/nss_packages..."
  rm -rf tmp_nss || true
  git clone --depth=1 https://github.com/openwrt/nss_packages.git tmp_nss || true
  if [ -d "tmp_nss/kmod-qca-nss-drv" ]; then
    echo "Found tmp_nss/kmod-qca-nss-drv — moving to package/"
    mkdir -p package
    mv -f tmp_nss/kmod-qca-nss-drv package/kmod-qca-nss-drv
  else
    echo "tmp_nss does not contain kmod-qca-nss-drv. Trying VIKINGYFY/packages..."
    rm -rf tmp_nss || true
    git clone --depth=1 https://github.com/VIKINGYFY/packages.git tmp_nss || true
    if [ -d "tmp_nss/kmod-qca-nss-drv" ]; then
      echo "Found in VIKINGYFY/packages. moving to package/"
      mkdir -p package
      mv -f tmp_nss/kmod-qca-nss-drv package/kmod-qca-nss-drv
    else
      # 也尝试查找类似名称的目录（容错）
      echo "Searching for 'qca-nss' dirs inside tmp_nss..."
      find tmp_nss -maxdepth 3 -type d -iname "*qca*nss*" -print || true
      echo "Could not locate kmod-qca-nss-drv automatically. Manual fix may be required."
    fi
  fi
  rm -rf tmp_nss || true
else
  echo "package/kmod-qca-nss-drv already present — no quick-clone needed."
fi

# 再次尝试安装 feeds（让 make 能找到新搬入的 package）
echo "Re-running ./scripts/feeds install -a -f to refresh package index"
./scripts/feeds install -a -f || true

# 输出最终状态供 CI 查看
echo "==== Final package dir listing (top-level) ===="
ls -la package || true
echo "==== Look specifically for kmod-qca-nss-drv ===="
if [ -d "package/kmod-qca-nss-drv" ]; then
  echo "OK: package/kmod-qca-nss-drv exists"
  ls -la package/kmod-qca-nss-drv || true
else
  echo "WARNING: package/kmod-qca-nss-drv still missing after attempts"
fi

# 打印 .config 中 kernel 相关信息（若有）
if [ -f .config ]; then
  echo "==== kernel/config summary from .config (if present) ===="
  grep -i "kernel" .config || true
  grep -i "KERNEL" .config || true
fi

echo ">>> diy-part2.sh end: $(date) <<<"
