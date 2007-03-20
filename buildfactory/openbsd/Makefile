dist-obsd:
	$(H)cd ..;./configure.sh obsd || true
	$(H)cd ..;$(MAKE) install
	$(H)cd openbsd;pkg_create -f CONTENTS -c COMMENT -d DESC \
	-D DISPLAY freepops-$(VERSION)
	$(H)gzip openbsd/freepops-$(VERSION)
	$(H)mv openbsd/freepops-$(VERSION).gz freepops-$(VERSION).tgz

