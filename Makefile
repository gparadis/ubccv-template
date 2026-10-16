PYTHON ?= python3
DOCX   ?= cv.docx
BUILD  ?= build

.PHONY: all pdf tex check blocks clean

all: pdf

## Render data/ -> build/ubccv.pdf
pdf:
	$(PYTHON) src/render.py -o $(BUILD)/ubccv.pdf

## Render the intermediate LaTeX only (useful when debugging the template)
tex:
	$(PYTHON) src/render.py --tex-only

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
