//=============================================================
// Module      : id_ex_reg
// Project     : RV32I 5-Stage Pipelined Processor (Phase 3)
// Description : ID/EX pipeline register. Latches decoded
//               register data, immediate, instruction fields,
//               and control signals for use in EX.
//               rs1_addr/rs2_addr are carried through now even
//               though unused this increment -- the future
//               hazard detection unit will need them, and
//               plumbing them through here now avoids an
//               interface change later.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module id_ex_reg (
    input  wire        clk,
    input  wire        rst_n,

    // Datapath values
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_out_in,
    input  wire [4:0]  rs1_addr_in,
    input  wire [4:0]  rs2_addr_in,
    input  wire [4:0]  rd_addr_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in,
    input  wire [6:0]  opcode_in,

    // Control signals (from control_unit.v)
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        alu_src_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire [1:0]  alu_op_in,

    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out_out,
    output reg  [4:0]  rs1_addr_out,
    output reg  [4:0]  rs2_addr_out,
    output reg  [4:0]  rd_addr_out,
    output reg  [2:0]  funct3_out,
    output reg  [6:0]  funct7_out,
    output reg  [6:0]  opcode_out,

    output reg         reg_write_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         mem_to_reg_out,
    output reg         alu_src_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg  [1:0]  alu_op_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_out         <= 32'd0;
            pc_plus4_out   <= 32'd0;
            rs1_data_out   <= 32'd0;
            rs2_data_out   <= 32'd0;
            imm_out_out    <= 32'd0;
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
            rd_addr_out    <= 5'd0;
            funct3_out     <= 3'd0;
            funct7_out     <= 7'd0;
            opcode_out     <= 7'd0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_src_out    <= 1'b0;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            alu_op_out     <= 2'b00;
        end else begin
            pc_out         <= pc_in;
            pc_plus4_out   <= pc_plus4_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_out_out    <= imm_out_in;
            rs1_addr_out   <= rs1_addr_in;
            rs2_addr_out   <= rs2_addr_in;
            rd_addr_out    <= rd_addr_in;
            funct3_out     <= funct3_in;
            funct7_out     <= funct7_in;
            opcode_out     <= opcode_in;

            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_src_out    <= alu_src_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            alu_op_out     <= alu_op_in;
        end
    end

endmodule
