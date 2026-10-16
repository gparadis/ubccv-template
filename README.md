# UBC academic CV — a data-driven template

A pipeline for maintaining an academic CV in the format prescribed by the
*Guide to Reappointment, Promotion and Tenure Procedures at UBC* (the SAC
Guide), Appendix 3: "Annotated CV for the Professoriate Stream".

**You edit structured data. The pipeline produces the PDF.**

Keeping a CV in Word means re-doing the same formatting every year, for every
entry, and hoping nothing quietly dropped out. Here the content lives in plain
text files under `data/`, and one command turns it into a correctly formatted
CV — including the separately paginated Publications Record — as
`build/ubccv.pdf`.

A fully populated, real-world instance of this template (one UBC faculty
member's actual CV, updated with it regularly) lives at
**[gparadis/ubccv-paradis](https://github.com/gparadis/ubccv-paradis)** —
useful to see what the data files look like in practice.

```
data/*.yaml  +  data/publications.bib
        |
        v
  src/render.py  ->  Jinja2  ->  LaTeX  ->  tectonic (or latexmk)
        |
        v
  build/ubccv.pdf
```

## Quickstart

```sh
# 1. Get a copy (or use the GitHub "Use this template" button)
git clone https://github.com/gparadis/ubccv-template.git my-cv
cd my-cv

# 2. Install the two kinds of requirements
pip install pyyaml jinja2 bibtexparser        # or: pipx / your venv of choice
#   plus tectonic (recommended: a single static binary, no TeX install needed)
#   see https://tectonic-typesetting.github.io, or install TeX Live w/ latexmk

# 3. Build the sample CV that ships with the template
make

# 4. Replace the sample ("Jane Q. Doe") with yourself, section by section
$EDITOR data/*.yaml data/publications.bib
git commit -am "My real CV"
```

`make` re-renders `build/ubccv.pdf`. There is nothing to install beyond the
above, and no proprietary software anywhere in the chain.

## Where things live

| Path | What it is |
| --- | --- |
| `data/profile.yaml` | Sections 1–7: identity, education, employment, leaves |
| `data/teaching.yaml` | Section 8: courses, supervision, continuing education |
| `data/research.yaml` | Section 9: statement, grants, contracts, conference participation |
| `data/service.yaml` | Sections 10–11: service to the university and the community |
| `data/awards.yaml` | Section 12: awards and distinctions |
| `data/other.yaml` | Section 13: other relevant information |
| `data/publications.bib` | The Publications Record, plus invited and other presentations |
| `src/templates/cv.tex.j2` | The UBC layout (a Jinja-flavoured LaTeX template) |
| `src/cvdata.py` | Loads the sources, formats references |
| `src/latexfmt.py` | Inline markup and author-list formatting |
| `tools/` | Helpers for importing an existing Word CV, plus a QA check |
| `Makefile` | `make`, `make tex`, `make check` |

## Editing conventions

**Text fields** accept a small amount of inline markup, which the renderer
turns into LaTeX:

| Markup | Result |
| --- | --- |
| `**text**` | bold |
| `*text*` | italic |
| `[label](url)` | hyperlink |
| `^{x}` | superscript |
| ` \ ` (inside a table cell) | line break |

Everything else is escaped, so `&`, `%`, `$` and `_` are safe to type literally.

**Publications and presentations** live in `data/publications.bib`. Beyond the
standard BibTeX fields, these are used:

| Field | Meaning |
| --- | --- |
| `ubccv` | Which CV subsection the entry belongs in (see below) |
| `hqp` | Co-authors who are your highly qualified personnel |
| `presenter` | The presenting author(s), for entries under Other Presentations |
| `venue`, `role`, `scope`, `date` | Presentation details (`scope` is local/national/international) |
| `authorrole` | e.g. `editor`, for edited books |
| `starred` | `yes` marks a publication of primary importance; adds the `*` the guide asks for, and the symbol key appears only when at least one entry is starred |

Emphasis is **not** stored. A name is rendered bold when it is yours (matched
by surname against `profile.yaml`) or appears in `hqp`; `hqp` names get a `^`
and `presenter` names get a `*`. This keeps the symbol key honest
automatically.

Valid `ubccv` values:

```
invited_presentation      other_presentation
refereed_journal          refereed_proceedings      refereed_other
nonrefereed_journal       nonrefereed_proceedings   nonrefereed_other
book_authored             book_edited               book_chapter
patent                    copyright                 artistic       other_work
work_submitted            work_in_progress
```

**Ordering** is taken from the file, not computed. The guide asks for reverse
chronological order, but ties and "in press" entries need judgement, so
entries appear in the order you write them. The numbering in the PDF counts
down, as in the guide's annotated format, so the newest item carries the
highest number.

**Empty sections are kept.** The guide requires every heading to appear even
when there is nothing under it; those render as *(none to report)*.

## Adding a publication

Append to `data/publications.bib`, at the top of its section:

```bibtex
@article{doe2026keyword,
  author     = {Doe, J. and Student, A.},
  title      = {A title, sentence case},
  year       = {2026},
  journal    = {Journal Name},
  volume     = {12},
  number     = {3},
  pages      = {101--119},
  doi        = {10.1000/example},
  hqp        = {Student, A.},
  ubccv      = {refereed_journal},
}
```

A DOI renders as a live link. So does `url`, for entries without a DOI.

## Migrating an existing Word CV

You do not need this pipeline's importers to work on your document — porting
by hand, section by section, is the reliable way (it is also a good audit of
your CV). To keep it safe, the repository ships a coverage checker:

```sh
cp /path/to/your-cv.docx cv.docx     # or: make check DOCX=/path/to/your-cv.docx
make check
```

`make check` converts your `.docx` to an intermediate JSON block dump, then
compares the multiset of every word, number and name in it against everything
held in `data/`. Whatever your document has more often than your data does is
reported as potential loss — dropped authors, dates and dollar amounts
included. Fix the data (or record an intentional exception in `EXPECTED` at
the top of `tools/qa_coverage.py`) until it reports OK, then delete the Word
file with confidence. Expect a first run with a long list: the checker also
sees the guide's own boilerplate headings, which the template regenerates;
those words are accounted for in `tools/qa_coverage.py`.

## Requirements

- `python3` with `pyyaml`, `jinja2` and `bibtexparser` (BibTeX parsing uses
  bibtexparser v2's `parse_file` API)
- `tectonic` (recommended; static binary, downloads only the LaTeX packages it
  needs on first build) **or** a TeX installation providing `latexmk`

No other dependencies. The pipeline was developed with Python 3.12.

## Customizing

The layout is a single LaTeX template: `src/templates/cv.tex.j2`. It is
ordinary LaTeX with `\VAR{...}` for values and `%%`-prefixed lines for Jinja
statements, so it can be adjusted like any LaTeX document (fonts, margins,
section formatting). For example, the header line on every page and the
`\cvsection` macro are defined at the top of that file. Inline-markup and
author-name handling live in `src/latexfmt.py`.

The official SAC Guide (the format this template implements) is maintained by
UBC HR: <https://hr.ubc.ca/working-ubc/faculty-resources/tenure-and-faculty-appointments>.
Check your faculty's local requirements too — practice varies.

## License

MIT — see [LICENSE](LICENSE). Template extracted from the author's own CV
pipeline; the sample data ("Jane Q. Doe") is fictional.
