#!/bin/bash

# Verify Node.js and python-netifaces in OpenWrt containers

set -e

ARCH="${ARCH:-x86_64}"
VERSION="${VERSION:-openwrt-24.10}"
BUILD_NAME="${ARCH}/${VERSION}"
ARTIFACTS_DIR=".temp/artifacts/${BUILD_NAME}"

echo "========================================="
echo "Verifying Packages: ${BUILD_NAME}"
echo "========================================="

# Find packages
NODE_PKG=$(find "${ARTIFACTS_DIR}/packages" -name "node_*.ipk" 2>/dev/null | head -1)
NPM_PKG=$(find "${ARTIFACTS_DIR}/packages" -name "node-npm_*.ipk" 2>/dev/null | head -1)
NETIFACES_PKG=$(find "${ARTIFACTS_DIR}/packages" -name "python3-netifaces_*.ipk" 2>/dev/null | head -1)

if [ -z "$NODE_PKG" ] || [ -z "$NETIFACES_PKG" ]; then
  echo "✗ Packages not found in ${ARTIFACTS_DIR}/packages"
  exit 1
fi

# Convert to absolute paths
NODE_PKG=$(readlink -f "$NODE_PKG")
NPM_PKG=$(readlink -f "$NPM_PKG")
NETIFACES_PKG=$(readlink -f "$NETIFACES_PKG")
ARTIFACTS_DIR_ABS=$(readlink -f "${ARTIFACTS_DIR}/packages")

DOCKER_ARCH="${ARCH//_/-}"
CONTAINER="openwrt/rootfs:${DOCKER_ARCH}-${VERSION}"

# Test Node.js
echo "Testing Node.js..."
CMD_NODE="set -e; \
  mkdir -p /var/lock; \
  find /tmp/packages -name Packages.gz | xargs -n1 dirname | while read dir; do \
    echo \"src/gz local_\$(basename \$dir) file://\$dir\" >> /etc/opkg/customfeeds.conf; \
  done; \
  opkg update || true; \
  opkg install node node-npm --force-checksum; \
  node -v; \
  npm -v"

if sudo docker run --rm -v "${ARTIFACTS_DIR_ABS}:/tmp/packages:ro" "$CONTAINER" sh -c "$CMD_NODE"; then
  echo "✓ Node.js is working"
else
  echo "✗ Node.js verification failed"
  exit 1
fi

# Test python-netifaces
echo "Testing python-netifaces..."
CMD_PY="set -e; \
  mkdir -p /var/lock; \
  find /tmp/packages -name Packages.gz | xargs -n1 dirname | while read dir; do \
    echo \"src/gz local_\$(basename \$dir) file://\$dir\" >> /etc/opkg/customfeeds.conf; \
  done; \
  opkg update || true; \
  opkg install python3-netifaces --force-checksum; \
  python3 -c 'import netifaces; print(netifaces.interfaces())'"

if sudo docker run --rm -v "${ARTIFACTS_DIR_ABS}:/tmp/packages:ro" "$CONTAINER" sh -c "$CMD_PY"; then
  echo "✓ python-netifaces is working"
else
  echo "✗ python-netifaces verification failed"
  exit 1
fi

echo "========================================="
echo "✓ ALL SUCCESS"
echo "========================================="
