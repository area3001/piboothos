BUILDDIR := $(shell pwd)
RELEASE_DIR = $(BUILDDIR)/release

BUILDROOT = $(BUILDDIR)/buildroot
BUILDROOT_EXTERNAL = $(BUILDDIR)
DEFCONFIG_DIR = $(BUILDROOT_EXTERNAL)/configs

BR2_JLEVEL := 13
BR2_DL_DIR := $(HOME)/br-dl
BUILD_OPTIONS = BR2_EXTERNAL=$(BUILDROOT_EXTERNAL) BR2_DL_DIR=$(BR2_DL_DIR) BR2_JLEVEL=$(BR2_JLEVEL)

TARGETS := $(notdir $(patsubst %_defconfig,%,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))
TARGETS_CONFIG := $(notdir $(patsubst %_defconfig,%-config,$(wildcard $(DEFCONFIG_DIR)/*_defconfig)))

# Set O variable if not already done on the command line
ifneq ("$(origin O)", "command line")
O := $(BUILDROOT)/output
else
override O := $(BUILDROOT)/$(O)
endif

ifeq ("$(origin V)", "command line")
VERBOSE := $(V)
endif
ifneq ($(VERBOSE),1)
Q := @
else

endif

.NOTPARALLEL: $(TARGETS) $(TARGETS_CONFIG) all

.PHONY: $(TARGETS) $(TARGETS_CONFIG) all help

all: $(TARGETS)

$(TARGETS_CONFIG): %-config:
	$(Q)echo "config $*"
	$(MAKE) -C $(BUILDROOT) $(BUILD_OPTIONS) "$*_defconfig" O=$(O)/$*

$(TARGETS): %: %-config
	$(Q)echo "build $@"
	$(Q)mkdir -p $(O)/$@/log
	$(MAKE) -C $(BUILDROOT) $(BUILD_OPTIONS) O=$(O)/$@ 2>&1 | tee $(O)/$@/log/build.log
	$(Q)echo "finished $@"

help:
	$(Q)echo "Supported targets: $(TARGETS)"
	$(Q)echo "Run 'make <target>' to build a target image."
	$(Q)echo "Run 'make all' to build all target images."
	$(Q)echo "Run 'make <target>-config' to configure buildroot for a target."

# make show-info O=output/rpi4 | jq -r '. as $o | keys[] | select(startswith("python-") and not .virtual) | [$o[.].name, $o[.].version] | @sh'
# make show-info O=output/rpi4 | jq -r '. as $o | keys[] | select($o[.].virtual == false and $o[.].version != "") | [$o[.].name, $o[.].version] | @sh'