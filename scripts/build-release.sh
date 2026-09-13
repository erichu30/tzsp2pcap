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
cp COPYING "$output/COPYING"
tar -czf "dist/tzsp2pcap-linux-$arch.tar.gz" -C "$output" tzsp2pcap COPYING
printf 'Built %s\n' "dist/tzsp2pcap-linux-$arch.tar.gz"
