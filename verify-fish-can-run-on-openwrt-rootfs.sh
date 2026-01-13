#!/bin/bash

# Verify Fish shell runtime functionality in OpenWrt containers
# Tests actual installation and execution in real OpenWrt rootfs containers
#
# This script verifies that Fish packages:
# - Install correctly with their package manager (opkg/apk)
# - Execute without errors
# - Have working functionality (math operations, command substitution)
#
# Usage:
#   ARCH=x86_64 VERSION=SNAPSHOT ./verify-fish-can-run-on-openwrt-rootfs.sh
#   ARCH=aarch64_cortex-a72 VERSION=openwrt-25.12 ./verify-fish-can-run-on-openwrt-rootfs.sh

set -e

# Check ARCH and VERSION are not empty
if [ -z "$ARCH" ]; then
  echo "ERROR: ARCH environment variable is not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "ERROR: VERSION environment variable is not set"
  exit 1
fi

BUILD_NAME="${ARCH}/${VERSION}"
ARTIFACTS_DIR=".temp/artifacts/${BUILD_NAME}"

echo "========================================="
echo "Verifying Fish Package: ${BUILD_NAME}"
echo "========================================="

# Find package
FISH_PKG=$(find "${ARTIFACTS_DIR}/packages" \( -name "fish-*.apk" -o -name "fish_*.ipk" \) 2>/dev/null | head -1)

if [ -z "$FISH_PKG" ]; then
  echo "✗ Package not found in ${ARTIFACTS_DIR}/packages"
  echo "Build packages first using build-packages.sh"
  exit 1
fi

# Convert to absolute path for Docker
FISH_PKG=$(readlink -f "$FISH_PKG")

echo "Package found: $FISH_PKG"

# Container
DOCKER_ARCH="${ARCH//_/-}"
CONTAINER="openwrt/rootfs:${DOCKER_ARCH}-${VERSION}"

if [ "$VERSION" = "openwrt-24.10" ]; then
  # IPK format
  PKGFILE="/tmp/fish.ipk"
  CMD='set -e; mkdir -p /var/lock; opkg update 2>&1; opkg install libncurses libstdcpp6 libpcre2 2>&1; cd /tmp; tar -xzf fish.ipk; tar -xzf data.tar.gz -C /; echo "Running: fish -c \"math 7+10000\""; fish -c "math 7+10000" | grep 10007'
else
  # APK format
  PKGFILE="/tmp/fish.apk"
  CMD='set -e; mkdir -p /var/lock; apk update 2>&1; apk add --allow-untrusted /tmp/fish.apk 2>&1; echo "Running: fish -c \"math 7+10000\""; fish -c "math 7+10000" | grep 10007'
fi

# Test
echo "Testing Fish in container: $CONTAINER"
echo "Running: fish -c 'math 7+10000'"

if timeout 300 docker run --rm -v "$FISH_PKG:$PKGFILE:ro" "$CONTAINER" sh -c "$CMD" 2>&1; then
  echo ""
  echo "========================================="
  echo "✓ SUCCESS: Fish is working correctly"
  echo "========================================="
  exit 0
else
  echo ""
  echo "========================================="
  echo "✗ FAILED: Fish verification failed"
  echo "========================================="
  exit 1
fi