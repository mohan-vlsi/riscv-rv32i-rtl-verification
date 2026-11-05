# 32-Bit RV32I RISC-V Processor — RTL Design and Verification

A 32-bit RISC-V processor implemented in Verilog/SystemVerilog with a five-stage pipeline (IF, ID, EX, MEM, WB), data forwarding, and hazard detection. This project focuses on front-end RTL design and functional verification.

> **Scope:** This implementation supports the instruction subset listed below. The reported simulation and coverage results apply to the implemented design and configured test scenarios; they do not establish exhaustive RV32I compliance or 100% RTL code coverage.

---

## Project Overview

RISC-V is an open-standard Instruction Set Architecture (ISA) used in embedded systems and SoC design. This project implements a modular, pipelined 32-bit processor capable of executing the supported arithmetic, load/store, and control-flow instructions listed in this README.

## Features

- 32-bit RISC-V processor implementing a selected RV32I instruction subset
- Five-stage pipeline: IF–ID–EX–MEM–WB
- Modular RTL design
- Register file, ALU, and ALU control
- Immediate generator and control unit
- Instruction and data memory
- Data forwarding unit
- Load-use hazard detection
- SystemVerilog-based functional testbench
- Functional coverage analysis
- Simulation and waveform debugging using Cadence Xcelium and SimVision

---

## Repository Structure

```text
riscv-rv32i-rtl-verification
│
├── rtl/
│   ├── core/
│   ├── pipeline/
│   └── hazard/
│
├── verification/
│   ├── tests/
│   ├── coverage/
│   └── testbench files
│
├── test_programs/
├── docs/
├── scripts/
└── README.md
```

*The directory tree is a high-level guide; check the repository for the current file and folder names.*

---

## Processor Architecture

The processor uses the following five stages:

| Stage | Function |
|---|---|
| IF — Instruction Fetch | Fetches the instruction using the program counter |
| ID — Instruction Decode | Decodes the instruction, reads register operands, and generates immediate values |
| EX — Execute | Performs ALU operations, comparisons, and address calculations |
| MEM — Memory Access | Performs data-memory reads and writes |
| WB — Write Back | Writes the selected result back to the register file |

Key RTL blocks include the program counter, instruction memory, register file, immediate generator, control unit, ALU, data memory, pipeline registers, forwarding unit, and hazard detection unit.

---

## Supported Instruction Types

- **R-Type:** ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT
- **I-Type:** ADDI, ANDI, ORI, LW, JALR
- **S-Type:** SW
- **B-Type:** BEQ, BNE, BLT, BGE
- **U-Type:** LUI, AUIPC
- **J-Type:** JAL

---

## Verification Environment

The processor was verified using SystemVerilog testbenches. Simulation and waveform debugging were performed using **Cadence Xcelium** and **SimVision**.

### Simulation Results

- Processor-level directed tests: **68 passed, 0 failed**

### Functional Coverage Results

| Coverage metric | Result |
|---|---:|
| Instruction coverage | 79.69% |
| ALU coverage | 100% |
| Branch coverage | 55.56% |
| Hazard coverage | 77.50% |
| Instruction type × ALU coverage | 77.14% |
| Configured scenario bins | 15/15 (100%) |

These figures represent functional coverage for the defined covergroups and bins. They are not RTL statement, branch, toggle, or overall code coverage.

---

## FPGA Implementation

An implementation run was performed using **AMD Xilinx Vivado 2023.2** targeting the **PYNQ-Z2 / Zynq-7000 (xc7z020clg400-1)** device.

### Timing Results

| Metric | Result |
|---|---:|
| Target clock period | 10 ns (100 MHz) |
| WNS | +0.308 ns |
| TNS | 0 ns |
| WHS | +0.058 ns |
| THS | 0 ns |
| WPWS | +3.000 ns |
| Failing setup endpoints | 0 |
| Failing hold endpoints | 0 |

The reported implementation meets the specified 100 MHz timing constraint. This does not establish the maximum achievable operating frequency or confirm operation on a physical FPGA board.

### Resource Utilization

| Resource | Result |
|---|---:|
| LUTs | 610 (1.15%) |
| Registers | 706 (0.66%) |
| Slices | 273 (2.05%) |
| BRAM | 0 |
| DSP | 0 |
| Bonded I/O | 72/125 (57.60%) |

### Power Estimate

Vivado reported an estimated total power of **0.214 W**, comprising **0.108 W dynamic** and **0.106 W static** power, with an estimated junction temperature of **27.5 °C**. These are tool estimates, not measurements from a physical FPGA board.

---

## Tools Used

- Verilog
- SystemVerilog
- Cadence Xcelium
- Cadence SimVision
- AMD Xilinx Vivado 2023.2

---

## Future Improvements

- Increase instruction, branch, forwarding, and hazard scenario coverage
- Add further assertions and constrained-random verification
- Develop an independent reference model
- Add program-level regression tests and cycle-count benchmarks
- Extend the implemented RV32I instruction coverage
- Perform physical FPGA board validation

---

## Skills Demonstrated

- Verilog and SystemVerilog
- RTL design and processor microarchitecture
- Pipelined processor design
- Hazard detection and data forwarding
- Functional verification and coverage analysis
- Cadence Xcelium and SimVision
- AMD Xilinx Vivado

---

## Author

**Mohan Meesala**

M.Tech VLSI | RTL Design | Design Verification
