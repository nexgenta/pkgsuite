DEVTOOLS ?= /Local/Developer

devbin = $(DEVTOOLS)/usr/bin

all: darwin-9.0-nx1_all.deb

darwin-9.0-nx1_all.deb: darwin/control
	rm -f control.tar.gz debian-binary empty $@
	echo 2.0 > debian-binary
	cd darwin && tar zcvf ../control.tar.gz .
	mkdir empty && cd empty && tar zcvf ../data.tar.gz . 
	$(devbin)/ar rc $@ debian-binary control.tar.gz data.tar.gz
