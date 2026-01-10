include $(TOPDIR)/rules.mk

PKG_NAME:=ly4096x-packages-feeds
PKG_VERSION:=20250103
PKG_RELEASE:=1
PKG_MAINTAINER:=ly4096x

include $(INCLUDE_DIR)/package.mk

define Package/ly4096x-packages-feeds
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=ly4096x packages feed configuration
  PKGARCH:=all
endef

define Package/ly4096x-packages-feeds/description
  Feeds configuration for ly4096x's packages.
endef

define Build/Compile
endef

define Package/ly4096x-packages-feeds/install
	$(INSTALL_DIR) $(1)/etc/opkg/distfeeds.d
	$(INSTALL_DIR) $(1)/etc/apk/repositories.d
	$(INSTALL_DIR) $(1)/usr/lib/opkg/info

	# Create post-install script that will set the correct feed URL at install time
	$(INSTALL_BIN) ./files/postinst $(1)/usr/lib/opkg/info/ly4096x-packages-feeds.postinst || true
endef

define Package/ly4096x-packages-feeds/postinst
#!/bin/sh
# Detect OpenWrt version and architecture from /etc/os-release
if [ -f /etc/os-release ]; then
	. /etc/os-release

	# Extract version (e.g., "24.10", "25.12", or "SNAPSHOT")
	if [ "$$VERSION_ID" = "snapshot" ]; then
		FEED_VERSION="SNAPSHOT"
	else
		FEED_VERSION="$${VERSION_ID}"
	fi

	# Get architecture
	FEED_ARCH="$${OPENWRT_ARCH:-x86_64}"

	# Create OPKG feed configuration
	echo "src/gz ly4096x_packages https://ly4096x.github.io/my-openwrt-packages/$$FEED_VERSION/packages/$$FEED_ARCH" > /etc/opkg/distfeeds.d/ly4096x.conf

	# Create APK repository configuration
	echo "https://ly4096x.github.io/my-openwrt-packages/$$FEED_VERSION/packages/$$FEED_ARCH" > /etc/apk/repositories.d/ly4096x.list

	echo "Configured ly4096x package feed for OpenWrt $$FEED_VERSION ($$FEED_ARCH)"
fi
endef

$(eval $(call BuildPackage,ly4096x-packages-feeds))
