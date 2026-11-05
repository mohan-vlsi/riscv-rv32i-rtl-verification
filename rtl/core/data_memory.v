//=============================================================
// Module      : data_memory
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : Word-organized read/write data memory for LW/SW.
//               Synchronous (clocked) writes, combinational
//               (asynchronous) reads gated by mem_read.
// Standard    : Synthesizable Verilog-2001
//=============================================================
`timescale 1ns/1ps
module data_memory #(
    parameter WORD_ADDR_WIDTH = 8,                      // 2^8 = 256 words
    parameter MEM_SIZE_WORDS  = (1 << WORD_ADDR_WIDTH)  // 256 words = 1 KB
) (
    input  wire        clk,
    input  wire        mem_read,     // read enable (from control_unit.v)
    input  wire        mem_write,    // write enable (from control_unit.v)
    input  wire [31:0] addr,         // byte address (ALU result: rs1 + imm)
    input  wire [31:0] write_data,   // data to store (rs2_data, for SW)

    output wire [31:0] read_data     // data loaded (for LW, into WB mux)
);

    //---------------------------------------------------------
    // Word-organized storage
    //---------------------------------------------------------
    reg [31:0] mem [0:MEM_SIZE_WORDS-1];

    //---------------------------------------------------------
    // Byte address -> word index: drop the two byte-offset bits
    // (LW/SW addresses are always 4-byte aligned in this model)
    //---------------------------------------------------------
    wire [WORD_ADDR_WIDTH-1:0] word_index = addr[WORD_ADDR_WIDTH+1:2];

    //---------------------------------------------------------
    // Synchronous write, gated by mem_write
    //---------------------------------------------------------
    always @(posedge clk) begin
        if (mem_write) begin
            mem[word_index] <= write_data;
        end
    end

    //---------------------------------------------------------
    // Combinational read, gated by mem_read.
    // When mem_read is not asserted, read_data is forced to 0
    // rather than silently exposing memory contents -- makes
    // "read happened when it shouldn't have" bugs directly
    // observable in simulation/waveforms.
    //---------------------------------------------------------
    assign read_data = mem_read ? mem[word_index] : 32'd0;

    //---------------------------------------------------------
    // Simulation initial contents (all zero) -- avoids X values
    // on reads before any write has occurred.
    //---------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

endmodule
