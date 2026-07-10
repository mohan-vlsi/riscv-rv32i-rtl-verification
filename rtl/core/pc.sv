`timescale 1ns/1ps

module pc #(
    parameter DATA_WIDTH = 32,
    parameter RESET_PC   = 32'h0000_0000
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  stall,
    input  logic [DATA_WIDTH-1:0] next_pc,

    output logic [DATA_WIDTH-1:0] pc
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pc <= RESET_PC;
    else if (!stall)
        pc <= next_pc;
end

endmodule
