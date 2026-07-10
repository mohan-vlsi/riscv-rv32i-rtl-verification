module alu_control
(
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7,

    output alu_op_t    alu_ctrl
);

always_comb begin

    case(alu_op)

        2'b00:
            alu_ctrl = ALU_ADD;

        2'b01:
            alu_ctrl = ALU_SUB;

        2'b10:
        begin

            case(funct3)

                3'b000:
                    alu_ctrl = funct7 ? ALU_SUB : ALU_ADD;

                3'b111:
                    alu_ctrl = ALU_AND;

                3'b110:
                    alu_ctrl = ALU_OR;

                3'b100:
                    alu_ctrl = ALU_XOR;

                3'b001:
                    alu_ctrl = ALU_SLL;

                3'b101:
                    alu_ctrl = funct7 ? ALU_SRA : ALU_SRL;

                3'b010:
                    alu_ctrl = ALU_SLT;

                default:
                    alu_ctrl = ALU_ADD;

            endcase

        end

        default:
            alu_ctrl = ALU_ADD;

    endcase

end

endmodule
