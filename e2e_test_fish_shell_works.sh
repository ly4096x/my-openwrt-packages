#!/bin/bash

# Test package installation from GitHub Pages across all OpenWrt versions
# This script tests the actual end-user installation experience

set -e

REPO_URL="https://ly4096x.github.io/my-openwrt-packages"
ARCH="x86-64"
RESULTS_FILE="/tmp/openwrt-test-results.txt"

# Clear previous results
> "$RESULTS_FILE"

log_result() {
    echo "$1" | tee -a "$RESULTS_FILE"
}

test_openwrt_2410() {
    log_result ""
    log_result "========================================="
    log_result "Testing OpenWrt 24.10 (OPKG)"
    log_result "========================================="

    CONTAINER="openwrt/rootfs:${ARCH}-openwrt-24.10"

    docker pull "$CONTAINER" 2>&1 | tee -a "$RESULTS_FILE"

    # Test installation following README instructions
    TEST_SCRIPT='
set -e
mkdir -p /var/lock

echo "Step 1: Installing keyring..."
wget -q https://ly4096x.github.io/my-openwrt-packages/ly4096x-keyring.ipk
opkg install ly4096x-keyring.ipk 2>&1

echo "Step 2: Configuring feed..."
echo "src/gz ly4096x_packages https://ly4096x.github.io/my-openwrt-packages/24.10/packages/x86_64" >> /etc/opkg/customfeeds.conf

echo "Step 3: Updating package list..."
opkg update 2>&1

echo "Step 4: Installing fish..."
opkg install fish 2>&1

echo "Step 5: Verifying fish installation..."
fish --version

echo "Step 6: Testing fish functionality..."
fish -c "math 7+10000" | grep -q 10007 && echo "Fish math test: PASS"

echo "Step 7: Testing command substitution..."
fish -c "echo (math 5+5)" | grep -q 10 && echo "Fish command substitution: PASS"
'

    if timeout 600 docker run --rm "$CONTAINER" sh -c "$TEST_SCRIPT" 2>&1 | tee -a "$RESULTS_FILE"; then
        log_result "✓ OpenWrt 24.10 (OPKG): SUCCESS"
        return 0
    else
        log_result "✗ OpenWrt 24.10 (OPKG): FAILED"
        return 1
    fi
}

test_openwrt_2512() {
    log_result ""
    log_result "========================================="
    log_result "Testing OpenWrt 25.12 (APK)"
    log_result "========================================="

    CONTAINER="openwrt/rootfs:${ARCH}-openwrt-25.12"

    docker pull "$CONTAINER" 2>&1 | tee -a "$RESULTS_FILE"

    TEST_SCRIPT='
set -e
mkdir -p /var/lock

echo "Step 1: Installing keyring..."
wget -q https://ly4096x.github.io/my-openwrt-packages/ly4096x-keyring.apk
apk add --allow-untrusted ly4096x-keyring.apk 2>&1

echo "Step 2: Configuring feed..."
echo "https://ly4096x.github.io/my-openwrt-packages/25.12/packages/x86_64" >> /etc/apk/repositories.d/ly4096x.list

echo "Step 3: Updating package list..."
apk update 2>&1

echo "Step 4: Installing fish..."
apk add fish 2>&1

echo "Step 5: Verifying fish installation..."
fish --version

echo "Step 6: Testing fish functionality..."
fish -c "math 7+10000" | grep -q 10007 && echo "Fish math test: PASS"

echo "Step 7: Testing command substitution..."
fish -c "echo (math 5+5)" | grep -q 10 && echo "Fish command substitution: PASS"
'

    if timeout 600 docker run --rm "$CONTAINER" sh -c "$TEST_SCRIPT" 2>&1 | tee -a "$RESULTS_FILE"; then
        log_result "✓ OpenWrt 25.12 (APK): SUCCESS"
        return 0
    else
        log_result "✗ OpenWrt 25.12 (APK): FAILED"
        return 1
    fi
}

test_openwrt_snapshot() {
    log_result ""
    log_result "========================================="
    log_result "Testing OpenWrt SNAPSHOT"
    log_result "========================================="

    CONTAINER="openwrt/rootfs:${ARCH}-snapshot"

    docker pull "$CONTAINER" 2>&1 | tee -a "$RESULTS_FILE"

    # Check which package manager SNAPSHOT uses and test accordingly
    PKG_MGR=$(docker run --rm "$CONTAINER" sh -c "if which apk >/dev/null 2>&1; then echo apk; else echo opkg; fi")
    log_result "Detected package manager: $PKG_MGR"

    if [ "$PKG_MGR" = "apk" ]; then
        # APK-based SNAPSHOT
        TEST_SCRIPT='
set -e
mkdir -p /var/lock

echo "Step 1: Installing keyring..."
wget -q https://ly4096x.github.io/my-openwrt-packages/ly4096x-keyring.apk
apk add --allow-untrusted ly4096x-keyring.apk 2>&1

echo "Step 2: Configuring feed..."
echo "https://ly4096x.github.io/my-openwrt-packages/SNAPSHOT/packages/x86_64" >> /etc/apk/repositories.d/ly4096x.list

echo "Step 3: Updating package list..."
apk update 2>&1

echo "Step 4: Installing fish..."
apk add fish 2>&1

echo "Step 5: Verifying fish installation..."
fish --version

echo "Step 6: Testing fish functionality..."
fish -c "math 7+10000" | grep -q 10007 && echo "Fish math test: PASS"

echo "Step 7: Testing command substitution..."
fish -c "echo (math 5+5)" | grep -q 10 && echo "Fish command substitution: PASS"
'
    else
        # OPKG-based SNAPSHOT (older)
        TEST_SCRIPT='
set -e
mkdir -p /var/lock

echo "Step 1: Installing keyring..."
wget -q https://ly4096x.github.io/my-openwrt-packages/ly4096x-keyring.ipk
opkg install ly4096x-keyring.ipk 2>&1

echo "Step 2: Configuring feed..."
echo "src/gz ly4096x_packages https://ly4096x.github.io/my-openwrt-packages/SNAPSHOT/packages/x86_64" >> /etc/opkg/customfeeds.conf

echo "Step 3: Updating package list..."
opkg update 2>&1

echo "Step 4: Installing fish..."
opkg install fish 2>&1

echo "Step 5: Verifying fish installation..."
fish --version

echo "Step 6: Testing fish functionality..."
fish -c "math 7+10000" | grep -q 10007 && echo "Fish math test: PASS"

echo "Step 7: Testing command substitution..."
fish -c "echo (math 5+5)" | grep -q 10 && echo "Fish command substitution: PASS"
'
    fi

    if timeout 600 docker run --rm "$CONTAINER" sh -c "$TEST_SCRIPT" 2>&1 | tee -a "$RESULTS_FILE"; then
        log_result "✓ OpenWrt SNAPSHOT: SUCCESS"
        return 0
    else
        log_result "✗ OpenWrt SNAPSHOT: FAILED"
        return 1
    fi
}

# Run all tests
FAILED=0

test_openwrt_2410 || FAILED=$((FAILED+1))
test_openwrt_2512 || FAILED=$((FAILED+1))
test_openwrt_snapshot || FAILED=$((FAILED+1))

# Summary
log_result ""
log_result "========================================="
log_result "TEST SUMMARY"
log_result "========================================="
if [ $FAILED -eq 0 ]; then
    log_result "✓ All tests passed (3/3)"
    log_result ""
    log_result "Results saved to: $RESULTS_FILE"
    exit 0
else
    log_result "✗ Some tests failed ($FAILED/3)"
    log_result ""
    log_result "Results saved to: $RESULTS_FILE"
    exit 1
fi
