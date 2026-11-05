//=============================================================
// Module      : alu_control
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : Translates the coarse ALUOp class (from the
//               Main Control Unit) plus opcode/funct3/funct7
//               into the exact 4-bit ALU operation code that
//               alu.v understands.
// Standard    : Synthesizable Verilog-2001
//=============================================================
`timescale 1ns/1ps
module alu_control (
    input  wire [1:0] alu_op,    // coarse class from control_unit.v
    input  wire [6:0] opcode,    // instruction[6:0]
    input  wire [2:0] funct3,    // instruction[14:12]
    input  wire [6:0] funct7,    // instruction[31:25]

    output reg  [3:0] alu_ctrl   // final ALU select (matches alu.v encoding)
);

    //---------------------------------------------------------
    // ALU operation encoding -- MUST match alu.v exactly
    //---------------------------------------------------------
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    localparam OPCODE_R_TYPE = 7'b0110011;

    //---------------------------------------------------------
    // ALUOp class encoding (from control_unit.v)
    //---------------------------------------------------------
    localparam CLASS_LOAD_STORE = 2'b00; // force ADD (address calc)
    localparam CLASS_BRANCH     = 2'b01; // decode via funct3[2:1] below
    localparam CLASS_RTYPE_ITYPE= 2'b10; // decode via funct3/funct7
    localparam CLASS_LUI        = 2'b11; // pass-through (ADD, operand_a=0)

    always @(*) begin
        case (alu_op)

            CLASS_LOAD_STORE: alu_ctrl = ALU_ADD;

            // Branches: funct3[2:1] selects which comparison, and
            // funct3[0] means "invert the result" for ALL THREE
            // pairs (BEQ/BNE, BLT/BGE, BLTU/BGEU) -- that inversion
            // itself is applied by the caller using zero_flag /
            // alu_result[0] together with funct3[0], NOT here; this
            // block only needs to pick the right COMPARISON op.
            //   funct3[2:1] = 00 -> BEQ/BNE  -> SUB (caller uses zero_flag)
            //   funct3[2:1] = 10 -> BLT/BGE  -> SLT  (signed)
            //   funct3[2:1] = 11 -> BLTU/BGEU-> SLTU (unsigned)
            //   funct3[2:1] = 01 -> reserved/unused in RV32I branches
            CLASS_BRANCH: begin
                case (funct3[2:1])
                    2'b00:   alu_ctrl = ALU_SUB;
                    2'b10:   alu_ctrl = ALU_SLT;
                    2'b11:   alu_ctrl = ALU_SLTU;
                    default: alu_ctrl = ALU_SUB; // reserved encoding: safe default
                endcase
            end

            CLASS_LUI:        alu_ctrl = ALU_ADD; // operand_a forced to 0
                                                   // upstream in the datapath

            CLASS_RTYPE_ITYPE: begin
                case (funct3)

                    3'b000: begin
                        // ADD (R-type & I-type) vs SUB (R-type ONLY).
                        // funct7[5] is only trustworthy as a real opcode
                        // bit when this is confirmed R-type -- for
                        // I-type ADDI, instruction[31:25] is immediate
                        // DATA, not a funct7 field, and must never be
                        // used to select SUB.
                        if ((opcode == OPCODE_R_TYPE) && funct7[5])
                            alu_ctrl = ALU_SUB;
                        else
                            alu_ctrl = ALU_ADD;
                    end

                    3'b001: alu_ctrl = ALU_SLL;  // SLL / SLLI

                    3'b010: alu_ctrl = ALU_SLT;  // SLT / SLTI

                    3'b011: alu_ctrl = ALU_SLTU; // SLTU / SLTIU

                    3'b100: alu_ctrl = ALU_XOR;  // XOR / XORI

                    3'b101: begin
                        // SRL vs SRA -- funct7[5] IS mandated/reliable
                        // here for BOTH R-type and I-type shift-immediate
                        // (SRLI/SRAI encode a fixed funct7 pattern, unlike
                        // ADDI's immediate-data bits).
                        if (funct7[5])
                            alu_ctrl = ALU_SRA;
                        else
                            alu_ctrl = ALU_SRL;
                    end

                    3'b110: alu_ctrl = ALU_OR;   // OR / ORI

                    3'b111: alu_ctrl = ALU_AND;  // AND / ANDI

                    default: alu_ctrl = ALU_ADD;

                endcase
            end

            default: alu_ctrl = ALU_ADD;

        endcase
    end

endmodule
