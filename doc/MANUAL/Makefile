all: manual.pdf manual-it.pdf
	cp manual.pdf manual-it.pdf ../

%.pdf:%.ps
	ps2pdf $< $@

%.ps:%.dvi
	dvips $< -o $@

%.dvi:%.tex macro.tex
	latex $<

clean:
	rm -f *.aux *.pdf *.dvi *.ps *.ps.gz *.log *.toc *.lof *.lot *.bbl *.blg
