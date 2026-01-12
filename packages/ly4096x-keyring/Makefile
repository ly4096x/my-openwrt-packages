include $(TOPDIR)/rules.mk

PKG_NAME:=ly4096x-keyring
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=ly4096x

include $(INCLUDE_DIR)/package.mk

define Package/ly4096x-keyring
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=ly4096x package signing key
  PKGARCH:=all
endef

define Package/ly4096x-keyring/description
  The public key for ly4096x's package feed.
endef

define Build/Compile
endef

define Package/ly4096x-keyring/install
	$(INSTALL_DIR) $(1)/etc/opkg/keys
	$(INSTALL_DATA) ./files/key.pub $(1)/etc/opkg/keys/b2b5dcacab8d299a
	$(INSTALL_DIR) $(1)/etc/apk/keys
	$(INSTALL_DATA) ./files/key.pub $(1)/etc/apk/keys/b2b5dcacab8d299a
endef

$(eval $(call BuildPackage,ly4096x-keyring))
