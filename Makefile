.PHONY: all test

VERSION = 5.6
URL = http://www.squid-cache.org/Versions/v$(firstword $(subst ., ,${VERSION}))/squid-${VERSION}.tar.xz

all: squid-${VERSION}.tar.xz
	bosh create-release --force

squid-${VERSION}.tar.xz:
	wget -O "$@" "${URL}"
	bosh add-blob "$@" squid/squid.tar.xz
