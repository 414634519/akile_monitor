#!/bin/bash

# Install bc in user space if necessary
if ! command -v bc > /dev/null; then
    echo "bc is not installed. Please install bc manually or ensure it is available."
    exit 1
fi

# Function to detect main network interface
get_main_interface() {
   local interfaces=$(ip -o link show | \
       awk -F': ' '$2 !~ /^((lo|docker|veth|br-|virbr|tun|vnet|wg|vmbr|dummy|gre|sit|vlan|lxc|lxd|warp|tap))/{print $2}' | \
       grep -v '@')

   local interface_count=$(echo "$interfaces" | wc -l)

   # 显示网卡流量的函数
   show_interface_traffic() {
       local interface=$1
       if [ -d "/sys/class/net/$interface" ]; then
           local rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes)
           local tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes)
           echo "   ↓ Received: $(format_bytes $rx_bytes)"
           echo "   ↑ Sent: $(format_bytes $tx_bytes)"
       else
           echo "   无法读取流量信息"
       fi
   }

   # 显示所有网卡
   echo "所有可用的网卡接口:" >&2
   echo "------------------------" >&2
   local i=1
   while read -r interface; do
       echo "$i) $interface" >&2
       show_interface_traffic "$interface" >&2
       i=$((i+1))
   done < <(ip -o link show | grep -v "lo:" | awk -F': ' '{print $2}')
   echo "------------------------" >&2

   while true; do
       read -p "请选择网卡，如上方显示异常或没有需要的网卡，请直接填入网卡名: " selection
       # 检查是否为数字
       if [[ "$selection" =~ ^[0-9]+$ ]]; then
           selected_interface=$(ip -o link show | grep -v "lo:" | sed -n "${selection}p" | awk -F': ' '{print $2}')
           if [ -n "$selected_interface" ]; then
               echo "已选择网卡: $selected_interface" >&2
               echo "$selected_interface"
               break
           else
               echo "无效的选择，请重新输入" >&2
               continue
           fi
       else
           echo "已选择网卡: $selection" >&2
           echo "$selection"
           break
       fi
   done
}

# Check if all arguments are provided
if [ "$#" -ne 3 ]; then
 echo "Usage: $0 <auth_secret> <url> <name>"
 echo "Example: $0 your_secret wss://api.123.321 HK-Akile"
 exit 1
fi

# Get system architecture
ARCH=$(uname -m)
CLIENT_FILE="akile_client-linux-amd64"

# Set appropriate client file based on architecture
if [ "$ARCH" = "x86_64" ]; then
 CLIENT_FILE="akile_client-linux-amd64"
elif [ "$ARCH" = "aarch64" ]; then
 CLIENT_FILE="akile_client-linux-arm64"
elif [ "$ARCH" = "x86_64" ] && [ "$(uname -s)" = "Darwin" ]; then
 CLIENT_FILE="akile_client-darwin-amd64"
else
 echo "Unsupported architecture: $ARCH"
 exit 1
fi

# Assign command line arguments to variables
auth_secret="$1"
url="$2"
monitor_name="$3"

# Get network interface
net_name=$(get_main_interface)
echo "Using network interface: $net_name"

# Create directory and change to it
mkdir -p ~/ak_monitor
cd ~/ak_monitor

# Download client
wget -O client https://github.com/akile-network/akile_monitor/releases/latest/download/$CLIENT_FILE
chmod 777 client

# Create client configuration
cat > ~/ak_monitor/client.json << EOF
{
"auth_secret": "${auth_secret}",
"url": "${url}",
"net_name": "${net_name}",
"name": "${monitor_name}"
}
EOF

# Manually start the client
nohup ./client &
