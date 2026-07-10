module alu #(
    parameter DATA_WIDTH = 32
)
(
    input  logic [DATA_WIDTH-1:0] operand_a,
    input  logic [DATA_WIDTH-1:0] operand_b,
    input  alu_op_t               alu_op,

    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
);

always_comb begin

    case(alu_op)

        ALU_ADD : result = operand_a + operand_b;
        ALU_SUB : result = operand_a - operand_b;
        ALU_AND : result = operand_a & operand_b;
        ALU_OR  : result = operand_a | operand_b;
        ALU_XOR : result = operand_a ^ operand_b;
        ALU_SLL : result = operand_a << operand_b[4:0];
        ALU_SRL : result = operand_a >> operand_b[4:0];
        ALU_SRA : result = $signed(operand_a) >>> operand_b[4:0];
        ALU_SLT : result = ($signed(operand_a) < $signed(operand_b));

        default : result = '0;

    endcase

end

assign zero = (result == 32'd0);

endmodule
