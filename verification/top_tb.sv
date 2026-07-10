`timescale 1ns/1ps

module top_tb;

logic clk;

always #5 clk = ~clk;

cpu_if cpu_if_inst(clk);

cpu_environment env;

// DUT

riscv_top dut
(
    .clk(clk),
    .rst_n(cpu_if_inst.rst_n)
);

initial
begin

    clk = 0;

    cpu_if_inst.rst_n = 0;

    #20;

    cpu_if_inst.rst_n = 1;

end

initial
begin

    env = new(cpu_if_inst);

    env.run();

end

initial
begin

    #1000;

    $finish;

end

endmodule
