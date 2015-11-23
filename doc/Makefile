report.pdf: *.md
	pandoc -r markdown $(shell cat report_orga) -t latex -o out.pdf --toc-depth=4 -s --highlight-style=tango --number-sections
	mv out.pdf report.pdf
clean: report.pdf
	rm report.pdf
monitor:
	when-changed *.md **/*.md -c make
