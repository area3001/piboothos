################################################################################
#
# python-pygame-vkeyboard
#
################################################################################

PYTHON_PYGAME_VKEYBOARD_VERSION = 2.0.9
PYTHON_PYGAME_VKEYBOARD_SITE = $(call github,Faylixe,pygame-vkeyboard,$(PYTHON_PYGAME_VKEYBOARD_VERSION))
PYTHON_PYGAME_VKEYBOARD_SETUP_TYPE = setuptools
PYTHON_PYGAME_VKEYBOARD_LICENSE = Apache License 2.0
PYTHON_PYGAME_VKEYBOARD_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
