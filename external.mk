# custom packages
include $(sort $(wildcard $(BR2_EXTERNAL_PIBOOTHOS_PATH)/package/*/*.mk))

# override options
RAUC_CONF_OPTS += --disable-service
undefine DNSMASQ_INSTALL_INIT_SYSV
undefine BLUEZ5_UTILS_INSTALL_INIT_SYSV

# enable libsigrok python bindings if needed
ifeq ($(BR2_KAAS_SIGROK),y)
LIBSIGROK_DEPENDENCIES += python3 host-swig python-gobject host-python-numpy
LIBSIGROK_CONF_OPTS += --enable-python
endif

ifeq ($(BR2_SECURE_SSH),y)
export SECURE_SSH_PUBKEY_PATH ?= $(call qstrip,$(BR2_SECURE_SSH_PUBKEY_PATH))
endif

ifeq ($(BR2_WIFI_SETTINGS),y)
export WIFI_SETTINGS_SSID ?= $(call qstrip,$(BR2_WIFI_SETTINGS_SSID))
export WIFI_SETTINGS_PASSWORD ?= $(call qstrip,$(BR2_WIFI_SETTINGS_PASSWORD))
endif

ifneq ($(BR2_WPA_SUPPLICANT_CONF_PATH),)
export WPA_SUPPLICANT_CONF_PATH ?= $(call qstrip,$(BR2_WPA_SUPPLICANT_CONF_PATH))
endif

