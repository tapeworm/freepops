LATEX_HTML= \
	    -split +1\
	    -show_section_numbers\
	    -html_version 3.2\
	    -scalable_fonts\
	    -local_icons\
	    -antialias\
	    -antialias_text\
	    -top_navigation\
	    -bottom_navigation\
	    -next_page_in_navigation\
	    -previous_page_in_navigation

all: pdf html
	
pdf: manual.pdf manual-it.pdf
	@cp manual.pdf manual-it.pdf ../ || true

html: macro.tex manual.tex manual-it.tex
	@echo Generating the HTML manuals
	@rm -rf html-manual/;mkdir html-manual/
	@latex2html -t "FreePOPs Manual"\
		-dir html-manual $(LATEX_HTML) manual.tex \
		2>log.log >log.log || true
	@rm -rf html-manual-it/;mkdir html-manual-it/
	@latex2html -t "Manuale di FreePOPs"\
		-dir html-manual-it $(LATEX_HTML) manual-it.tex \
		2>log.log >log.log || true

spell:
	@aspell -t -c manual.tex

spell-it:
	@aspell -t --lang=it -c manual-it.tex

%.pdf:%.ps
	@ps2pdf $< $@

%.ps:%.dvi
	@dvips -f $< > $@

%.dvi:%.tex macro.tex xml
	@echo Generating the PDF manuals
	@latex $<
	@latex $<
	@latex $<

xml:
	@DIR=`date +%s`;\
		mkdir -p /tmp/$$DIR;\
		cd ../../;\
		[ -e src/freepopsd ] || make all;\
		for X in src/lua/*.lua; do \
			src/freepopsd -x $$X 1> \
				/tmp/$$DIR/`basename $$X`.xml 2>/dev/null;\
		done;\
		for X in /tmp/$$DIR/*.xml; do \
			echo "Generating tex data for " `basename $$X`;\
			src/freepopsd -e \
				xml2tex.lua $$X it 1> \
				doc/manual/`basename $$X`.it.xmltex;\
			src/freepopsd -e \
				xml2tex.lua $$X en 1> \
				doc/manual/`basename $$X`.en.xmltex;\
			src/freepopsd -e \
				xml2tex.lua $$X it brief 1> \
				doc/manual/`basename $$X`.b.it.xmltex;\
			src/freepopsd -e \
				xml2tex.lua $$X en brief 1> \
				doc/manual/`basename $$X`.b.en.xmltex;\
		done;\
		rm -rf /tmp/$$DIR

clean:
	@rm -rf *.aux *.pdf *.dvi *.ps *.ps.gz *.log\
		*.toc *.lof *.lot *.bbl *.blg *.xmltex\
		html-manual html-manual-it manual.txt manual-it.txt

.PHONY: html pdf xml
