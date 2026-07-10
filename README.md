# RISC-V (RV32I) Processor RTL Design and Verification

An industry-style implementation of a **32-bit RV32I RISC-V Processor** in Verilog/SystemVerilog featuring a **5-stage pipelined architecture**, hazard detection, forwarding, and a layered verification environment. The project demonstrates RTL design, processor microarchitecture, SystemVerilog Assertions (SVA), and functional verification using Synopsys VCS/Verdi.

---

## Project Overview

RISC-V is an open-standard Instruction Set Architecture (ISA) widely adopted in modern embedded systems and SoC design. This project implements a **32-bit RV32I processor** with a modular pipelined architecture capable of executing arithmetic, load/store, and branch instructions.

The processor is designed using synthesizable RTL and verified using a layered SystemVerilog verification environment.

---

## Features

- 32-bit RV32I Processor
- 5-Stage Pipeline (IF–ID–EX–MEM–WB)
- Modular RTL Design
- Hazard Detection Unit
- Data Forwarding Unit
- Register File
- ALU & ALU Control
- Immediate Generator
- Instruction & Data Memory
- Layered SystemVerilog Verification Environment
- SystemVerilog Assertions (SVA)
- Functional Coverage
- Waveform Debugging using Synopsys VCS/Verdi

---

## Repository Structure

```text
riscv-rv32i-rtl-verification
│
├── rtl/
│   ├── core/
│   │   ├── cpu_pkg.sv
│   │   ├── pc.sv
│   │   ├── instruction_memory.sv
│   │   ├── register_file.sv
│   │   ├── immediate_generator.sv
│   │   ├── control_unit.sv
│   │   ├── alu_control.sv
│   │   ├── alu.sv
│   │   ├── data_memory.sv
│   │   └── riscv_top.sv
│   │
│   ├── pipeline/
│   │   ├── if_id.sv
│   │   ├── id_ex.sv
│   │   ├── ex_mem.sv
│   │   └── mem_wb.sv
│   │
│   └── hazard/
│       ├── forwarding_unit.sv
│       └── hazard_detection_unit.sv
│
├── verification/
│   ├── interface/
│   ├── transaction/
│   ├── generator/
│   ├── driver/
│   ├── monitor/
│   ├── scoreboard/
│   ├── environment/
│   ├── assertions/
│   ├── coverage/
│   ├── tests/
│   └── top_tb.sv
│
├── test_programs/
│
├── docs/
│
├── scripts/
│
└── README.md
```

---

## Processor Architecture

The processor consists of the following RTL modules:

| Module | Description |
|---------|-------------|
| pc.sv | Program Counter |
| instruction_memory.sv | Instruction Memory |
| register_file.sv | 32 × 32-bit Register File |
| immediate_generator.sv | Immediate Value Generator |
| control_unit.sv | Main Control Unit |
| alu_control.sv | ALU Control Decoder |
| alu.sv | Arithmetic Logic Unit |
| data_memory.sv | Data Memory |
| if_id.sv | IF/ID Pipeline Register |
| id_ex.sv | ID/EX Pipeline Register |
| ex_mem.sv | EX/MEM Pipeline Register |
| mem_wb.sv | MEM/WB Pipeline Register |
| forwarding_unit.sv | Data Forwarding Logic |
| hazard_detection_unit.sv | Load-Use Hazard Detection |
| riscv_top.sv | Top-Level Processor |

---

## Pipeline Architecture

The processor implements a classic **5-stage pipeline**:

```text
Instruction Fetch (IF)
          │
          ▼
Instruction Decode (ID)
          │
          ▼
Execute (EX)
          │
          ▼
Memory Access (MEM)
          │
          ▼
Write Back (WB)
```

---

## Supported Instruction Types

- R-Type
  - ADD
  - SUB
  - AND
  - OR
  - XOR
  - SLL
  - SRL
  - SRA
  - SLT

- I-Type
  - ADDI
  - ANDI
  - ORI
  - LW
  - JALR

- S-Type
  - SW

- B-Type
  - BEQ
  - BNE
  - BLT
  - BGE

- U-Type
  - LUI
  - AUIPC

- J-Type
  - JAL

---

## Verification Environment

The processor is verified using a layered SystemVerilog verification environment.

```text
Generator
    │
Mailbox
    │
Driver
    │
CPU DUT
    │
Monitor
    │
Mailbox
    │
Scoreboard
```

Verification Components

- Interface
- Transaction
- Generator
- Driver
- Monitor
- Scoreboard
- Environment
- Testbench

---

## Assertions

Implemented SystemVerilog Assertions for:

- Program Counter Alignment
- Register x0 Constant Zero
- Hazard Detection Logic
- Pipeline Stall Behavior
- Forwarding Logic
- Memory Read/Write Control

---

## Functional Coverage

Coverage includes:

- Instruction Types
- ALU Operations
- Register Write Operations
- Load/Store Instructions
- Branch Instructions
- Hazard Scenarios
- Forwarding Conditions

---

## Simulation

Simulation flow:

1. Compile RTL
2. Compile Verification Environment
3. Run Simulation
4. Debug using Synopsys VCS/Verdi
5. Analyze Assertions
6. Check Functional Coverage

---

## Future Improvements

- Branch Prediction Unit
- Instruction Cache
- Data Cache
- CSR Instruction Support
- RV32M Extension
- UVM-based Verification Environment
- Coverage-Driven Verification
- CI/CD Integration using GitHub Actions

---

## Skills Demonstrated

- Verilog
- SystemVerilog
- RTL Design
- Processor Microarchitecture
- RISC-V (RV32I)
- Pipelined Processor Design
- Hazard Detection
- Data Forwarding
- SystemVerilog Assertions (SVA)
- Functional Coverage
- Design Verification
- Synopsys VCS/Verdi

---

## Author

**Mohan Meesala**

Electrical Engineering | VLSI | RTL Design | Design Verification
