`timescale 1ns/1ps

module data_memory #(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256
)
(
    input logic clk,

    input logic mem_read,
    input logic mem_write,

    input logic [31:0] address,
    input logic [31:0] write_data,

    output logic [31:0] read_data
);

logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

always_ff @(posedge clk)
begin
    if(mem_write)
        memory[address[31:2]] <= write_data;
end

always_comb
begin
    if(mem_read)
        read_data = memory[address[31:2]];
    else
        read_data = '0;
end

endmodule
