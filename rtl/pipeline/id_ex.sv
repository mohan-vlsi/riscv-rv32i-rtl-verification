module id_ex
(
    input logic clk,
    input logic rst_n,

    input logic flush,

    input logic [31:0] pc_in,
    input logic [31:0] rs1_data_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] imm_in,

    input logic [4:0] rs1_addr_in,
    input logic [4:0] rs2_addr_in,
    input logic [4:0] rd_addr_in,

    input logic reg_write_in,
    input logic mem_read_in,
    input logic mem_write_in,
    input logic mem_to_reg_in,
    input logic alu_src_in,
    input logic branch_in,

    input logic [1:0] alu_op_in,

    output logic [31:0] pc_out,
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] imm_out,

    output logic [4:0] rs1_addr_out,
    output logic [4:0] rs2_addr_out,
    output logic [4:0] rd_addr_out,

    output logic reg_write_out,
    output logic mem_read_out,
    output logic mem_write_out,
    output logic mem_to_reg_out,
    output logic alu_src_out,
    output logic branch_out,

    output logic [1:0] alu_op_out
);

always_ff @(posedge clk or negedge rst_n)
begin

    if(!rst_n || flush)
    begin
        pc_out <= '0;
        rs1_data_out <= '0;
        rs2_data_out <= '0;
        imm_out <= '0;

        rs1_addr_out <= '0;
        rs2_addr_out <= '0;
        rd_addr_out <= '0;

        reg_write_out <= 1'b0;
        mem_read_out <= 1'b0;
        mem_write_out <= 1'b0;
        mem_to_reg_out <= 1'b0;
        alu_src_out <= 1'b0;
        branch_out <= 1'b0;
        alu_op_out <= 2'b00;
    end

    else
    begin
        pc_out <= pc_in;
        rs1_data_out <= rs1_data_in;
        rs2_data_out <= rs2_data_in;
        imm_out <= imm_in;

        rs1_addr_out <= rs1_addr_in;
        rs2_addr_out <= rs2_addr_in;
        rd_addr_out <= rd_addr_in;

        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        mem_to_reg_out <= mem_to_reg_in;
        alu_src_out <= alu_src_in;
        branch_out <= branch_in;
        alu_op_out <= alu_op_in;
    end

end

endmodule
