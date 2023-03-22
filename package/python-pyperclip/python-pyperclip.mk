################################################################################
#
# python-pyperclip
#
################################################################################

PYTHON_PYPERCLIP_VERSION = 1.8.2
PYTHON_PYPERCLIP_SOURCE = pyperclip-$(PYTHON_PYPERCLIP_VERSION).tar.gz
PYTHON_PYPERCLIP_SITE = https://files.pythonhosted.org/packages/a7/2c/4c64579f847bd5d539803c8b909e54ba087a79d01bb3aba433a95879a6c5
PYTHON_PYPERCLIP_SETUP_TYPE = setuptools
PYTHON_PYPERCLIP_LICENSE = FIXME: please specify the exact BSD version
PYTHON_PYPERCLIP_LICENSE_FILES = LICENSE.txt

$(eval $(python-package))
