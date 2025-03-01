#!/bin/sh

# 检测是否为 FreeBSD
if [ "$(uname)" != "FreeBSD" ]; then
  echo "This script is only for FreeBSD."
  exit 1
fi

# 检查 bc 是否安装
if ! command -v bc >/dev/null 2>&1; then
  echo "Installing bc..."
  sudo pkg install -y bc
fi

# 检查参数数量
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <auth_secret> <url> <name>"
  exit 1
fi

auth_secret="$1"
url="$2"
monitor_name="$3"

# 获取网卡接口
get_main_interface() {
  interfaces=$(ifconfig | grep -E "^[a-zA-Z0-9]+" | awk '{print $1}' | sed 's/://g' | grep -vE "lo|tun|tap|vtnet|bridge")

  echo "可用网卡接口:"
  echo "$interfaces"

  read -p "请选择网卡: " net_name
  echo "已选择网卡: $net_name"
}

get_main_interface

# 创建目录
mkdir -p ~/ak_monitor
cd ~/ak_monitor || exit

# 下载客户端
fetch -o client https://github.com/akile-network/akile_monitor/releases/latest/download/akile_client-freebsd-amd64
chmod 755 client

# 创建配置文件
cat > client.json <<EOF
{
  "auth_secret": "${auth_secret}",
  "url": "${url}",
  "net_name": "${net_name}",
  "name": "${monitor_name}"
}
EOF

# 通过 daemon 启动
echo "正在启动客户端..."
daemon -f ./client

echo "Akile Monitor 已启动！"
