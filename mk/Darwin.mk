### Configurable

DEVTOOLS ?= /Local/Developer
prefix ?= /usr/local
ARCHS = x86_64 i486 ppc
DEBARCHS = darwin-amd64 darwin-i386 darwin-powerpc

### Native package version information

PKG_VERSION = 1.14.30
PKG_REVISION = nx12
PKG_NAME = dpkg+apt_$(PKG_VERSION)-$(PKG_REVISION)_darwin-universal.pkg

### dpkg version information

DPKG_VERSION = 1.14.30
DPKG_REVISION = nx4
DPKG_BINARY = dpkg dpkg-deb dpkg-query dpkg-split dpkg-trigger dselect
DPKG_DEB = dpkg_$(DPKG_VERSION)-$(DPKG_REVISION)_darwin-universal.deb

define dpkg_control
Package: dpkg
Version: $(DPKG_VERSION)-$(DPKG_REVISION)
Architecture: darwin-universal
Essential: yes
Maintainer: Mo McRoberts <mo.mcroberts@nexgenta.com>
Original-Maintainer: Dpkg Developers <debian-dpkg@lists.debian.org>
Suggests: apt
Provides: dselect
Section: admin
Priority: required
Origin: Nexgenta
Homepage: https://github.com/nexgenta/dpkg
Bugs: https://github.com/nexgenta/dpkg/issues
Description: Debian package management system
 This package provides the low-level infrastructure for handling the
 installation and removal of Debian software packages.
endef

export dpkg_control

define dpkg_conffiles
$(prefix)/etc/dpkg/dpkg.cfg
$(prefix)/etc/dpkg/origins/debian
$(prefix)/etc/alternatives/README
$(prefix)/etc/dpkg/origins/debian
endef

export dpkg_conffiles

### apt version information

APT_VERSION = 0.7.20.2
APT_REVISION = nx9
APT_BINARY = bin/apt-cache bin/apt-cdrom bin/apt-config bin/apt-extracttemplates bin/apt-get bin/apt-sortpkgs lib/apt/methods/cdrom lib/apt/methods/copy lib/apt/methods/file lib/apt/methods/ftp lib/apt/methods/gpgv lib/apt/methods/gzip lib/apt/methods/http lib/apt/methods/https lib/apt/methods/rred lib/apt/methods/rsh
APT_DEB = apt_$(APT_VERSION)-$(APT_REVISION)_darwin-universal.deb

define apt_control
Package: apt
Version: $(APT_VERSION)-$(APT_REVISION)
Architecture: darwin-universal
Essential: yes
Maintainer: Mo McRoberts <mo.mcroberts@nexgenta.com>
Original-Maintainer: APT Development Team <deity@lists.debian.org>
Depends: dpkg
Provides: dselect
Section: admin
Priority: important
Origin: Nexgenta
Homepage: https://github.com/nexgenta/apt
Bugs: https://github.com/nexgenta/apt/issues
Description: Advanced front-end for dpkg
 This is Debian's next generation front-end for the dpkg package manager.
 It provides the apt-get utility and APT dselect method that provides a
 simpler, safer way to install and upgrade packages.
 .
 APT features complete installation ordering, multiple source capability
 and several other unique features, see the Users Guide in apt-doc.
endef

export apt_control

## '

define apt_conffiles
$(prefix)/etc/apt/sources.list.d/pkgsuite.list
$(prefix)/etc/apt/sources.list.d/fink.list
endef

export apt_conffiles

### No user-serviceable parts beyond this point

dpkg_var=$(prefix)/var/dpkg
devbin=$(DEVTOOLS)/usr/bin

all: $(PKG_NAME)

clean: dpkg-clean apt-clean
	rm -f $(PKG_NAME)

######## DPKG

dpkg/configure: dpkg/configure.ac
	cd dpkg && PATH=$(devbin):$$PATH $(devbin)/autoreconf --install --force -I m4

dpkg-pkg: $(PKG_NAME)

$(PKG_NAME): $(DPKG_DEB) $(APT_DEB)
	sudo rm -rf dpkg-pkgroot
	mkdir dpkg-pkgroot
	cp $(DPKG_DEB) $(APT_DEB) dpkg-stage-universal$(prefix)/bin/* dpkg-pkgroot/
	sudo chown -R root:wheel dpkg-pkgroot
	rm -f dpkg-scripts/postupgrade
	cp dpkg-scripts/postinstall dpkg-scripts/postupgrade
	$(devbin)/packagemaker \
		--doc dpkg.pmdoc \
		--out $(PKG_NAME) \
		--target 10.5 \
		--verbose

dpkg-deb: $(DPKG_DEB)

$(DPKG_DEB): dpkg-stage-universal$(prefix)/bin/dpkg
	echo "2.0" > debian-binary
	sudo chown -R root:wheel dpkg-stage-universal
	( cd dpkg-stage-universal && sudo tar cvf ../data.tar.gz . )
	rm -rf dpkg-control
	mkdir dpkg-control
	echo "$$dpkg_control" > dpkg-control/control
	echo "$$dpkg_conffiles" > dpkg-control/conffiles
	find dpkg-stage-universal -type f -exec md5 -r \{} \; | sed -e 's! dpkg-stage-universal/! !' > dpkg-control/md5sums
	( cd dpkg-control && tar cvf ../control.tar.gz . )
	$(DEVTOOLS)/usr/bin/ar rc $(DPKG_DEB) debian-binary control.tar.gz data.tar.gz

dpkg-stage-universal$(prefix)/bin/dpkg: $(foreach arch,$(ARCHS),dpkg-stage-$(arch)$(prefix)/bin/dpkg)
	rm -rf dpkg-stage-universal
	mkdir dpkg-stage-universal
	( cd dpkg-stage-x86_64 && sudo tar cf - . ) | ( cd dpkg-stage-universal && tar xf - )
	cd dpkg-stage-universal$(prefix)/bin && sudo rm -f $(DPKG_BINARY)
	for i in $(DPKG_BINARY) ; do \
		sudo lipo $(foreach arch,$(ARCHS),dpkg-stage-$(arch)$(prefix)/bin/$$i) -create -output dpkg-stage-universal$(prefix)/bin/$$i ; \
	done

dpkg-clean:
	rm -rf $(foreach arch,$(ARCHS),dpkg-build-$(arch))
	sudo rm -rf $(foreach arch,$(ARCHS),dpkg-stage-$(arch)) dpkg-stage-universal dpkg-control
	rm -f control.tar.gz data.tar.gz debian-binary $(DPKG_DEB)

dpkg-archs: $(foreach arch,$(ARCHS),dpkg-stage-$(arch)$(prefix)/bin/dpkg)

dpkg-stage-x86_64$(prefix)/bin/dpkg: dpkg/configure
	./stage-dpkg-darwin $(DEVTOOLS) x86_64 $(prefix)

dpkg-stage-i486$(prefix)/bin/dpkg: dpkg/configure
	./stage-dpkg-darwin $(DEVTOOLS) i486 $(prefix)

dpkg-stage-ppc$(prefix)/bin/dpkg: dpkg/configure
	./stage-dpkg-darwin $(DEVTOOLS) ppc $(prefix)

######## APT

apt-deb: $(APT_DEB)

$(APT_DEB): apt-stage-universal$(prefix)/bin/apt-get
	echo "2.0" > debian-binary
	sudo chown -R root:wheel apt-stage-universal
	( cd apt-stage-universal && sudo tar cvf ../data.tar.gz . )
	rm -rf apt-control
	mkdir apt-control
	echo "$$apt_control" > apt-control/control
	echo "$$apt_conffiles" > apt-control/conffiles
	find apt-stage-universal -type f -exec md5 -r \{} \; | sed -e 's! apt-stage-universal/! !' > apt-control/md5sums
	( cd apt-control && tar cvf ../control.tar.gz . )
	$(DEVTOOLS)/usr/bin/ar rc $(APT_DEB) debian-binary control.tar.gz data.tar.gz

apt/configure: apt/configure.in
	cd apt && PATH=$(devbin):$$PATH $(devbin)/autoconf --force -I buildlib

apt-stage-universal$(prefix)/bin/apt-get: $(foreach arch,$(ARCHS),apt-stage-$(arch)$(prefix)/bin/apt-get)
	sudo rm -rf apt-stage-universal
	mkdir apt-stage-universal
	( cd apt-stage-x86_64 && sudo tar cf - . ) | ( cd apt-stage-universal && tar xf - )
	cd apt-stage-universal$(prefix)/bin && sudo rm -f $(APT_BINARY)
	for i in $(APT_BINARY) ; do \
		sudo lipo $(foreach arch,$(ARCHS),apt-stage-$(arch)$(prefix)/$$i) -create -output apt-stage-universal$(prefix)/$$i ; \
	done

apt-clean:
	rm -rf $(foreach arch,$(ARCHS),apt-build-$(arch))
	sudo rm -rf $(foreach arch,$(ARCHS),apt-stage-$(arch)) apt-stage-universal apt-control
	rm -f control.tar.gz data.tar.gz debian-binary $(APT_DEB)

apt-archs: $(foreach arch,$(ARCHS),apt-stage-$(arch)$(prefix)/bin/apt-get)

apt-stage-x86_64$(prefix)/bin/apt-get: apt/configure dpkg-stage-universal$(prefix)/bin/dpkg
	./stage-apt-darwin $(DEVTOOLS) x86_64 $(prefix)

apt-stage-i486$(prefix)/bin/apt-get: apt/configure dpkg-stage-universal$(prefix)/bin/dpkg
	./stage-apt-darwin $(DEVTOOLS) i486 $(prefix)

apt-stage-ppc$(prefix)/bin/apt-get: apt/configure dpkg-stage-universal$(prefix)/bin/dpkg
	./stage-apt-darwin $(DEVTOOLS) ppc $(prefix)

.PHONY: apt-deb apt-archs apt-clean dpkg-deb dpkg-archs dpkg-clean
