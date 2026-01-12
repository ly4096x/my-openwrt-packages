#!/bin/bash

# Verify OpenWrt package signatures locally
# This script verifies that packages were properly signed with the key

set -e

ARCH="${ARCH:-x86_64}"
VERSION="${VERSION:-SNAPSHOT}"
ARTIFACTS_DIR=".temp/artifacts-${ARCH}-${VERSION}"

echo "========================================="
echo "Verifying Package Signatures"
echo "========================================="
echo "Architecture: ${ARCH}"
echo "Version: ${VERSION}"
echo "Artifacts: ${ARTIFACTS_DIR}"
echo ""

# Check if artifacts exist
if [ ! -d "${ARTIFACTS_DIR}/packages" ]; then
  echo "ERROR: No packages found at ${ARTIFACTS_DIR}/packages"
  echo "Run ./build-signed.sh first to build signed packages"
  exit 1
fi

# Check if public key exists
if [ ! -f "packages/ly4096x-keyring/files/key.pub" ]; then
  echo "ERROR: Public key not found"
  exit 1
fi

# Detect package format (APK v3 with .adb or OPKG with Packages.sig)
PACKAGES_ADB=$(find "${ARTIFACTS_DIR}/packages" -name "packages.adb" | head -1)
PACKAGES_SIG=$(find "${ARTIFACTS_DIR}/packages" -name "Packages.sig" | head -1)

if [ -n "$PACKAGES_ADB" ]; then
  echo "Detected APK v3 format (packages.adb)"
  echo "Package index: $PACKAGES_ADB"
  echo ""

  PACKAGES_DIR=$(dirname "$PACKAGES_ADB")
  PACKAGES_DIR="$(cd "$PACKAGES_DIR" && pwd)"

  # Verify APK v3 signature
  echo "Verifying APK v3 signature using apk in Docker..."
  echo ""

  # Run verification in Docker with apk tools
  docker run --rm \
    -v "$PWD/packages/ly4096x-keyring/files/key.pub:/etc/apk/keys/712bfbad30870c38:ro" \
    -v "${PACKAGES_DIR}:/packages:ro" \
    openwrt/rootfs:x86_64-SNAPSHOT \
    sh -c "
      echo 'Verifying APK database signature with public key...'
      apk verify --allow-untrusted /packages/packages.adb 2>&1
      if [ \$? -eq 0 ]; then
        echo ''
        echo '✓ SIGNATURE VALID: Packages were correctly signed with your key'
        exit 0
      else
        echo ''
        echo '✗ SIGNATURE INVALID: Verification failed!'
        exit 1
      fi
    "

  VERIFY_RESULT=$?

elif [ -n "$PACKAGES_SIG" ]; then
  echo "Detected OPKG format (Packages.sig)"
  echo "Signature file: $PACKAGES_SIG"
  echo ""

  PACKAGES_DIR=$(dirname "$PACKAGES_SIG")
  PACKAGES_DIR="$(cd "$PACKAGES_DIR" && pwd)"
  PACKAGES_FILE="${PACKAGES_DIR}/Packages"

  if [ ! -f "$PACKAGES_FILE" ]; then
    # Try compressed versions
    if [ -f "${PACKAGES_FILE}.gz" ]; then
      echo "Decompressing Packages.gz..."
      gunzip -k "${PACKAGES_FILE}.gz"
    elif [ -f "${PACKAGES_FILE}.zst" ]; then
      echo "Decompressing Packages.zst..."
      zstd -d "${PACKAGES_FILE}.zst" -o "${PACKAGES_FILE}"
    else
      echo "ERROR: Packages file not found: $PACKAGES_FILE"
      exit 1
    fi
  fi

  # Run verification in Docker with usign
  echo "Verifying OPKG signature using usign in Docker..."
  echo ""

  docker run --rm \
    -v "$PWD/packages/ly4096x-keyring/files/key.pub:/key.pub:ro" \
    -v "${PACKAGES_DIR}:/packages:ro" \
    openwrt/rootfs:x86_64-SNAPSHOT \
    sh -c "
      # Install usign (apk works in newer containers)
      if ! command -v usign 2>&1; then
        apk add usign 2>&1 || (opkg update 2>&1 && opkg install usign 2>&1)
      fi
      echo 'Verifying with public key...'
      usign -V -m /packages/Packages -p /key.pub 2>&1
      if [ \$? -eq 0 ]; then
        echo ''
        echo '✓ SIGNATURE VALID: Packages were correctly signed with your key'
        exit 0
      else
        echo ''
        echo '✗ SIGNATURE INVALID: Verification failed!'
        exit 1
      fi
    "

  VERIFY_RESULT=$?

else
  echo "ERROR: No package index signature found"
  echo "Searched for:"
  echo "  - packages.adb (APK v3 format)"
  echo "  - Packages.sig (OPKG format)"
  echo ""
  echo "This indicates packages were built without signing."
  echo "Make sure to use KEY_BUILD when building."
  exit 1
fi

echo ""
echo "========================================="
if [ $VERIFY_RESULT -eq 0 ]; then
  echo "✓ Verification SUCCESS"
  echo "========================================="
  echo ""
  echo "Your packages are properly signed and verified!"
  echo ""
  echo "Package index location:"
  echo "  $PACKAGES_DIR/Packages"
  echo ""
  echo "Signed packages:"
  find "${ARTIFACTS_DIR}/packages" -name "*.ipk" -o -name "*.apk" | head -10
  echo ""
  TOTAL=$(find "${ARTIFACTS_DIR}/packages" -name "*.ipk" -o -name "*.apk" | wc -l)
  echo "Total: $TOTAL packages"
else
  echo "✗ Verification FAILED"
  echo "========================================="
  echo ""
  echo "The signature verification failed. This could mean:"
  echo "  1. Packages were not signed (KEY_BUILD not provided)"
  echo "  2. Wrong key was used for signing"
  echo "  3. Packages were modified after signing"
  exit 1
fi

echo "========================================="
