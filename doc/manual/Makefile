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
	cp manual.pdf manual-it.pdf ../

html: macro.tex manual.tex manual-it.tex
	rm -rf html-manual/;mkdir html-manual/
	latex2html -t "FreePOPs Manual"\
		-dir html-manual $(LATEX_HTML) manual.tex \
		2>log.log >log.log
	rm -rf html-manual-it/;mkdir html-manual-it/
	latex2html -t "Manuale di FreePOPs"\
		-dir html-manual-it $(LATEX_HTML) manual-it.tex \
		2>log.log >log.log

spell:
	aspell -t -c manual.tex

spell-it:
	aspell -t --lang=it -c manual-it.tex

%.pdf:%.ps
	ps2pdf $< $@

%.ps:%.dvi
	dvips -f $< > $@

%.dvi:%.tex macro.tex
	latex $<
	latex $<

clean:
	rm -rf *.aux *.pdf *.dvi *.ps *.ps.gz *.log\
		*.toc *.lof *.lot *.bbl *.blg \
		html-manual html-manual-it manual.txt manual-it.txt

.PHONY: html pdf txt
