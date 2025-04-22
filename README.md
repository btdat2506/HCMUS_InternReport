# HCMUS FETEL Internship Report: Custom DMA Controller on FPGA

This repository contains the LaTeX source code for the internship report titled "**Thiết kế và Tích hợp Bộ điều khiển DMA Tùy chỉnh trên FPGA trong Hệ thống SoC Nios V/m**" (Design and Integration of a Custom DMA Controller on FPGA in a Nios V/m SoC System).

**Author:** Bùi Thành Đạt (MSSV: 21207001)
**Supervisor:** TS. Huỳnh Hữu Thuận
**Institution:** Faculty of Electronics & Telecommunications, Ho Chi Minh City University of Science (HCMUS)
**Program:** Chương trình Chất lượng cao

## Project Overview

This project details the design, implementation, simulation, and testing of a custom Direct Memory Access (DMA) controller integrated into a System-on-Chip (SoC) based on the Intel Nios V/m soft-core processor on an FPGA platform. The primary goal was to create an efficient hardware component for data transfer between on-chip memory regions, offloading the CPU.

**Key Technologies & Concepts Covered:**
*   System-on-Chip (SoC) Design [cite: 47, 18]
*   Intel Nios V/m Soft-Core Processor (RV32IMAZicsr)
*   Custom Direct Memory Access (DMA) Controller Design 
*   Field-Programmable Gate Array (FPGA) Implementation (Intel Cyclone V) 
*   Avalon Memory-Mapped (Avalon-MM) Bus Interface 
*   Verilog HDL 
*   Quartus Prime & Platform Designer
*   Questa Advanced Simulator / ModelSim for Simulation
*   Ashling RiscFree™ IDE for Nios V Software Development & Debugging 
*   C Programming for Embedded Systems 

## Project Structure

*   `main.tex`: The main LaTeX file that orchestrates the document structure.
*   `chapter*.tex`: Individual chapter files (e.g., `chapter1.tex`, `chapter2.tex`).
*   `Appendix/`: Contains appendix materials.
*   `Title/`: Contains the title page definition (`title.tex`).
*   `References/references.bib`: Bibliography database file.
*   `Images/`: Directory for storing images used in the report.
*   `DMAC/`: Verilog source files for the custom DMA Controller.
*   `QuestaSim/`: Simlation Results from Questa/ModelSim.
*   `myacronyms.sty`: Custom package for acronyms.
*   Other supporting files (`.aux`, `.log`, etc.) generated during compilation.

## Branches

This project utilizes two main branches:

1.  **`Thesis-Format`** (currently here): Contains the Undergraduate Thesis chapter layout.
2.  **`FETEL-Intern-Format`**: Contains the chapter layout specific to the HCMUS FETEL Internship requirements.

## Compilation

To compile the LaTeX project and generate the PDF ([`main.pdf`](main.pdf)), ensure you have a LaTeX distribution (like TeX Live or MiKTeX) installed with `bibtex` and `makeglossaries` capabilities. Run the following commands in sequence in your terminal from the project's root directory:

```bash
bibtex main
makeglossaries main
pdflatex main.tex
```

You might need to run `pdflatex main.tex` a second time for cross-references (like table of contents, figure numbers, citations) to be correctly updated.
