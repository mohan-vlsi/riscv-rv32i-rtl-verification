interface cpu_if(input logic clk);

    logic rst_n;

    logic stall;

    logic [31:0] next_pc;

    logic [31:0] pc;

endinterface
