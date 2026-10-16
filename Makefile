PYTHON ?= python3
DOCX   ?= cv.docx
BUILD  ?= build

SOURCES = $(wildcard data/*) $(wildcard src/*.py) src/templates/cv.tex.j2

.PHONY: all pdf tex publish check blocks clean

all: pdf

## Render data/ -> build/ubccv.pdf
pdf:
	$(PYTHON) src/render.py -o $(BUILD)/ubccv.pdf

## Render the intermediate LaTeX only (useful when debugging the template)
tex:
	$(PYTHON) src/render.py --tex-only

## Refresh the two committed renderings of the CV: cv.pdf and cv.md
publish: cv.pdf cv.md

cv.pdf: $(SOURCES)
	$(PYTHON) src/render.py -o $(BUILD)/ubccv.pdf
	cp $(BUILD)/ubccv.pdf $@

cv.md: $(SOURCES)
	$(PYTHON) src/render_md.py -o $@

## Dump your original Word CV into build/cv_blocks.json (one-time, for `make check`).
## Put your old CV next to this Makefile as cv.docx, or pass DOCX=/path/to/file.docx
blocks: $(BUILD)/cv_blocks.json

$(BUILD)/cv_blocks.json: $(DOCX) tools/docx_dump.py
	@mkdir -p $(BUILD)
	$(PYTHON) tools/docx_dump.py $(DOCX) $@

## Verify that data/ accounts for everything in your original Word CV
## (see tools/qa_coverage.py for how to record intentional exceptions)
check: $(BUILD)/cv_blocks.json
	$(PYTHON) tools/qa_coverage.py

clean:
	rm -rf $(BUILD)
