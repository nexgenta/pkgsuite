DEVTOOLS ?= /Local/Developer
prefix ?= /usr/local

ARCHS = x86_64 i486 ppc
DEBARCHS = darwin-amd64 darwin-i386 darwin-powerpc

DPKG_VERSION = 1.14.30
DPKG_REVISION = 3
DPKG_BINARY = dpkg dpkg-deb dpkg-query dpkg-split dpkg-trigger dselect
DPKG_DEB = dpkg_$(DPKG_VERSION)-$(DPKG_REVISION)_darwin-universal.deb

dpkg_var=$(prefix)/var/dpkg

all: $(DPKG_DEB)

clean: dpkg-clean

define dpkg_control
Package: dpkg
Version: $(DPKG_VERSION)
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

dpkg/configure: dpkg/configure.ac
	cd dpkg && autoreconf --install --force -I m4

$(DPKG_DEB): dpkg-stage-universal$(prefix)/bin/dpkg
	echo "2.0" > debian-binary
	( cd dpkg-stage-universal && sudo tar cvf ../data.tar.gz . )
	rm -rf dpkg-control
	mkdir dpkg-control
	echo "$$dpkg_control" > dpkg-control/control
	echo "$$dpkg_conffiles" > dpkg-control/conffiles
	find dpkg-stage-universal -type f -exec md5 -r \{} \; | sed -e 's! dpkg-stage-universal/! !' > dpkg-control/md5sums
	( cd dpkg-control && tar cvf ../control.tar.gz . )
	$(DEVTOOLS)/usr/bin/ar rc $(DPKG_DEB) debian-binary control.tar.gz data.tar.gz

dpkg-stage-universal$(prefix)/bin/dpkg: dpkg-archs
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
	./stage-dpkg $(DEVTOOLS) x86_64 $(prefix)

dpkg-stage-i486$(prefix)/bin/dpkg: dpkg/configure
	./stage-dpkg $(DEVTOOLS) i486 $(prefix)

dpkg-stage-ppc$(prefix)/bin/dpkg: dpkg/configure
	./stage-dpkg $(DEVTOOLS) ppc $(prefix)

preinst:
	sudo mkdir -p $(dpkg_var) $(dpkg_var)/alternatives $(dpkg_var)/info $(dpkg_var)/methods $(dpkg_var)/parts $(dpkg_var)/triggers $(dpkg_var)/updates
	sudo touch $(dpkg_var)/available $(dpkg_var)/status

obliterate:
	sudo rm -rf $(dpkg_var)
