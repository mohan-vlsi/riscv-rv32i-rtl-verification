`timescale 1ns/1ps
//=============================================================
// Module      : immediate_generator
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : Extracts and sign-extends the immediate field
//               from a 32-bit RV32I instruction for I/S/B/U/J
//               formats. Format is decoded internally from the
//               opcode field.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module immediate_generator (
    input  wire [31:0] instruction,  // full 32-bit fetched instruction
    output reg  [31:0] imm_out       // sign-extended immediate
);

    //---------------------------------------------------------
    // RV32I opcode map (instruction[6:0]) relevant to Phase 1
    //---------------------------------------------------------
    localparam OPCODE_LOAD   = 7'b0000011; // I-type (lw, lh, lb, ...)
    localparam OPCODE_OP_IMM = 7'b0010011; // I-type (addi, andi, ...)
    localparam OPCODE_JALR   = 7'b1100111; // I-type
    localparam OPCODE_STORE  = 7'b0100011; // S-type (sw, sh, sb)
    localparam OPCODE_BRANCH = 7'b1100011; // B-type (beq, bne, ...)
    localparam OPCODE_LUI    = 7'b0110111; // U-type
    localparam OPCODE_AUIPC  = 7'b0010111; // U-type
    localparam OPCODE_JAL    = 7'b1101111; // J-type

    wire [6:0] opcode = instruction[6:0];

    //---------------------------------------------------------
    // Combinational immediate extraction + sign extension
    //---------------------------------------------------------
    always @(*) begin
        case (opcode)

            // ---------------- I-type ----------------
            // imm[11:0] = instruction[31:20]
            OPCODE_LOAD, OPCODE_OP_IMM, OPCODE_JALR: begin
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            end

            // ---------------- S-type ----------------
            // imm[11:5] = instruction[31:25], imm[4:0] = instruction[11:7]
            OPCODE_STORE: begin
                imm_out = {{20{instruction[31]}},
                           instruction[31:25], instruction[11:7]};
            end

            // ---------------- B-type ----------------
            // imm[12]=instr[31], imm[11]=instr[7], imm[10:5]=instr[30:25],
            // imm[4:1]=instr[11:8], imm[0]=0 (implied)
            OPCODE_BRANCH: begin
                imm_out = {{19{instruction[31]}}, instruction[31],
                           instruction[7], instruction[30:25],
                           instruction[11:8], 1'b0};
            end

            // ---------------- U-type ----------------
            // imm[31:12] = instruction[31:12], imm[11:0] = 0 (implied)
            OPCODE_LUI, OPCODE_AUIPC: begin
                imm_out = {instruction[31:12], 12'b0};
            end

            // ---------------- J-type ----------------
            // imm[20]=instr[31], imm[19:12]=instr[19:12], imm[11]=instr[20],
            // imm[10:1]=instr[30:21], imm[0]=0 (implied)
            OPCODE_JAL: begin
                imm_out = {{11{instruction[31]}}, instruction[31],
                           instruction[19:12], instruction[20],
                           instruction[30:21], 1'b0};
            end

            // ---------------- Unrecognized opcode ----------------
            default: begin
                imm_out = 32'd0;
            end

        endcase
    end

endmodule
