include $(TOPDIR)/rules.mk

PKG_NAME:=fish
PKG_VERSION:=4.3.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=https://github.com/fish-shell/fish-shell/releases/download/$(PKG_VERSION)
PKG_HASH:=36a09cfc7fc2d1f1d0b6f5caf3828998621721f8c60a7a31ec55679286a9fe1c

PKG_MAINTAINER:=ly4096x
PKG_LICENSE:=GPL-3
PKG_LICENSE_FILES:=COPYING

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# Determine Rust target based on OpenWrt architecture
ifeq ($(ARCH),x86_64)
  RUST_TARGET:=x86_64-unknown-linux-musl
else ifeq ($(ARCH),aarch64)
  RUST_TARGET:=aarch64-unknown-linux-musl
else ifeq ($(ARCH),arm)
  RUST_TARGET:=arm-unknown-linux-musleabi
else ifeq ($(ARCH),armv7)
  RUST_TARGET:=armv7-unknown-linux-musleabihf
else ifeq ($(ARCH),mips)
  RUST_TARGET:=mips-unknown-linux-musl
else ifeq ($(ARCH),mipsel)
  RUST_TARGET:=mipsel-unknown-linux-musl
else
  RUST_TARGET:=$(ARCH)-unknown-linux-musl
endif

# CMake configuration for Rust-based Fish 4.x
CMAKE_OPTIONS += \
	-DWITH_DOCS=OFF \
	-DRust_CARGO_TARGET=$(RUST_TARGET)

# Cargo environment for cross-compilation
TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include
TARGET_LDFLAGS += -L$(STAGING_DIR)/usr/lib

# Ensure msgfmt is available in PATH during build (for fish-gettext-maps)
export PATH:=$(STAGING_DIR_HOST)/bin:$(PATH)

define Build/Configure
	mkdir -p $(PKG_BUILD_DIR)/.cargo
	echo '[target.$(RUST_TARGET)]' > $(PKG_BUILD_DIR)/.cargo/config.toml
	echo 'linker = "$(TARGET_CC)"' >> $(PKG_BUILD_DIR)/.cargo/config.toml
	echo 'ar = "$(TARGET_AR)"' >> $(PKG_BUILD_DIR)/.cargo/config.toml
	echo 'rustflags = ["-C", "link-arg=-L$(STAGING_DIR)/usr/lib"]' >> $(PKG_BUILD_DIR)/.cargo/config.toml
	$(call Build/Configure/Default)
endef

define Package/fish
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Fish shell
  URL:=https://fishshell.com/
  DEPENDS:=
endef

define Package/fish/description
  Fish is a smart and user-friendly command line shell.
endef

define Package/fish/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/fish $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/share/fish
	$(CP) $(PKG_INSTALL_DIR)/usr/share/fish/* $(1)/usr/share/fish/
	$(INSTALL_DIR) $(1)/etc/profile.d
	$(INSTALL_DATA) ./files/fish.sh $(1)/etc/profile.d/
endef

$(eval $(call BuildPackage,fish))
