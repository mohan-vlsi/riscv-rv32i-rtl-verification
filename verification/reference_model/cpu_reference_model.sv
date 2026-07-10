class cpu_reference_model;

    logic [31:0] expected_result;

    function logic [31:0] alu_model
    (
        alu_op_t op,
        logic [31:0] a,
        logic [31:0] b
    );

        case(op)

            ALU_ADD : alu_model = a + b;

            ALU_SUB : alu_model = a - b;

            ALU_AND : alu_model = a & b;

            ALU_OR  : alu_model = a | b;

            ALU_XOR : alu_model = a ^ b;

            ALU_SLL : alu_model = a << b[4:0];

            ALU_SRL : alu_model = a >> b[4:0];

            ALU_SRA : alu_model = $signed(a) >>> b[4:0];

            ALU_SLT : alu_model = ($signed(a) < $signed(b));

            default : alu_model = 32'h0;

        endcase

    endfunction

endclass
