`timescale 1ns/1ps

module ex_mem
(
    input logic clk,
    input logic rst_n,

    input logic [31:0] alu_result_in,
    input logic [31:0] rs2_data_in,
    input logic [4:0]  rd_addr_in,

    input logic reg_write_in,
    input logic mem_read_in,
    input logic mem_write_in,
    input logic mem_to_reg_in,

    output logic [31:0] alu_result_out,
    output logic [31:0] rs2_data_out,
    output logic [4:0]  rd_addr_out,

    output logic reg_write_out,
    output logic mem_read_out,
    output logic mem_write_out,
    output logic mem_to_reg_out
);

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        alu_result_out <= '0;
        rs2_data_out   <= '0;
        rd_addr_out    <= '0;

        reg_write_out  <= 1'b0;
        mem_read_out   <= 1'b0;
        mem_write_out  <= 1'b0;
        mem_to_reg_out <= 1'b0;
    end
    else
    begin
        alu_result_out <= alu_result_in;
        rs2_data_out   <= rs2_data_in;
        rd_addr_out    <= rd_addr_in;

        reg_write_out  <= reg_write_in;
        mem_read_out   <= mem_read_in;
        mem_write_out  <= mem_write_in;
        mem_to_reg_out <= mem_to_reg_in;
    end
end

endmodule
