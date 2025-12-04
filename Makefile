# SPDX-License-Identifier: GPL-3
#
# Copyright (C) 2023-2026 ly4096x

include $(TOPDIR)/rules.mk

PKG_NAME:=my-openwrt-packages
PKG_VERSION:=1.0
PKG_RELEASE:=20260104

PKG_MAINTAINER:=ly4096x
PKG_LICENSE:=GPL-3
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/Default
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=ly4096x openwrt packages
	URL:=https://github.com/ly4096x/my-openwrt-packages
	PKGARCH:=all
	DEPENDS:=
endef

define Package/$(PKG_NAME)-packages
	$(call Package/$(PKG_NAME)/Default)
	DEPENDS+:=\
		+fish \
		+ly4096x-keyring
endef

define Package/$(PKG_NAME)
	$(call Package/$(PKG_NAME)/Default)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/conffiles
endef

define Package/$(PKG_NAME)/postinst
endef

define Package/$(PKG_NAME)/prerm
endef

define Package/$(PKG_NAME)/install/Default
	:
endef

Package/$(PKG_NAME)-packages/install = $(Package/$(PKG_NAME)/install/Default)
Package/$(PKG_NAME)-luci/install = $(Package/$(PKG_NAME)/install/Default)
Package/$(PKG_NAME)/install = $(Package/$(PKG_NAME)/install/Default)

$(eval $(call BuildPackage,$(PKG_NAME)-packages))
$(eval $(call BuildPackage,$(PKG_NAME)-luci))
$(eval $(call BuildPackage,$(PKG_NAME)))