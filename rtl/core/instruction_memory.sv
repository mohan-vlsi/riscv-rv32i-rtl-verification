`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Project : RISC-V RV32I RTL Verification
// Module  : Instruction Memory
// Author  : Mohan Meesala
//
// Description:
// Read-only instruction memory with parameterized depth.
// Instructions are initialized using $readmemh().
//////////////////////////////////////////////////////////////////////////////////

module instruction_memory #(
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256,
    parameter MEM_FILE   = "../../test_programs/arithmetic.hex"
)(
    input  logic [31:0] addr,
    output logic [DATA_WIDTH-1:0] instruction
);

logic [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

initial begin
    $readmemh(MEM_FILE, memory);
end

// Word-aligned instruction fetch
assign instruction = memory[addr[31:2]];

endmodule
