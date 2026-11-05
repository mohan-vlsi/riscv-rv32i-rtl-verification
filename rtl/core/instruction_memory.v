//=============================================================
// Module      : instruction_memory
// Project     : RV32I 5-Stage Pipelined Processor (Phase 1)
// Description : Read-only, word-organized instruction memory.
//               Address input is a BYTE address (as produced by
//               the Program Counter); the two LSBs are dropped
//               to form a word index since instruction fetches
//               are always 4-byte aligned. Preloaded with a
//               small test program via an initial block --
//               no external file dependency.
// Standard    : Synthesizable Verilog-2001
//=============================================================
`timescale 1ns/1ps
module instruction_memory #(
    parameter WORD_ADDR_WIDTH = 8,                      // 2^8 = 256 words
    parameter MEM_SIZE_WORDS  = (1 << WORD_ADDR_WIDTH)  // 256 words = 1 KB
) (
    input  wire [31:0] addr,         // byte address (from PC, addr[1:0] must be 00)
    output wire [31:0] instruction   // instruction word at that address
);

    //---------------------------------------------------------
    // Word-organized storage
    //---------------------------------------------------------
    reg [31:0] mem [0:MEM_SIZE_WORDS-1];

    //---------------------------------------------------------
    // Byte address -> word index: drop the two byte-offset bits
    // (addr[1:0]) since fetches are always 4-byte aligned.
    //---------------------------------------------------------
    wire [WORD_ADDR_WIDTH-1:0] word_index = addr[WORD_ADDR_WIDTH+1:2];

    //---------------------------------------------------------
    // Combinational (asynchronous) read
    //---------------------------------------------------------
    assign instruction = mem[word_index];

    //---------------------------------------------------------
    // Simulation/synthesis initial program load.
    // No external file dependency: instructions are hard-coded
    // machine-code words, independently computed (not hand
    // bit-packed) for the following 5-instruction test program:
    //
    //   addr 0x00 : ADDI x1, x0, 5      -> x1 = 5
    //   addr 0x04 : ADDI x2, x0, 10     -> x2 = 10
    //   addr 0x08 : ADD  x3, x1, x2     -> x3 = x1 + x2 = 15
    //   addr 0x0C : SUB  x4, x1, x2     -> x4 = x1 - x2 = -5
    //   addr 0x10 : JAL  x0, 0          -> infinite self-loop (halt marker)
    //   all remaining words             -> NOP (ADDI x0, x0, 0)
    //---------------------------------------------------------
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE_WORDS; i = i + 1) begin
            mem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end

        mem[0] = 32'h00500093; // ADDI x1, x0, 5
        mem[1] = 32'h00A00113; // ADDI x2, x0, 10
        mem[2] = 32'h002081B3; // ADD  x3, x1, x2
        mem[3] = 32'h40208233; // SUB  x4, x1, x2
        mem[4] = 32'h0000006F; // JAL  x0, 0  (self-loop)
    end

endmodule
