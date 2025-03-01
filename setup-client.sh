#!/bin/bash
SECRET=$1
URL=$2
NAME=$3

if [ -z "$SECRET" ] || [ -z "$URL" ] || [ -z "$NAME" ]; then
    echo "Usage: $0 <secret> <url> <name>"
    exit 1
fi

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

wget -O client "https://github.com/akile-network/akile_monitor/releases/latest/download/$CLIENT_FILE"
chmod +x client

nohup ./client -s $SECRET -u $URL -n $NAME >/dev/null 2>&1 &

echo "Akile Monitor Client is running successfully!"
