# 32-Bit RV32I RISC-V Processor
### RTL Design and Functional Verification

A 32-bit RISC-V processor implemented in synthesizable Verilog-2001, featuring a five-stage pipelined microarchitecture, data forwarding, load-use hazard handling, and branch/jump control-flow resolution.

This project covers the front-end RTL design and verification flow: datapath and control design, pipeline integration, self-checking simulation, functional coverage, and waveform-based debugging.

> **Implementation scope:** This project implements a tested subset of the RV32I instruction set. The reported test and coverage results apply to the supplied RTL and configured test programs; they do not establish complete RV32I ISA compliance or 100% RTL code coverage.

---

## 1. Processor Architecture

The processor uses a conventional five-stage pipeline:

| Stage | Description |
|---|---|
| **IF — Instruction Fetch** | Reads the instruction using the program counter and calculates PC + 4. |
| **ID — Instruction Decode** | Decodes the opcode, reads source registers, generates the immediate, and produces control signals. |
| **EX — Execute** | Performs ALU operations, forwarding, branch comparisons, and branch/jump target calculations. |
| **MEM — Memory Access** | Performs data-memory reads and writes. |
| **WB — Write Back** | Selects the result and writes it back to the register file. |

Pipeline registers separate the stages. The forwarding unit handles data dependencies, while the hazard-detection unit inserts a one-cycle stall for a load-use dependency. Taken branches and jumps redirect the PC and flush wrong-path instructions.

### Key design features

- 32-bit datapath and 32-entry integer register file.
- Five-stage pipelined datapath (IF, ID, EX, MEM, WB).
- Separate instruction-memory and data-memory modules.
- Main control unit and ALU control unit.
- Immediate generation for I, S, B, U, and J formats.
- EX/MEM and MEM/WB forwarding paths.
- Load-use hazard detection and pipeline stall.
- Branch and jump resolution in the EX stage.
- Pipeline flush on taken branch, JAL, and JALR.
- Register x0 remains hardwired to zero.

---

## 2. Implemented Instruction Subset

The RTL decodes the following instruction operations:

| Instruction format | Implemented operations |
|---|---|
| **R-type** | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU |
| **I-type arithmetic** | ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU |
| **Load** | LW |
| **Store** | SW |
| **Conditional branches** | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| **Upper immediate** | LUI, AUIPC |
| **Jumps** | JAL, JALR |

This is an implemented instruction subset, not a claim that every RV32I instruction, exception, or privileged architectural feature is supported.

---

## 3. Repository Structure

The repository is organized into separate RTL blocks and verification testbenches.

```text
riscv-rv32i-rtl-verification/
│
├── rtl/
│   ├── core/
│   │   ├── alu.v
│   │   ├── alu_control.v
│   │   ├── control_unit.v
│   │   ├── data_memory.v
│   │   ├── immediate_generator.v
│   │   ├── instruction_memory.v
│   │   ├── program_counter.v
│   │   ├── register_file.v
│   │   └── riscv_core.v
│   │
│   ├── hazard/
│   │   ├── forwarding_unit.v
│   │   └── hazard_detection.v
│   │
│   └── pipeline/
│       ├── ex_mem.v
│       ├── id_ex.v
│       ├── if_id.v
│       └── mem_wb.v
│
├── tb/
│   ├── self_tb/
│   │   ├── tb_alu.v
│   │   ├── tb_alu_control.v
│   │   ├── tb_control_unit.v
│   │   ├── tb_data_memory.v
│   │   ├── tb_immediate_generator.v
│   │   ├── tb_instruction_memory.v
│   │   ├── tb_program_counter.v
│   │   └── tb_register_file.v
│   │
│   ├── tb_riscv_core.v
│   ├── tb_riscv_functional.v
│   └── tb_riscv_coverage.sv
│
├── LICENSE
└── README.md
```

### RTL directory

- **core/** — datapath, arithmetic, decode, memory, register-file, immediate-generation, and top-level core modules.
- **hazard/** — forwarding selection and load-use hazard detection.
- **pipeline/** — IF/ID, ID/EX, EX/MEM, and MEM/WB pipeline registers.

### Testbench directory

- **self_tb/** — standalone testbenches for individual RTL modules.
- **tb_riscv_core.v** — processor integration testbench with sequential self-checking phases.
- **tb_riscv_functional.v** — processor-level functional testbench covering instruction behavior, memory operations, control flow, and pipeline hazards.
- **tb_riscv_coverage.sv** — SystemVerilog functional coverage testbench.

---

## 4. Verification Strategy

Verification is performed at two levels.

### 4.1 Module-level verification

Standalone testbenches are provided for:

- ALU
- ALU control
- Main control unit
- Data memory
- Immediate generator
- Instruction memory
- Program counter
- Register file

These testbenches allow individual blocks to be exercised before or independently of full processor integration.

### 4.2 Processor-level verification

The top-level testbenches exercise the integrated `riscv_core` using instruction sequences loaded into instruction memory by the testbench.

The integration scenarios include:

1. Pipeline register and datapath operation.
2. EX/MEM and MEM/WB data forwarding.
3. Load-use hazard detection and one-cycle stall.
4. Store and load operations.
5. Taken and not-taken conditional branches.
6. Signed and unsigned branch comparisons.
7. JAL and JALR target redirection and link-register values.
8. Pipeline flush and wrong-path instruction suppression.
9. R-type and I-type ALU operations.
10. LUI and AUIPC operations.
11. Register x0 behavior and additional corner cases.

### Reported simulation results

| Testbench | Reported result |
|---|---:|
| Processor integration testbench (`tb_riscv_core.v`) | 50/50 checks passed |
| Processor functional testbench (`tb_riscv_functional.v`) | 68/68 checks passed |

The results above are the reported results for the configured test programs. They should not be interpreted as proof of exhaustive ISA compliance.

---

## 5. Functional Coverage

The SystemVerilog coverage testbench collects coverage for the following groups:

| Coverage group | What it measures |
|---|---|
| Instruction coverage | Opcode, funct3, and funct7 bins |
| ALU coverage | ALU operation selection |
| Branch coverage | Branch type and taken/not-taken outcomes |
| Hazard coverage | Forwarding selections, stalls, and flushes |
| Instruction type × ALU | Cross coverage between instruction type and ALU operation |

### Reported functional coverage results

| Coverage group | Result |
|---|---:|
| Instruction coverage | 79.69% |
| ALU coverage | 100% |
| Branch coverage | 55.56% |
| Hazard coverage | 77.50% |
| Instruction type × ALU coverage | 77.14% |
| Configured RTL scenario bins | 15/15 (100%) |

**Coverage interpretation:** These are functional coverage results from the defined covergroups and scenario bins. They are not statement, branch, toggle, or overall RTL code-coverage percentages. Coverage is limited by the bins and stimulus configured in the testbench.

---

## 6. Simulation and Waveform Debugging

The RTL and testbenches are written in Verilog/SystemVerilog and have been used with Cadence Xcelium. SimVision is used to inspect simulation waveforms and debug signal behavior.

Run commands from the repository root. The following are example Xcelium invocations; use the options supported by your installed Xcelium version.

### Processor integration test

```sh
xrun -access +rwc rtl/core/*.v rtl/hazard/*.v rtl/pipeline/*.v tb/tb_riscv_core.v -top tb_riscv_core
```

### Processor functional test

```sh
xrun -access +rwc rtl/core/*.v rtl/hazard/*.v rtl/pipeline/*.v tb/tb_riscv_functional.v -top tb_riscv_functional
```

### Functional coverage test

```sh
xrun -sv -access +rwc rtl/core/*.v rtl/hazard/*.v rtl/pipeline/*.v tb/tb_riscv_coverage.sv -top tb_riscv_coverage
```

### Individual module testbenches

Compile the RTL module under test together with its corresponding testbench from `tb/self_tb/`. For example:

```sh
xrun -access +rwc rtl/core/alu.v tb/self_tb/tb_alu.v -top tb_alu
```

Use SimVision to inspect the PC, pipeline registers, forwarding controls, stall/flush signals, ALU outputs, memory interface, and write-back signals.

---

## 7. FPGA Synthesis and Timing Analysis

The design was also evaluated using AMD Xilinx Vivado 2023.2 for the PYNQ-Z2 / Zynq-7000 device (`xc7z020clg400-1`).

### Timing summary

| Metric | Reported result |
|---|---:|
| Clock constraint | 10 ns (100 MHz) |
| Worst Negative Slack (WNS) | +0.308 ns |
| Total Negative Slack (TNS) | 0 ns |
| Worst Hold Slack (WHS) | +0.058 ns |
| Total Hold Slack (THS) | 0 ns |
| Worst Pulse Width Slack (WPWS) | +3.000 ns |
| Failing setup endpoints | 0 |
| Failing hold endpoints | 0 |

### Resource utilization

| Resource | Reported utilization |
|---|---:|
| LUTs | 610 (1.15%) |
| Registers | 706 (0.66%) |
| Slices | 273 (2.05%) |
| BRAM | 0 |
| DSP | 0 |
| Bonded I/O | 72/125 (57.60%) |

### Estimated power

| Metric | Tool estimate |
|---|---:|
| Total power | 0.214 W |
| Dynamic power | 0.108 W |
| Static power | 0.106 W |
| Junction temperature | 27.5 °C |

These are implementation-tool results and estimates. They are not measured board power or temperature, and they do not establish successful operation on a physical FPGA board. The timing figures apply to the reported implementation run and its constraints.

---

## 8. Tools and Technologies

- **HDL:** Verilog-2001, SystemVerilog
- **RTL simulation:** Cadence Xcelium
- **Waveform debugging:** Cadence SimVision
- **Synthesis and implementation analysis:** AMD Xilinx Vivado 2023.2
- **Target device used for implementation analysis:** PYNQ-Z2 / Zynq-7000 (`xc7z020clg400-1`)

---

## 9. Future Improvements

- Expand the implemented instruction subset and add broader ISA-level tests.
- Improve branch and hazard functional coverage.
- Add SystemVerilog assertions for pipeline, control, and protocol behavior.
- Add constrained-random instruction generation and an independent reference model.
- Add automated regression scripts and reproducible coverage reporting.
- Perform physical FPGA board validation.

---

## 10. Skills Demonstrated

RTL design, five-stage pipelined processor architecture, Verilog, SystemVerilog, datapath and control logic, ALU design, forwarding, hazard detection, pipeline control, self-checking testbenches, functional coverage, simulation, waveform debugging, and timing analysis.

---

## Author

**Mohan Meesala**  
M.Tech VLSI | RTL Design | Design Verification

