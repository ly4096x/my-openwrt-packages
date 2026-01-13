# My OpenWrt Packages

This repository contains custom OpenWrt packages built using GitHub Actions.

## Packages

- **ly4096x-keyring**: Contains the public key for verifying signed packages.
- **fish**: The Fish shell.

## Installation

### 1. Install Keyring

First, download and install the keyring package to trust the repository.

```sh
# For OPKG (OpenWrt 24.10 and older)
wget https://ly4096x.github.io/my-openwrt-packages/ly4096x-keyring.ipk
opkg install ly4096x-keyring.ipk

# For APK (OpenWrt 25.12 and newer)
wget https://ly4096x.github.io/my-openwrt-packages/ly4096x-keyring.apk
apk add --allow-untrusted ly4096x-keyring.apk
```

### 2. Configure Feed

Add the feed URL to your package manager configuration. Replace `24.10`/`aarch64_cortex-a53` with your specific version/architecture if different.

**OPKG (OpenWrt 24.10 and older):**
```sh
echo "src/gz ly4096x_packages https://ly4096x.github.io/my-openwrt-packages/24.10/packages/aarch64_cortex-a53" >> /etc/opkg/customfeeds.conf
opkg update
```

**APK (OpenWrt 25.12 and newer):**
```sh
echo "https://ly4096x.github.io/my-openwrt-packages/25.12/packages/aarch64_cortex-a53" >> /etc/apk/repositories.d/ly4096x.list
apk update
```

### 3. Install Packages

Now you can install packages from the feed.

```sh
opkg update
opkg install fish

# or

apk update
apk add fish
```

## Development

### Adding a new package

1. Create a directory in `packages/`.
2. Add `Makefile` and necessary files.
3. Push to `main` branch.

### Building Locally with Docker

You can build packages locally using Docker without needing a full OpenWrt build environment:

```sh
# Build all packages for x86_64 SNAPSHOT
ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh

# Build specific package
PACKAGES="fish" ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh

# Build for different architecture/version
ARCH="aarch64_cortex-a53" VERSION="openwrt-24.10" ./build-packages.sh

# Build multiple packages
PACKAGES="ly4096x-keyring fish" ARCH=x86_64 VERSION=SNAPSHOT ./build-packages.sh
```

**Build artifacts:**
- Built packages: `.temp/artifacts/{ARCH}/{VERSION}/packages/`

**Requirements:**
- Docker installed and running

**Notes:**
- First build downloads the OpenWrt SDK (~300MB), which takes time depending on connection speed
- Subsequent builds are much faster if the SDK image is present
- All build artifacts are stored in `.temp/` which is gitignored and can be safely deleted to reclaim space

### GitHub Actions

The workflow in `.github/workflows/build-packages.yml` automatically builds and signs packages for:
- OpenWrt 24.10
- OpenWrt 25.12
- OpenWrt SNAPSHOT

Architectures:
- x86_64
- aarch64_cortex-a53
- aarch64_cortex-a72

**Build triggers:**
- Push to main (packages or workflow changes)
- Manual workflow dispatch
- Weekly schedule (Sunday 2 AM UTC)

**Deployment:**
Packages are automatically deployed to gh-pages and accessible at:
https://ly4096x.github.io/my-openwrt-packages/