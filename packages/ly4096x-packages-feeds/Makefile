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
	echo "src/gz ly4096x_packages https://ly4096x.github.io/my-openwrt-packages/$(CONFIG_VERSION_NUMBER)/packages/$(CONFIG_TARGET_ARCH_PACKAGES)" > $(1)/etc/opkg/distfeeds.d/ly4096x.conf
	$(INSTALL_DIR) $(1)/etc/apk/repositories.d
	echo "https://ly4096x.github.io/my-openwrt-packages/$(CONFIG_VERSION_NUMBER)/packages/$(CONFIG_TARGET_ARCH_PACKAGES)" > $(1)/etc/apk/repositories.d/ly4096x.list
endef

$(eval $(call BuildPackage,ly4096x-packages-feeds))
