include subscribed

H=@

all:
	$(H)for X in $(MK_TEMPLATE); do \
		cd $$X ;\
		[ -e Makefile ] || ln -s ../Makefile.template Makefile;\
		cd ..;\
	done
	$(H)for X in $(MK_TEMPL_CTRIB); do \
		cd $$X ;\
		[ -e Makefile ] || ln -s ../Makefile.template-contrib Makefile;\
		cd ..;\
	done
	$(H)for X in $(MK_CUSTOM); do \
		cd $$X ;\
		if [ ! -e Makefile ] ; then \
			echo "Custom Makefile not found in '$$X'" ; \
			exit 1;\
		fi;\
		cd ..;\
	done



clean:
	$(H)for X in $(MK_TEMPLATE) $(MK_TEMPL_CTRIB) ; do \
		cd $$X ;\
		rm -f Makefile;\
		cd ..;\
	done

