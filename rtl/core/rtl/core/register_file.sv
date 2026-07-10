`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Project : RISC-V RV32I RTL Verification
// Module  : Register File
// Author  : Mohan Meesala
//
// Description:
// 32 x 32-bit Register File with:
// - Two asynchronous read ports
// - One synchronous write port
// - x0 hardwired to zero
//////////////////////////////////////////////////////////////////////////////////

module register_file #(
    parameter DATA_WIDTH = 32,
    parameter REG_COUNT  = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  reg_write,

    input  logic [4:0]            rs1_addr,
    input  logic [4:0]            rs2_addr,
    input  logic [4:0]            rd_addr,

    input  logic [DATA_WIDTH-1:0] rd_data,

    output logic [DATA_WIDTH-1:0] rs1_data,
    output logic [DATA_WIDTH-1:0] rs2_data
);

logic [DATA_WIDTH-1:0] registers [0:REG_COUNT-1];

integer i;

// Reset + Write Logic
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < REG_COUNT; i = i + 1)
            registers[i] <= '0;
    end
    else if (reg_write && (rd_addr != 5'd0)) begin
        registers[rd_addr] <= rd_data;
    end
end

// Asynchronous Read Port 1
always_comb begin
    if (rs1_addr == 5'd0)
        rs1_data = '0;
    else
        rs1_data = registers[rs1_addr];
end

// Asynchronous Read Port 2
always_comb begin
    if (rs2_addr == 5'd0)
        rs2_data = '0;
    else
        rs2_data = registers[rs2_addr];
end

endmodule
