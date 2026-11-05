//=============================================================
// Module      : ex_mem_reg
// Project     : RV32I 5-Stage Pipelined Processor (Phase 3)
// Description : EX/MEM pipeline register. Latches the ALU
//               result, the (unmodified) store data, and
//               control signals for use in MEM.
//
//               IMPORTANT: rs2_data_in here MUST be the
//               un-muxed register value (rs2_data straight from
//               ID/EX), NOT the ALU's operand_b. For a store
//               instruction, ALUSrc selects the immediate as
//               operand_b (for address calculation), but the
//               value actually being stored is always rs2_data
//               itself. Conflating the two silently stores the
//               wrong value.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module ex_mem_reg (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rs2_data_in,   // store data (see header note)
    input  wire [4:0]  rd_addr_in,

    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        jump_in,

    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rs2_data_out,
    output reg  [4:0]  rd_addr_out,

    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         jump_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_plus4_out   <= 32'd0;
            alu_result_out <= 32'd0;
            rs2_data_out   <= 32'd0;
            rd_addr_out    <= 5'd0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            jump_out       <= 1'b0;
        end else begin
            pc_plus4_out   <= pc_plus4_in;
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;
            rd_addr_out    <= rd_addr_in;

            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            jump_out       <= jump_in;
        end
    end

endmodule
