dist-rpm: freepops-$(VERSION).tar.gz
	$(H)mkdir -p _rpm_/build
	$(H)mkdir -p _rpm_/tmp
	$(H)sed 's/\%FREEPOPSVERSION/$(VERSION)/' freepops.spec.in > \
		_rpm_/freepops.spec
	$(H)cp freepops-$(VERSION).tar.gz _rpm_
	$(H)rpmbuild --rcfile rpmrc -ba _rpm_/freepops.spec
	$(H)mkdir ../dist-rpm || true
	$(H)cp _rpm_/*.rpm ../dist-rpm
	$(H)rm -rf _rpm_

