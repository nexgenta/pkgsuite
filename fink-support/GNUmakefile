DEVTOOLS ?= /Local/Developer

devbin = $(DEVTOOLS)/usr/bin

DPKG_DARWIN = darwin-$(shell cat darwin/control | egrep '^Version:' | sed -e's/^Version: //')_all.deb

all: $(DPKG_DARWIN)

clean:
	rm -f *.deb
	rm -rf control.tar.gz debian-binary empty

$(DPKG_DARWIN): darwin/control
	rm -rf control.tar.gz debian-binary empty $@
	echo 2.0 > debian-binary
	cd darwin && tar zcvf ../control.tar.gz .
	mkdir empty && cd empty && tar zcvf ../data.tar.gz . 
	$(devbin)/ar rc $@ debian-binary control.tar.gz data.tar.gz
