#!/bin/bash

# Docker-based build script for OpenWrt packages

set -e

echo "========================================="
echo "OpenWrt Package Build (Docker)"
echo "========================================="
echo "Architecture: ${ARCH}"
echo "Version: ${VERSION}"
echo "ARCH: ${ARCH}"
echo "Feed Directory: ${FEED_DIR}"
echo "Packages: ${PACKAGES}"
echo "========================================="
echo ""
echo "Available workflow configurations:"
echo "  Versions: openwrt-24.10, openwrt-25.12, SNAPSHOT"
echo "  Architectures: aarch64_cortex-a53, aarch64_cortex-a72, x86_64"
echo ""
echo "Example usage:"
echo "  ARCH=aarch64_cortex-a53 VERSION=openwrt-24.10 ./build-packages.sh"
echo "  ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh"
echo "  PACKAGES=\"ly4096x-keyring\" ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh"
echo "========================================="
echo ""

# Configuration (matching workflow matrix)
ARCH="${ARCH}"
VERSION="${VERSION}"
FEED_DIR="${PWD}/packages"
KEY_BUILD="${KEY_BUILD}"
FILE_HOST="${FILE_HOST}"  # Optional: Use proxy mirror for faster downloads

# Check required parameters are not empty
if [ -z "$ARCH" ]; then
  echo "ERROR: ARCH environment variable is not set"
  echo "Example: ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "ERROR: VERSION environment variable is not set"
  echo "Example: ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh"
  exit 1
fi

# Generate package list (matching workflow)
if [ -z "$PACKAGES" ]; then
  echo "Generating package list from packages/ directory..."
  PACKAGES=$(ls -d packages/*/ 2>/dev/null | xargs -n1 basename | tr '\n' ' ' || echo "")
  if [ -z "$PACKAGES" ]; then
    echo "Error: No packages found in packages/ directory"
    exit 1
  fi
  echo "Auto-detected packages: $PACKAGES"
else
  echo "Building specified packages: $PACKAGES"
fi

DOCKER_IMAGE="${DOCKER_IMAGE:-openwrt/sdk:${ARCH}-${VERSION}}"
echo "Docker image: ${DOCKER_IMAGE}"
echo

# Create temp directories for this specific build
ARTIFACTS_DIR="${PWD}/.temp/artifacts/${ARCH}/${VERSION}"
mkdir -p "${ARTIFACTS_DIR}"

# Container name for easy management
CONTAINER_NAME="openwrt-build-${ARCH}-${VERSION}"

# Run the build in Docker
echo "Starting build process..."
echo "Container name: ${CONTAINER_NAME}"
docker run --rm \
  --user root \
  --name "${CONTAINER_NAME}" \
  -v "${FEED_DIR}:/feed" \
  -v "${ARTIFACTS_DIR}:/builder/bin" \
  -v "${PWD}/docker-entrypoint.sh:/builder/entrypoint.sh:ro" \
  -e ARCH="${ARCH}-${VERSION}" \
  -e FEEDNAME=localbuilt \
  -e PACKAGES="${PACKAGES}" \
  -e INDEX="${INDEX:-1}" \
  -e V=s \
  -e KEY_BUILD="${KEY_BUILD}" \
  -e FILE_HOST="${FILE_HOST}" \
  "${DOCKER_IMAGE}" \
  bash /builder/entrypoint.sh

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
if [ -d "${ARTIFACTS_DIR}/packages" ]; then
  echo "Output location: ${ARTIFACTS_DIR}/packages/"
  find "${ARTIFACTS_DIR}/packages" -name "*.ipk" -o -name "*.apk" | head -20
  echo ""
  echo "Total packages built:"
  find "${ARTIFACTS_DIR}/packages" -name "*.ipk" -o -name "*.apk" | wc -l
else
  echo "No packages found"
fi
echo "========================================="
