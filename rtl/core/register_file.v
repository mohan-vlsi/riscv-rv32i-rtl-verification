`timescale 1ns/1ps
//=============================================================
// Module      : register_file
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : 32 x 32-bit general-purpose register file.
//               Two asynchronous (combinational) read ports,
//               one synchronous write port. x0 hardwired to 0.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module register_file #(
    parameter WIDTH     = 32,
    parameter NUM_REGS  = 32,
    parameter ADDR_BITS = 5
) (
    input  wire                  clk,
    input  wire                  rst_n,       // active-low synchronous reset

    input  wire                  reg_write,   // write enable
    input  wire [ADDR_BITS-1:0]  rs1_addr,    // source register 1 address
    input  wire [ADDR_BITS-1:0]  rs2_addr,    // source register 2 address
    input  wire [ADDR_BITS-1:0]  rd_addr,     // destination register address
    input  wire [WIDTH-1:0]      rd_data,     // data to write into rd_addr

    output wire [WIDTH-1:0]      rs1_data,    // read data 1
    output wire [WIDTH-1:0]      rs2_data     // read data 2
);

    //---------------------------------------------------------
    // Register storage: 32 x 32-bit array
    //---------------------------------------------------------
    reg [WIDTH-1:0] regfile [0:NUM_REGS-1];

    integer i;

    //---------------------------------------------------------
    // Synchronous write + synchronous reset
    // Nonblocking assignments used for sequential logic
    //---------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_REGS; i = i + 1) begin
                regfile[i] <= {WIDTH{1'b0}};
            end
        end else if (reg_write && (rd_addr != {ADDR_BITS{1'b0}})) begin
            // x0 (address 0) is never written
            regfile[rd_addr] <= rd_data;
        end
    end

   //---------------------------------------------------------
// Asynchronous (combinational) reads, x0 forced to zero
// Includes WB -> ID bypass
//---------------------------------------------------------
assign rs1_data =
    (rs1_addr == {ADDR_BITS{1'b0}}) ? {WIDTH{1'b0}} :
    (reg_write && (rd_addr != {ADDR_BITS{1'b0}}) &&
     (rs1_addr == rd_addr)) ? rd_data :
    regfile[rs1_addr];

assign rs2_data =
    (rs2_addr == {ADDR_BITS{1'b0}}) ? {WIDTH{1'b0}} :
    (reg_write && (rd_addr != {ADDR_BITS{1'b0}}) &&
     (rs2_addr == rd_addr)) ? rd_data :
    regfile[rs2_addr];
endmodule
