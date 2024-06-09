#!/usr/bin/env bash

# 获取物理内存大小 (MB)
mem_size=$(free -m | awk '/Mem:/ {print $2}')
# 计算 swap 大小范围
min_swap_size=$((mem_size * 3))
max_swap_size=$((mem_size * 4))

echo "正在检查系统上的 swap 设置..."

# 检查是否已存在 swapfile
if grep -q "swapfile" /etc/fstab; then
  # 获取当前 swap 空间大小 (KB)，并转换为 MB
  current_swap_size=$(swapon -s | grep "/swapfile" | awk '{print $3}')
  current_swap_size_mb=$((current_swap_size / 1024))
  # 检查当前 swap 大小是否在预期范围内
  if [[ "$current_swap_size_mb" -ge "$min_swap_size" ]] && [[ "$current_swap_size_mb" -le "$max_swap_size" ]]; then
    echo "已存在大小合适的 swap (${current_swap_size_mb}M)，无需修改。"
    exit 0
  else
    echo "发现一个大小不符合预期的 swapfile，将重新创建..."
    echo "正在删除旧的 swapfile..."
    sed -i '/swapfile/d' /etc/fstab
    swapoff -a
    rm -f /swapfile
    echo "旧 swapfile 已删除."
  fi
fi

echo "正在创建大小为物理内存四倍 (${max_swap_size}M) 的 swapfile..."
fallocate -l "${max_swap_size}M" /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

# 检查执行结果
if grep -q "swapfile" /etc/fstab && swapon -s | grep -q "/swapfile"; then
  echo "虚拟内存已成功设置为物理内存的四倍 (${max_swap_size}M)。"
else
  echo "设置虚拟内存失败，请检查错误信息!"
fi
