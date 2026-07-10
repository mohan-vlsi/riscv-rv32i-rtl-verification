module if_id
(
    input logic clk,
    input logic rst_n,

    input logic stall,
    input logic flush,

    input logic [31:0] pc_in,
    input logic [31:0] instruction_in,

    output logic [31:0] pc_out,
    output logic [31:0] instruction_out
);

always_ff @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin
        pc_out <= '0;
        instruction_out <= '0;
    end

    else if(flush)
    begin
        pc_out <= '0;
        instruction_out <= 32'h00000013; // NOP
    end

    else if(!stall)
    begin
        pc_out <= pc_in;
        instruction_out <= instruction_in;
    end

end

endmodule
