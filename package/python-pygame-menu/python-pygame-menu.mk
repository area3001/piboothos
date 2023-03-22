################################################################################
#
# python-pygame-menu
#
################################################################################

PYTHON_PYGAME_MENU_VERSION = 4.3.9
PYTHON_PYGAME_MENU_SOURCE = pygame-menu-$(PYTHON_PYGAME_MENU_VERSION).tar.gz
PYTHON_PYGAME_MENU_SITE = https://files.pythonhosted.org/packages/0b/90/d3355452019764967e3f01adc15d7f261f12239f2bd93925a13be48aa4f1
PYTHON_PYGAME_MENU_SETUP_TYPE = setuptools
PYTHON_PYGAME_MENU_LICENSE = MIT
PYTHON_PYGAME_MENU_LICENSE_FILES = LICENSE

$(eval $(python-package))
