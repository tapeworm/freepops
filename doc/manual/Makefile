all: manual.pdf manual-it.pdf
	cp manual.pdf manual-it.pdf ../

spell:
	aspell -t -c manual.tex

spell-it:
	aspell -t --lang=it -c manual-it.tex

%.pdf:%.ps
	ps2pdf $< $@

%.ps:%.dvi
	dvips $< -o $@

%.dvi:%.tex macro.tex
	latex $<
	latex $<

clean:
	rm -f *.aux *.pdf *.dvi *.ps *.ps.gz *.log *.toc *.lof *.lot *.bbl *.blg
