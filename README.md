# Intern Report Project

This repository contains the LaTeX source code for the intern report.

## Branches

This project utilizes two main branches:

1.  **`main`**: Contains the original chapter layout.
2.  **`HCMUS-FETEL-Intern-Chapter-Layout`**: Contains the chapter layout specific to the HCMUS FETEL Internship requirements.

## Compilation

To compile the LaTeX project and generate the PDF (`main.pdf`), run the following commands in sequence in your terminal from the project's root directory:

```bash
bibtex main
makeglossaries main
pdflatex main.tex
```

You might need to run `pdflatex main.tex` a second time for cross-references (like table of contents, figure numbers, citations) to be correctly updated.
