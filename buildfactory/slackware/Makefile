dist-slack: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _slack_
	$(H)mkdir -p dist-slack
	$(H)[ -d _slack_/freepops-$(VERSION) ] || \
		$(TAR) -xzf freepops-$(VERSION).tar.gz -C _slack_
	$(H)cd _slack_/freepops-$(VERSION); \
		./configure.sh linux-slack; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR="../../dist-slack/"
	$(H)cd dist-slack; \
		strip usr/bin/freepopsd; \
		mkdir -p install; \
		cp ../slackware/slack-desc install; \
		cp ../slackware/slack-required install; \
		mkdir -p etc/rc.d; \
		cp ../slackware/freepops.conf etc/freepops; \
		cp ../slackware/rc.freepops etc/rc.d; \
		mv usr/share/man usr/man; \
		mv usr/share/doc usr/doc; \
		gzip usr/man/man1/freepopsd.1; \
		rm usr/doc/freepops/MANUAL.txt; \
		mv usr/doc/freepops usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/AUTHORS \
			usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/COPYING \
			usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/ChangeLog \
			usr/doc/freepops-$(VERSION); \
		cp ../_slack_/freepops-$(VERSION)/README \
			usr/doc/freepops-$(VERSION); \
		chown -R root.root .; \
		chmod 755 .; \
		chown root.bin usr/bin ; \
		chmod 755 etc/rc.d/rc.freepops; \
		chmod 644 usr/share/freepops/lua/*; \
		rm -rf usr/share/freepops/lua_unofficial; \
		makepkg --chown n freepops-$(VERSION)-i386-1.tgz; \
		rm -rf etc; \
		rm -rf install; \
		rm -rf usr
	$(H)rm -rf _slack_
	

