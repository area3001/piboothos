################################################################################
#
# python-pibooth
#
################################################################################

PYTHON_PIBOOTH_VERSION = 2.0.6
PYTHON_PIBOOTH_SITE = $(call github,pibooth,pibooth,$(PYTHON_PIBOOTH_VERSION))
PYTHON_PIBOOTH_SETUP_TYPE = setuptools
PYTHON_PIBOOTH_LICENSE = MIT
PYTHON_PIBOOTH_LICENSE_FILES = LICENSE

$(eval $(python-package))
