`timescale 1ns/1ps
//=============================================================
// Module      : alu
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : Combinational Arithmetic Logic Unit supporting
//               all RV32I integer ALU operations.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module alu #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] operand_a,   // First operand (rs1)
    input  wire [WIDTH-1:0] operand_b,   // Second operand (rs2 or immediate)
    input  wire [3:0]       alu_op,      // Operation select (from ALU Control)

    output reg  [WIDTH-1:0] alu_result,  // Result of the operation
    output wire             zero_flag    // 1 if alu_result == 0
);

    //---------------------------------------------------------
    // ALU operation encoding (local parameters for readability)
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

    //---------------------------------------------------------
    // Shift amount is only the lower 5 bits of operand_b for a
    // 32-bit datapath (2^5 = 32 possible shift amounts).
    //---------------------------------------------------------
    wire [4:0] shift_amt = operand_b[4:0];

    //---------------------------------------------------------
    // Combinational operation select
    // Blocking assignments used inside combinational always block
    //---------------------------------------------------------
    always @(*) begin
        case (alu_op)
        
            ALU_ADD  : alu_result = operand_a + operand_b;
            ALU_SUB  : alu_result = operand_a - operand_b;
            ALU_AND  : alu_result = operand_a & operand_b;
            ALU_OR   : alu_result = operand_a | operand_b;
            ALU_XOR  : alu_result = operand_a ^ operand_b;
            ALU_SLL  : alu_result = operand_a << shift_amt;
            ALU_SRL  : alu_result = operand_a >> shift_amt;
            ALU_SRA  : alu_result = $signed(operand_a) >>> shift_amt;
            ALU_SLT  : alu_result = ($signed(operand_a) < $signed(operand_b))
                                     ? {{(WIDTH-1){1'b0}}, 1'b1}
                                     : {WIDTH{1'b0}};
            ALU_SLTU : alu_result = (operand_a < operand_b)
                                     ? {{(WIDTH-1){1'b0}}, 1'b1}
                                     : {WIDTH{1'b0}};
            default  : alu_result = {WIDTH{1'b0}};
        endcase
    end

    //---------------------------------------------------------
    // Zero flag: combinational, derived from result
    //---------------------------------------------------------
    assign zero_flag = (alu_result == {WIDTH{1'b0}});

endmodule
