SUMMARY = "CLI for extracting streams from various websites to a video player of your choosing"
DESCRIPTION = "Streamlink is a command-line utility that pipes video streams from various services into a video player, such as VLC."
HOMEPAGE = "https://github.com/streamlink/streamlink"
SECTION = "devel/python"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ca97af75b78809a5c401f63ead0f59f2"

DEPENDS += "python3-versioningit-native"

RDEPENDS:${PN} = "python3-core \
	python3-ctypes \
	python3-isodate \
	python3-pycountry \
	python3-lxml \
	python3-misc \
	python3-pkgutil \
	python3-pycryptodome \
	python3-pysocks \
	python3-requests \
	python3-shell \
	python3-singledispatch \
	python3-websocket-client \
	python3-trio \
	python3-certifi \
	python3-urllib3 \
	python3-trio-websocket \
"

inherit setuptools3 python3-dir python3-compileall gitpkgv

do_configure:prepend() {
    # Removes the Python 3.15 classifier that doesn't exist on PyPI
    sed -i '/"Programming Language :: Python :: 3.15",/d' ${S}/pyproject.toml
}


PV = "8.2.1+git"
PKGV = "8.2.1+git${GITPKGV}"

SRCREV_plugins = "${AUTOREV}"
SRCREV_FORMAT = "streamlink"

SRC_URI = " \
	git://github.com/streamlink/streamlink;protocol=https;branch=master;name=streamlink \
	git://github.com/oe-mirrors/streamlink-plugins;protocol=https;branch=master;name=plugins;destsuffix=additional-plugins \
	"

S = "${WORKDIR}/git"

do_unpack:append() {
    bb.build.exec_func('do_prepare_plugins_dir', d)
}

do_compile:prepend() {
	sed -i '/Programming Language :: Python :: 3.15/d' ${S}/pyproject.toml
}

do_prepare_plugins_dir() {
	cp -f ${WORKDIR}/additional-plugins/*.py ${S}/src/streamlink/plugins
}

do_install:append() {
	rm -rf ${D}${bindir}
	rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink_cli
	rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}/*.egg-info
	rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}/streamlink/plugins/.removed
	rm -rf ${D}${PYTHON_SITEPACKAGES_DIR}/*dirty.dist-info
	rm -rf ${D}${datadir}
}

include python3-package-split.inc

PACKAGES = "${PN} ${PN}-src"

FILES:${PN} += " \
	${PYTHON_SITEPACKAGES_DIR}/streamlink/*.pyc \
	${PYTHON_SITEPACKAGES_DIR}/streamlink/*/*.pyc \
	${PYTHON_SITEPACKAGES_DIR}/streamlink/*/*/*.pyc \
	"

FILES:${PN}-src += " \
	${PYTHON_SITEPACKAGES_DIR}/streamlink/plugins/.removed \
	"
