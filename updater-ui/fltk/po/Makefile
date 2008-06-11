include $(CONFIG)
H=@

PO=$(shell ls "$(PWD)/po/"*".po" | sed -e "s/.*\///g" -e "s/\.po/\.gmo/g")

all: $(PO)
	$(H)echo -n
	
%.gmo: %.po
	$(H)echo -n " building $< -> "
	$(H)msgfmt $< -o $@
	$(H)echo "$@"

clean:
	$(H)echo cleaning language files for updater_fltk
	$(H)rm -f *.gmo
