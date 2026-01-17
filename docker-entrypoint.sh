#!/bin/bash

# Entrypoint script for OpenWrt SDK Docker container
# This script runs inside the container to build packages

set -e  # Exit on any error
set -u  # Exit on undefined variables
set -o pipefail  # Exit on pipe failures

echo "========================================="
echo "OpenWrt SDK Build Entrypoint"
echo "========================================="

# Remove artifacts from previous build if any
if [ -d bin ]; then
  echo "Cleaning previous build artifacts..."
  rm -rf bin/*
fi

# Setup SDK (for SNAPSHOT builds)
if [ -f setup.sh ]; then
  echo "Running setup.sh to download SDK..."
  if ! ./setup.sh; then
    echo "ERROR: Failed to run setup.sh"
    exit 1
  fi
fi

# Install Rust toolchain if not present (required for Fish 4.x)
if ! command -v cargo &> /dev/null; then
  echo "Installing Rust toolchain..."

  # Download rustup installer (use wget as it's more common in OpenWrt SDK)
  if command -v wget &> /dev/null; then
    if ! wget -O /tmp/rustup-init.sh https://sh.rustup.rs; then
      echo "ERROR: Failed to download rustup installer"
      exit 1
    fi
  elif command -v curl &> /dev/null; then
    if ! curl --proto '=https' --tlsv1.2 -sSf -o /tmp/rustup-init.sh https://sh.rustup.rs; then
      echo "ERROR: Failed to download rustup installer"
      exit 1
    fi
  else
    echo "ERROR: Neither wget nor curl found. Cannot install Rust."
    exit 1
  fi

  # Install Rust
  if ! sh /tmp/rustup-init.sh -y --default-toolchain stable --profile minimal; then
    echo "ERROR: Failed to install Rust"
    exit 1
  fi
  rm /tmp/rustup-init.sh

  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
  else
    echo "ERROR: Cargo environment file not found after installation"
    exit 1
  fi

  echo "Rust installed: $(rustc --version)"
  echo "Cargo installed: $(cargo --version)"
else
  # Ensure Rust is in PATH if already installed
  [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
fi

# Install musl target for cross-compilation (required for OpenWrt)
# Determine the appropriate Rust target based on the SDK architecture
echo "Installing Rust musl target for cross-compilation..."

# Extract architecture from ARCH environment variable (format: arch-version)
# Default to x86_64 if ARCH is not set
SDK_ARCH="${ARCH:-x86_64}"
SDK_ARCH="${SDK_ARCH%%-*}"

# Map OpenWrt architecture to Rust target triple
case "$SDK_ARCH" in
  x86_64)
    RUST_TARGET="x86_64-unknown-linux-musl"
    ;;
  aarch64*)
    RUST_TARGET="aarch64-unknown-linux-musl"
    ;;
  arm*)
    # Default to armv7 for most ARM targets
    RUST_TARGET="armv7-unknown-linux-musleabihf"
    ;;
  mips)
    RUST_TARGET="mips-unknown-linux-musl"
    ;;
  mipsel)
    RUST_TARGET="mipsel-unknown-linux-musl"
    ;;
  *)
    # Default fallback
    RUST_TARGET="x86_64-unknown-linux-musl"
    echo "WARNING: Unknown architecture '$SDK_ARCH', defaulting to $RUST_TARGET"
    ;;
esac

if ! rustup target add "$RUST_TARGET"; then
  echo "ERROR: Failed to add Rust target: $RUST_TARGET"
  exit 1
fi
echo "Rust target added: $RUST_TARGET"

# Export Rust PATH for CMake to find
export PATH="$HOME/.cargo/bin:$PATH"
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"

# Add custom feed, keeping defaults
if [ -f feeds.conf.default ]; then
  sed -e 's|https://git.openwrt.org/openwrt/openwrt.git|https://github.com/openwrt/openwrt.git|g' \
      -e 's|https://git.openwrt.org/feed/packages.git|https://github.com/openwrt/packages.git|g' \
      -e 's|https://git.openwrt.org/project/luci.git|https://github.com/openwrt/luci.git|g' \
      -e 's|https://git.openwrt.org/feed/routing.git|https://github.com/openwrt/routing.git|g' \
      -e 's|https://git.openwrt.org/feed/telephony.git|https://github.com/openwrt/telephony.git|g' \
      feeds.conf.default > feeds.conf
fi
echo "src-link ${FEEDNAME} /feed" >> feeds.conf

# Show feed configuration
echo "Feed configuration:"
cat feeds.conf

# Update feeds
echo "Updating feeds..."
if ! ./scripts/feeds update base packages; then
  echo "ERROR: Failed to update feeds"
  exit 1
fi

# Install packages from custom feed
if [ -n "$PACKAGES" ]; then
  echo "Installing packages: $PACKAGES"
  # First update the custom feed to be sure
  ./scripts/feeds update "${FEEDNAME}"
  for pkg in $PACKAGES; do
    if ! ./scripts/feeds install -p "${FEEDNAME}" "$pkg"; then
      echo "ERROR: Failed to install package: $pkg"
      exit 1
    fi
  done
else
  echo "No specific packages specified, installing all from feed..."
  if ! ./scripts/feeds install -p "${FEEDNAME}" -a; then
    echo "ERROR: Failed to install packages from feed"
    exit 1
  fi
fi

# Configure
echo "Running make defconfig..."
if ! make defconfig; then
  echo "ERROR: Failed to run make defconfig"
  exit 1
fi

# Build packages
if [ -n "$PACKAGES" ]; then
  echo "Building packages: $PACKAGES"
  for pkg in $PACKAGES; do
    echo "Building $pkg..."
    if ! make "package/$pkg/compile" V="${V:-s}" -j"$(nproc)"; then
      echo "ERROR: Failed to build package: $pkg"
      exit 1
    fi
  done
else
  echo "Building all packages from feed..."
  if ! make V="${V:-s}" -j"$(nproc)"; then
    echo "ERROR: Failed to build packages"
    exit 1
  fi
fi

# Generate package index
if [ "${INDEX}" = "1" ]; then
  echo "Generating package index..."

  # Sign packages if key provided
  if [ -n "$KEY_BUILD" ]; then
    echo "$KEY_BUILD" > key-build
    if ! make package/index V=s CONFIG_SIGNED_PACKAGES=y; then
      echo "ERROR: Failed to generate signed package index"
      exit 1
    fi
  else
    # For local builds without KEY_BUILD, disable package signing
    echo "KEY_BUILD not provided - building unsigned packages for local testing..."
    # Disable signed packages in SDK config
    if [ -f .config ]; then
      sed -i 's/^CONFIG_SIGNED_PACKAGES=y/# CONFIG_SIGNED_PACKAGES is not set/' .config
    fi
    if ! make package/index V=s; then
      echo "ERROR: Failed to generate package index"
      exit 1
    fi
  fi
fi

echo "========================================="
echo "Build complete!"
echo "========================================="
find bin/packages -type f \( -name "*.ipk" -o -name "*.apk" \) 2>/dev/null || echo "No packages found"
