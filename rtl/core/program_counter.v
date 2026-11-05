//=============================================================
// Module      : program_counter
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : 32-bit Program Counter register with synchronous
//               reset and a PC+4 incrementer. The actual next-PC
//               SELECTION (straight-line vs branch vs jump target)
//               is intentionally left external to this module --
//               pc_next is a generic port that a future mux will
//               drive. No branch/jump logic is implemented here.
// Standard    : Synthesizable Verilog-2001
//=============================================================
`timescale 1ns/1ps
module program_counter #(
    parameter WIDTH      = 32,
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire             clk,
    input  wire             rst_n,     // active-low synchronous reset

    input  wire [WIDTH-1:0] pc_next,   // next PC value (driven externally;
                                        // today: tied to pc_plus4 by the
                                        // testbench/top level. Later: output
                                        // of a branch/jump-target mux.)

    output reg  [WIDTH-1:0] pc_out,    // current PC (-> Instruction Memory)
    output wire [WIDTH-1:0] pc_plus4   // PC + 4 (convenience: default next-PC
                                        // candidate, and JAL/JALR link value)
);

    //---------------------------------------------------------
    // PC register: synchronous reset, updates to pc_next each edge
    //---------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n)
            pc_out <= RESET_ADDR;
        else
            pc_out <= pc_next;
    end

    //---------------------------------------------------------
    // PC+4 incrementer (combinational)
    //---------------------------------------------------------
    assign pc_plus4 = pc_out + 32'd4;

endmodule
