include $(TOPDIR)/rules.mk

PKG_NAME:=slppsk-hostapd
PKG_VERSION:=0.1
PKG_RELEASE:=$(shell git rev-parse --short HEAD)
PKG_BUILD_DIR:=$(BUILD_DIR)/slppsk_hostapd

include $(INCLUDE_DIR)/package.mk

define Package/slppsk-hostapd
	TITLE:=Stateless Per-Station PSKs for hostapd
	SECTION:=net
	CATEGORY:=Network
	PKGARCH:=all
	DEPENDS:=+hostapd-utils +xxd +coreutils-base64
endef

define Package/slppsk-hostapd/description
	Generates a unique Pre Shared Key for each
	station based on its MAC address and a master
	password. No RADIUS server nor per-device
	configuration required.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/slppsk-hostapd/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/lib/hostapd_slppsk
	$(INSTALL_BIN) ./files/usr/bin/hostapd_slppsk $(1)/usr/bin
	$(INSTALL_BIN) \
		./files/usr/lib/hostapd_slppsk/{add_permanent_ppsk,add_temp_ppsk,event_handler,init_iface,init_psk}.sh \
		$(1)/usr/lib/hostapd_slppsk
	$(INSTALL_DATA) \
		./files/usr/lib/hostapd_slppsk/{key_common,iface_common,manage_common}.sh \
		$(1)/usr/lib/hostapd_slppsk
endef
 
$(eval $(call BuildPackage,slppsk-hostapd))
