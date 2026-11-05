//=============================================================
// Module      : riscv_core
// Project     : RV32I 5-Stage Pipelined Processor (Phase 3)
// Description : Full IF -> ID -> EX -> MEM -> WB pipeline,
//               built from the 8 verified Phase 1 blocks, the
//               4 pipeline registers, the forwarding unit, the
//               hazard detection unit, and (as of Increment 3)
//               branch/jump PC resolution with pipeline flush.
//
//               INCREMENT 3 SCOPE (adds to Increment 2):
//               - All 6 branch types (BEQ/BNE/BLT/BGE/BLTU/BGEU) and
//                 jump (JAL/JALR) are resolved in EX, using
//                 alu_control.v's funct3[2:1] comparison-select plus
//                 funct3[0] as a uniform result-invert bit, and
//                 PC+imm / rs1+imm target adders as in Phase 2's
//                 single-cycle datapath.
//               - On a taken branch or any jump, PC redirects to
//                 the target AND both IF/ID and ID/EX are flushed
//                 to bubbles on the same edge -- 2 wrong-path
//                 instructions (already fetched into IF and ID)
//                 are discarded. This is the standard 2-cycle
//                 branch/jump penalty for EX-stage resolution.
//               - flush and stall (Increment 2) can never be
//                 active simultaneously: both are derived from
//                 the SAME currently-latched ID/EX instruction,
//                 which cannot be both a load and a branch/jump
//                 at once (mutually exclusive opcodes).
// Standard    : Synthesizable Verilog-2001
//=============================================================
`timescale 1ns/1ps
module riscv_core (
    input  wire        clk,
    input  wire        rst_n,

    output wire [31:0] debug_pc,
    output wire [31:0] debug_wb_data,
    output wire [4:0]  debug_wb_rd,
    output wire        debug_wb_write
);
    //===========================================================
    // Forward declarations
    //===========================================================
    // hazard_detection_unit and forwarding_unit are instantiated
    // (below) before the pipeline registers that actually produce
    // their inputs (id_ex_reg, ex_mem_reg) appear later in this
    // file. Icarus Verilog tolerates this via elaboration-time
    // implicit-net resolution; Cadence Xcelium's xmvlog does NOT --
    // it requires strict declare-before-first-use ordering and
    // errors out (DUPIMP/DUPIDN) otherwise. These 5 signals are
    // declared here, once, and used (not re-declared) at their
    // natural point of production further down.
    wire        ex_mem_read;    // ID/EX output, used by hazard_detection
    wire [4:0]  ex_rd_addr;     // ID/EX output, used by hazard_detection
    wire [4:0]  mem_rd_addr;    // EX/MEM output, used by forwarding_unit
    wire        mem_reg_write;  // EX/MEM output, used by forwarding_unit
    wire [31:0] mem_alu_result; // EX/MEM output, used by the EX-stage
                                 // forwarding muxes

    //===========================================================
    // IF stage
    //===========================================================
    wire [31:0] if_pc_out;
    wire [31:0] if_pc_plus4;
    wire [31:0] if_instruction;
    wire [31:0] if_pc_next;

    program_counter #(
        .WIDTH      (32),
        .RESET_ADDR (32'h00000000)
    ) u_pc (
        .clk      (clk),
        .rst_n    (rst_n),
        .pc_next  (if_pc_next),
        .pc_out   (if_pc_out),
        .pc_plus4 (if_pc_plus4)
    );

    // stall (Increment 2, load-use) or flush (Increment 3, taken
    // branch/jump -- declared with the rest of the EX-stage signals
    // below) may override straight-line PC+4.
    wire stall;
    wire flush;
    wire [31:0] pc_redirect_target;
    assign if_pc_next = flush ? pc_redirect_target :
                         stall ? if_pc_out :
                                 if_pc_plus4;

    instruction_memory #(
        .WORD_ADDR_WIDTH (8)
    ) u_imem (
        .addr        (if_pc_out),
        .instruction (if_instruction)
    );

    //===========================================================
    // IF/ID pipeline register
    //===========================================================
    wire [31:0] id_pc;
    wire [31:0] id_pc_plus4;
    wire [31:0] id_instruction;

    if_id_reg u_if_id (
        .clk             (clk),
        .rst_n           (rst_n),
        // Priority: flush (Increment 3) forces a bubble (NOP) --
        // this cycle's IF fetch was wrong-path and must be
        // discarded. Else stall (Increment 2) replays IF/ID's own
        // current output. Else latch the newly fetched instruction
        // normally. (flush and stall can never both be 1 -- see
        // module header.)
        .pc_in           (flush ? if_pc_out : (stall ? id_pc          : if_pc_out)),
        .pc_plus4_in     (flush ? if_pc_plus4 : (stall ? id_pc_plus4    : if_pc_plus4)),
        .instruction_in  (flush ? 32'h00000013 : (stall ? id_instruction : if_instruction)),
        .pc_out          (id_pc),
        .pc_plus4_out    (id_pc_plus4),
        .instruction_out (id_instruction)
    );

    //===========================================================
    // ID stage
    //===========================================================
    wire [6:0] id_opcode = id_instruction[6:0];
    wire [4:0] id_rd     = id_instruction[11:7];
    wire [2:0] id_funct3 = id_instruction[14:12];
    wire [4:0] id_rs1    = id_instruction[19:15];
    wire [4:0] id_rs2    = id_instruction[24:20];
    wire [6:0] id_funct7 = id_instruction[31:25];

    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_imm_out;

    wire        id_reg_write;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_mem_to_reg;
    wire        id_alu_src;
    wire        id_branch;
    wire        id_jump;
    wire [1:0]  id_alu_op;

    // Write port driven by WB stage (see MEM/WB register below) --
    // reads (rs1/rs2) belong to the ID-stage instruction, the
    // write belongs to whatever instruction is currently in WB.
    wire [4:0]  wb_rd_addr;
    wire [31:0] wb_reg_write_data;
    wire        wb_reg_write;

    register_file #(
        .WIDTH     (32),
        .NUM_REGS  (32),
        .ADDR_BITS (5)
    ) u_rf (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_write (wb_reg_write),
        .rs1_addr  (id_rs1),
        .rs2_addr  (id_rs2),
        .rd_addr   (wb_rd_addr),
        .rd_data   (wb_reg_write_data),
        .rs1_data  (id_rs1_data),
        .rs2_data  (id_rs2_data)
    );

    immediate_generator u_immgen (
        .instruction (id_instruction),
        .imm_out     (id_imm_out)
    );

    control_unit u_ctrl (
        .opcode     (id_opcode),
        .reg_write  (id_reg_write),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .alu_src    (id_alu_src),
        .branch     (id_branch),
        .jump       (id_jump),
        .alu_op     (id_alu_op)
    );

    // Hazard detection: stalls the pipeline for exactly one cycle
    // when the instruction currently in EX is a load whose result
    // the instruction now in ID needs. Uses ID/EX's CURRENT
    // outputs (ex_mem_read, ex_rd_addr, declared below with the
    // rest of the ID/EX register outputs) together with this
    // cycle's ID-stage source registers.
    hazard_detection u_hazard (
        .ex_mem_read  (ex_mem_read),
        .ex_rd_addr   (ex_rd_addr),
        .id_rs1_addr  (id_rs1),
        .id_rs2_addr  (id_rs2),
        .stall        (stall)
    );

    //===========================================================
    // ID/EX pipeline register
    //===========================================================
    wire [31:0] ex_pc;
    wire [31:0] ex_pc_plus4;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm_out;
    wire [4:0]  ex_rs1_addr;
    wire [4:0]  ex_rs2_addr;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;
    wire [6:0]  ex_opcode;

    wire        ex_reg_write;
    wire        ex_mem_write;
    wire        ex_mem_to_reg;
    wire        ex_alu_src;
    wire        ex_branch;
    wire        ex_jump;
    wire [1:0]  ex_alu_op;

    id_ex_reg u_id_ex (
        .clk           (clk),
        .rst_n         (rst_n),

        .pc_in         (id_pc),
        .pc_plus4_in   (id_pc_plus4),
        .rs1_data_in   (id_rs1_data),
        .rs2_data_in   (id_rs2_data),
        .imm_out_in    (id_imm_out),
        .rs1_addr_in   (id_rs1),
        .rs2_addr_in   (id_rs2),
        .rd_addr_in    (id_rd),
        .funct3_in     (id_funct3),
        .funct7_in     (id_funct7),
        .opcode_in     (id_opcode),

        .reg_write_in  ((stall || flush) ? 1'b0 : id_reg_write),
        .mem_read_in   ((stall || flush) ? 1'b0 : id_mem_read),
        .mem_write_in  ((stall || flush) ? 1'b0 : id_mem_write),
        .mem_to_reg_in (id_mem_to_reg),
        .alu_src_in    (id_alu_src),
        .branch_in     ((stall || flush) ? 1'b0 : id_branch),
        .jump_in       ((stall || flush) ? 1'b0 : id_jump),
        .alu_op_in     (id_alu_op),

        .pc_out         (ex_pc),
        .pc_plus4_out   (ex_pc_plus4),
        .rs1_data_out   (ex_rs1_data),
        .rs2_data_out   (ex_rs2_data),
        .imm_out_out    (ex_imm_out),
        .rs1_addr_out   (ex_rs1_addr),
        .rs2_addr_out   (ex_rs2_addr),
        .rd_addr_out    (ex_rd_addr),
        .funct3_out     (ex_funct3),
        .funct7_out     (ex_funct7),
        .opcode_out     (ex_opcode),

        .reg_write_out  (ex_reg_write),
        .mem_read_out   (ex_mem_read),
        .mem_write_out  (ex_mem_write),
        .mem_to_reg_out (ex_mem_to_reg),
        .alu_src_out    (ex_alu_src),
        .branch_out     (ex_branch),
        .jump_out       (ex_jump),
        .alu_op_out     (ex_alu_op)
    );

    //===========================================================
    // EX stage
    //===========================================================
    wire [3:0]  ex_alu_ctrl;
    wire [31:0] ex_alu_operand_b;
    wire [31:0] ex_alu_result;
    wire        ex_alu_zero; // consumed by branch resolution, below

    alu_control u_aluctrl (
        .alu_op   (ex_alu_op),
        .opcode   (ex_opcode),
        .funct3   (ex_funct3),
        .funct7   (ex_funct7),
        .alu_ctrl (ex_alu_ctrl)
    );

    // Forwarding unit: resolves RAW hazards for the EX-stage
    // instruction's operands, using EX/MEM (mem_rd_addr/mem_reg_write,
    // declared below with the rest of the EX/MEM register outputs)
    // and MEM/WB (wb_rd_addr/wb_reg_write, declared with the ID
    // stage's write-port wires above).
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit u_fwd (
        .ex_rs1_addr   (ex_rs1_addr),
        .ex_rs2_addr   (ex_rs2_addr),
        .mem_rd_addr   (mem_rd_addr),
        .mem_reg_write (mem_reg_write),
        .wb_rd_addr    (wb_rd_addr),
        .wb_reg_write  (wb_reg_write),
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );

    // Forwarded operand values: 10=EX/MEM (most recent), 01=MEM/WB,
    // 00=no hazard, use ID/EX's own latched value.
    wire [31:0] ex_rs1_forwarded = (forward_a == 2'b10) ? mem_alu_result :
                                    (forward_a == 2'b01) ? wb_reg_write_data :
                                                            ex_rs1_data;

    wire [31:0] ex_rs2_forwarded = (forward_b == 2'b10) ? mem_alu_result :
                                    (forward_b == 2'b01) ? wb_reg_write_data :
                                                            ex_rs2_data;

    // ex_rs2_forwarded (not the raw, un-forwarded ex_rs2_data) feeds
    // BOTH the ALUSrc mux below AND the store-data path into EX/MEM
    // further down -- a store's data hazard uses this same forward,
    // since store data is the raw register value, not an ALU result.
    assign ex_alu_operand_b = ex_alu_src ? ex_imm_out : ex_rs2_forwarded;

    // AUIPC's ALU operand A must be the instruction's OWN PC, not
    // rs1_data -- AUIPC has no real rs1 field (those instruction
    // bits are part of the U-type immediate). Without this mux,
    // AUIPC silently computed rs1_data(=garbage/x0)+imm instead of
    // pc+imm. Caught by Phase 5 integration testing; control_unit.v
    // always intended this ("added to PC upstream") but the actual
    // wiring was missing until now.
    localparam OPCODE_AUIPC = 7'b0010111;
    wire is_auipc = (ex_opcode == OPCODE_AUIPC);
    wire [31:0] ex_alu_operand_a = is_auipc ? ex_pc : ex_rs1_forwarded;

    alu #(
        .WIDTH (32)
    ) u_alu (
        .operand_a  (ex_alu_operand_a),
        .operand_b  (ex_alu_operand_b),
        .alu_op     (ex_alu_ctrl),
        .alu_result (ex_alu_result),
        .zero_flag  (ex_alu_zero)
    );

    //-----------------------------------------------------------
    // Branch / Jump resolution (Increment 3)
    //-----------------------------------------------------------
    localparam OPCODE_JALR = 7'b1100111;

    wire is_jalr = (ex_opcode == OPCODE_JALR);

    // BEQ/BNE/BLT/BGE/BLTU/BGEU are ALL resolved correctly (see
    // alu_control.v -- funct3[2:1] selects SUB/SLT/SLTU, and
    // funct3[0] uniformly means "invert the base result" across
    // all three pairs). zero_flag is the right base for the SUB
    // case; alu_result[0] is the right base for SLT/SLTU.
    wire ex_branch_base = (ex_funct3[2:1] == 2'b00) ? ex_alu_zero : ex_alu_result[0];
    wire branch_taken = ex_branch & (ex_branch_base ^ ex_funct3[0]);

    // Shared PC+imm adder (branch target and JAL target). Uses
    // ex_pc/ex_imm_out -- the EX-stage instruction's OWN latched
    // PC and immediate, carried through ID/EX.
    wire [31:0] pc_target = ex_pc + ex_imm_out;

    // JALR target = rs1+imm = ex_alu_result (ALUSrc/ALUOp already
    // force this for JALR, exactly as in Phase 2), LSB cleared
    // per the RV32I spec. ex_alu_result already reflects any
    // needed EX-stage forwarding on rs1, since forwarding happens
    // upstream of the ALU.
    wire [31:0] jalr_target = {ex_alu_result[31:1], 1'b0};

    // flush=1 exactly when this cycle's EX-stage instruction is a
    // taken branch or any jump -- both IF and ID currently hold
    // wrong-path instructions that must be discarded this edge.
    assign flush = ex_jump | branch_taken;

    assign pc_redirect_target = ex_jump ? (is_jalr ? jalr_target : pc_target)
                                         : pc_target; // branch_taken case

    //===========================================================
    // EX/MEM pipeline register
    //===========================================================
    wire [31:0] mem_pc_plus4;
    wire [31:0] mem_rs2_data;

    wire        mem_mem_read;
    wire        mem_mem_write;
    wire        mem_mem_to_reg;
    wire        mem_jump;

    ex_mem_reg u_ex_mem (
        .clk            (clk),
        .rst_n          (rst_n),

        .pc_plus4_in    (ex_pc_plus4),
        .alu_result_in  (ex_alu_result),
        .rs2_data_in    (ex_rs2_forwarded), // forwarded value -- see EX stage note above
        .rd_addr_in     (ex_rd_addr),

        .reg_write_in   (ex_reg_write),
        .mem_read_in    (ex_mem_read),
        .mem_write_in   (ex_mem_write),
        .mem_to_reg_in  (ex_mem_to_reg),
        .jump_in        (ex_jump),

        .pc_plus4_out   (mem_pc_plus4),
        .alu_result_out (mem_alu_result),
        .rs2_data_out   (mem_rs2_data),
        .rd_addr_out    (mem_rd_addr),

        .reg_write_out  (mem_reg_write),
        .mem_read_out   (mem_mem_read),
        .mem_write_out  (mem_mem_write),
        .mem_to_reg_out (mem_mem_to_reg),
        .jump_out       (mem_jump)
    );

    //===========================================================
    // MEM stage
    //===========================================================
    wire [31:0] mem_read_data;

    data_memory #(
        .WORD_ADDR_WIDTH (8)
    ) u_dmem (
        .clk        (clk),
        .mem_read   (mem_mem_read),
        .mem_write  (mem_mem_write),
        .addr       (mem_alu_result),
        .write_data (mem_rs2_data),
        .read_data  (mem_read_data)
    );

    //===========================================================
    // MEM/WB pipeline register
    //===========================================================
    wire [31:0] wb_pc_plus4;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_mem_read_data;
    wire        wb_mem_to_reg;
    wire        wb_jump;

    mem_wb_reg u_mem_wb (
        .clk               (clk),
        .rst_n             (rst_n),

        .pc_plus4_in       (mem_pc_plus4),
        .alu_result_in     (mem_alu_result),
        .mem_read_data_in  (mem_read_data),
        .rd_addr_in        (mem_rd_addr),

        .reg_write_in      (mem_reg_write),
        .mem_to_reg_in     (mem_mem_to_reg),
        .jump_in           (mem_jump),

        .pc_plus4_out      (wb_pc_plus4),
        .alu_result_out    (wb_alu_result),
        .mem_read_data_out (wb_mem_read_data),
        .rd_addr_out       (wb_rd_addr),

        .reg_write_out     (wb_reg_write),
        .mem_to_reg_out    (wb_mem_to_reg),
        .jump_out          (wb_jump)
    );

    //===========================================================
    // WB stage: writeback mux (feeds register_file.rd_data above)
    //===========================================================
    assign wb_reg_write_data = wb_jump       ? wb_pc_plus4 :
                                wb_mem_to_reg ? wb_mem_read_data :
                                                wb_alu_result;
// Debug outputs for FPGA demonstration
assign debug_pc       = if_pc_out;
assign debug_wb_data  = wb_reg_write_data;
assign debug_wb_rd    = wb_rd_addr;
assign debug_wb_write = wb_reg_write;

endmodule
