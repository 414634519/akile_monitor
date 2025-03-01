#!/bin/bash

if [ "$#" -ne 3 ]; then
 echo "Usage: $0 <auth_secret> <url> <name>"
 exit 1
fi

auth_secret="$1"
url="$2"
monitor_name="$3"

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; then
  CLIENT_FILE="akile_client-linux-amd64"
elif [[ "$ARCH" == "i686" ]] || [[ "$ARCH" == "x86" ]]; then
  CLIENT_FILE="akile_client-linux-386"
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
  CLIENT_FILE="akile_client-linux-arm64"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi


mkdir -p ~/ak_monitor/
cd ~/ak_monitor/

wget -O client "https://github.com/akile-network/akile_monitor/releases/latest/download/$CLIENT_FILE" --no-check-certificate
chmod +x client

cat > client.json << EOF
{
  "auth_secret": "${auth_secret}",
  "url": "${url}",
  "name": "${monitor_name}"
}
EOF

nohup ./client > client.log 2>&1 &

if pgrep -f client > /dev/null; then
  echo "Akile Monitor Client is running successfully!"
else
  echo "Failed to start Akile Monitor Client."
fi
