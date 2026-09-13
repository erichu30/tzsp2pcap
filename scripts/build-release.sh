#!/bin/sh
set -eu

arch=${1:?Usage: scripts/build-release.sh amd64|arm64}
case "$arch" in
    amd64|arm64) ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

cd "$(dirname "$0")/.."
output="dist/linux-$arch"
mkdir -p "$output"
docker buildx build --platform "linux/$arch" --target release \
    --output "type=local,dest=$output" .
binary="dist/tzsp2pcap-linux-$arch"
cp "$output/tzsp2pcap" "$binary"
chmod 755 "$binary"
printf 'Built %s\n' "$binary"
