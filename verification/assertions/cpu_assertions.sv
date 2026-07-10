module cpu_assertions
(
    input logic clk,

    input logic rst_n,

    input logic [31:0] pc
);

property pc_alignment;

@(posedge clk)

disable iff(!rst_n)

pc[1:0] == 2'b00;

endproperty

assert property(pc_alignment)

else

$error("PC Alignment Failed");

endmodule
