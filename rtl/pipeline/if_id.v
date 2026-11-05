//=============================================================
// Module      : if_id_reg
// Project     : RV32I 5-Stage Pipelined Processor (Phase 3)
// Description : IF/ID pipeline register. Latches the fetched
//               instruction and its PC values for use in ID.
//               INCREMENT 1: no stall/flush inputs yet (added
//               once hazard detection / branch flush exist).
// Standard    : Synthesizable Verilog-2001
//=============================================================

module if_id_reg (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] instruction_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] instruction_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_out          <= 32'd0;
            pc_plus4_out    <= 32'd0;
            instruction_out <= 32'h00000013; // NOP (ADDI x0,x0,0) on reset
        end else begin
            pc_out          <= pc_in;
            pc_plus4_out    <= pc_plus4_in;
            instruction_out <= instruction_in;
        end
    end

endmodule
