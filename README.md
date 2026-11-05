# 32-Bit RV32I RISC-V Processor — RTL Design and Verification

A 32-bit RISC-V processor implemented in Verilog/SystemVerilog with a five-stage pipeline (IF, ID, EX, MEM, WB), data forwarding, and hazard detection. This project focuses on front-end RTL design and functional verification.

> **Scope:** This implementation supports the instruction subset listed below. The reported simulation and coverage results apply to the implemented design and configured test scenarios; they do not establish exhaustive RV32I compliance or 100% RTL code coverage.

## Project Overview

The processor is organized as a five-stage pipeline. Pipeline registers separate the stages, while forwarding and hazard-detection logic help manage data dependencies between instructions.

## Features

- 32-bit RISC-V processor RTL
- Five-stage pipelined architecture: IF, ID, EX, MEM, WB
- Modular datapath and control logic
- Data forwarding unit
- Hazard detection unit
- Instruction and data memory interfaces
- SystemVerilog-based functional testbench
- Functional coverage collection and waveform debugging

## Repository Structure

The following is a high-level guide to the project organization; consult the repository for the exact current file names and directory contents.

    riscv-rv32i-rtl-verification/
├── README.md
├── rtl/
│   ├── alu.v
│   ├── alu_control.v
│   ├── control_unit.v
│   ├── data_memory.v
│   ├── ex_mem_reg.v
│   ├── forwarding_unit.v
│   ├── hazard_detection.v
│   ├── id_ex_reg.v
│   ├── if_id_reg.v
│   ├── immediate_generator.v
│   ├── instruction_memory.v
│   ├── mem_wb_reg.v
│   ├── program_counter.v
│   ├── register_file.v
│   └── riscv_core.v
├── tb/
│   ├── individual module testbenches
│   ├── tb_riscv_core.v
│   ├── tb_riscv_functional.v
│   └── tb_riscv_coverage.sv
├── scripts/
│   └── run_simulation.sh
└── .gitignore

## Processor Architecture

| Stage | Function |
|---|---|
| IF — Instruction Fetch | Fetches the instruction using the program counter |
| ID — Instruction Decode | Decodes the instruction, reads registers, and generates immediates |
| EX — Execute | Performs ALU operations, branch comparisons, and address calculations |
| MEM — Memory Access | Performs data-memory reads and writes |
| WB — Write Back | Writes the selected result to the register file |

## Implemented Instruction Subset

| Type | Instructions |
|---|---|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT |
| I-type | ADDI, ANDI, ORI, LW, JALR |
| S-type | SW |
| B-type | BEQ, BNE, BLT, BGE |
| U-type | LUI, AUIPC |
| J-type | JAL |

This list describes the implemented subset, not a claim of complete RV32I ISA support.

## Verification

The design is verified using SystemVerilog testbenches and Cadence Xcelium. SimVision is used for waveform inspection and debugging.

### Processor-level simulation results

| Metric | Result |
|---|---:|
| Test cases passed | 68 |
| Test cases failed | 0 |

### Functional coverage

| Coverage group | Coverage |
|---|---:|
| Instruction coverage | 79.69% |
| ALU coverage | 100% |
| Branch coverage | 55.56% |
| Hazard coverage | 77.50% |
| Instruction type × ALU coverage | 77.14% |
| Configured scenario bins | 15/15 (100%) |

**Coverage note:** These figures represent the reported functional coverage groups and configured scenario bins. They are not RTL statement, branch, toggle, or overall code-coverage percentages.

## FPGA Implementation and Timing

An implementation run was performed using AMD Xilinx Vivado 2023.2 for the PYNQ-Z2 / Zynq-7000 device (xc7z020clg400-1).

### Timing summary

| Metric | Result |
|---|---:|
| Target clock period | 10 ns (100 MHz) |
| Worst Negative Slack (WNS) | +0.308 ns |
| Total Negative Slack (TNS) | 0 ns |
| Worst Hold Slack (WHS) | +0.058 ns |
| Total Hold Slack (THS) | 0 ns |
| Worst Pulse Width Slack (WPWS) | +3.000 ns |
| Failing setup endpoints | 0 |
| Failing hold endpoints | 0 |

The reported timing results meet the specified 10 ns clock constraint for this implementation run. They do not represent the maximum achievable operating frequency or confirm operation on a physical FPGA board.

### Resource utilization

| Resource | Utilization |
|---|---:|
| LUTs | 610 (1.15%) |
| Registers | 706 (0.66%) |
| Slices | 273 (2.05%) |
| BRAM | 0 |
| DSP | 0 |
| Bonded I/O | 72/125 (57.60%) |

### Estimated power

| Metric | Estimate |
|---|---:|
| Total power | 0.214 W |
| Dynamic power | 0.108 W |
| Static power | 0.106 W |
| Junction temperature | 27.5 °C |

Power and temperature values are tool estimates, not measurements from a physical board.

## Tools and Technologies

- Verilog
- SystemVerilog
- Cadence Xcelium
- Cadence SimVision
- AMD Xilinx Vivado 2023.2

## Future Improvements

- Increase functional coverage, especially for branch and hazard scenarios.
- Add more assertions and constrained-random tests.
- Add an independent reference model for result checking.
- Expand the implemented RV32I instruction subset.
- Add program-level tests and cycle-count/performance benchmarks.
- Validate the design on a physical FPGA board.

## Skills Demonstrated

RTL design, pipelined processor microarchitecture, Verilog/SystemVerilog, datapath and control design, forwarding, hazard detection, functional verification, functional coverage, simulation, and waveform debugging.

## Author

**Mohan Meesala**  
M.Tech VLSI | RTL Design | Design Verification
