module riscv_top
(
    input logic clk,
    input logic rst_n
);

// Program Counter
logic [31:0] pc;

// Next PC
logic [31:0] next_pc;

// Instruction
logic [31:0] instruction;

// Register File
logic [31:0] rs1_data;
logic [31:0] rs2_data;

// Immediate
logic [31:0] immediate;

// ALU
logic [31:0] alu_result;

// Memory
logic [31:0] mem_data;

// Instantiate Program Counter
pc u_pc(
    .clk(clk),
    .rst_n(rst_n),
    .stall(1'b0),
    .next_pc(next_pc),
    .pc(pc)
);

// Instruction Memory
instruction_memory u_imem(
    .addr(pc),
    .instruction(instruction)
);

// Immediate Generator
immediate_generator u_imm(
    .instruction(instruction),
    .immediate(immediate)
);

// Register File
register_file u_regfile(
    .*
);

// ALU
alu u_alu(
    .*
);

// Data Memory
data_memory u_dmem(
    .*
);

// PC + 4
assign next_pc = pc + 32'd4;

endmodule
