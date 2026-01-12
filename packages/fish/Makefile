include $(TOPDIR)/rules.mk

PKG_NAME:=fish
PKG_VERSION:=4.3.3
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=https://github.com/fish-shell/fish-shell/releases/download/$(PKG_VERSION)
PKG_HASH:=eba0e7d325c1d46046bb9d29434e7e0dabf7f584eb156845005d688e10b86e57

PKG_MAINTAINER:=ly4096x
PKG_LICENSE:=GPL-3
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:fishshell:fish

PKG_BUILD_DEPENDS:=rust/host pcre2
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# Disable static linking for pcre2-sys
export PCRE2_SYS_STATIC=0

# For pcre2-sys
export CC=$(TARGET_CC)
export RUSTFLAGS+=-C target-feature=-crt-static
export CARGO_TARGET_$(shell echo $(RUSTC_TARGET_ARCH) | sed -e 'y/abcdefghijklmnopqrstuvwxyz-/ABCDEFGHIJKLMNOPQRSTUVWXYZ_/')_LINKER:=$(TARGET_CC)

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
	-DWITH_GETTEXT=OFF \
	-DRust_CARGO_TARGET=$(RUST_TARGET) \
	-DFISH_USE_SYSTEM_PCRE2=ON

# Cargo environment for cross-compilation
TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include
TARGET_LDFLAGS += -L$(STAGING_DIR)/usr/lib

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
  SUBMENU:=Shells
  TITLE:=A smart and user-friendly command line shell
  DEPENDS:=$(RUST_ARCH_DEPENDS) +libpcre2 +libpcre2-32
  URL:=https://fishshell.com
endef

define Package/fish/description
  Fish is a smart and user-friendly command line shell for OS X, Linux, and the
  rest of the family. Fish includes features like syntax highlighting,
  autosuggest-as-you-type, and fancy tab completions that just work, with no
  configuration required.
endef

define Package/fish/conffiles
/usr/etc/fish/config.fish
endef

define Package/fish/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/fish $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/fish_indent $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/fish_key_reader $(1)/usr/bin

	$(INSTALL_DIR) $(1)/usr/share/fish
	$(CP) $(PKG_INSTALL_DIR)/usr/share/fish/* $(1)/usr/share/fish/
	rm -rf $(1)/usr/share/fish/man
endef

define Package/fish/postinst
#!/bin/sh
grep fish $${IPKG_INSTROOT}/etc/shells || \
    echo "/usr/bin/fish" >> $${IPKG_INSTROOT}/etc/shells

# Backwards compatibility
if [ -e /bin/fish ] && { [ ! -L /bin/fish ] || [ "$(readlink -fn $${IPKG_INSTROOT}/bin/fish)" != "../$(CONFIGURE_PREFIX)/bin/fish" ]; }; then
    ln -fs "../$(CONFIGURE_PREFIX)/bin/fish" "$${IPKG_INSTROOT}/bin/fish"
fi
endef

define Package/fish/postrm
	rm -rf "$${IPKG_INSTROOT}/$(CONFIGURE_PREFIX)/share/fish/$(PKG_VERSION)"
endef

$(eval $(call BuildPackage,fish))