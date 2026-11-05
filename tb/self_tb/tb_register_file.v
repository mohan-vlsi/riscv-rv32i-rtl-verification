//=============================================================
// Module      : tb_register_file
// Description : Self-checking testbench for register_file.v
//               Tests reset, write/read, simultaneous dual-port
//               reads, overwrite, x0 hardwiring, write-enable
//               gating, and write-then-read timing.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_register_file;

    localparam WIDTH     = 32;
    localparam ADDR_BITS = 5;
    localparam CLK_PERIOD = 10;

    reg                   clk;
    reg                   rst_n;
    reg                   reg_write;
    reg  [ADDR_BITS-1:0]  rs1_addr;
    reg  [ADDR_BITS-1:0]  rs2_addr;
    reg  [ADDR_BITS-1:0]  rd_addr;
    reg  [WIDTH-1:0]      rd_data;

    wire [WIDTH-1:0]      rs1_data;
    wire [WIDTH-1:0]      rs2_data;

    integer pass_count;
    integer fail_count;
    integer loop_idx;

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    register_file #(
        .WIDTH     (WIDTH),
        .NUM_REGS  (32),
        .ADDR_BITS (ADDR_BITS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_write (reg_write),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),
        .rd_data   (rd_data),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    //---------------------------------------------------------
    // Clock generation
    //---------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //---------------------------------------------------------
    // Task: perform a synchronous write (waits for clock edge)
    //---------------------------------------------------------
    task do_write;
        input [ADDR_BITS-1:0] addr;
        input [WIDTH-1:0]     data;
        input                 enable;
        begin
            @(negedge clk); // set up inputs mid-cycle, away from edge
            reg_write = enable;
            rd_addr   = addr;
            rd_data   = data;
            @(posedge clk); // write commits here
            @(negedge clk);
            reg_write = 1'b0;
        end
    endtask

    //---------------------------------------------------------
    // Task: self-checking read comparison
    //---------------------------------------------------------
    task check_read;
        input [319:0]     test_name;   // string label (40 chars @ 8 bits/char)
        input [ADDR_BITS-1:0] r1_addr;
        input [ADDR_BITS-1:0] r2_addr;
        input [WIDTH-1:0]     expected1;
        input [WIDTH-1:0]     expected2;
        begin
            rs1_addr = r1_addr;
            rs2_addr = r2_addr;
            #1; // allow combinational read to settle
            if ((rs1_data === expected1) && (rs2_data === expected2)) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : rs1(x%0d)=0x%h rs2(x%0d)=0x%h",
                          test_name, r1_addr, rs1_data, r2_addr, rs2_data);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : rs1(x%0d) got=0x%h exp=0x%h | rs2(x%0d) got=0x%h exp=0x%h",
                          test_name, r1_addr, rs1_data, expected1,
                          r2_addr, rs2_data, expected2);
            end
        end
    endtask

    //---------------------------------------------------------
    // Test sequence
    //---------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        rst_n      = 1'b0;
        reg_write  = 1'b0;
        rs1_addr   = 5'd0;
        rs2_addr   = 5'd0;
        rd_addr    = 5'd0;
        rd_data    = 32'd0;

        $display("=========================================");
        $display(" REGISTER FILE TESTBENCH START");
        $display("=========================================");

        // ---------- Reset ----------
        @(negedge clk);
        @(posedge clk); // reset clears all registers here
        @(negedge clk);
        rst_n = 1'b1;
        check_read("RESET_x1_x31_zero", 5'd1, 5'd31, 32'd0, 32'd0);

        // ---------- Basic write then read ----------
        do_write(5'd5, 32'hAAAA5555, 1'b1);
        check_read("WRITE_x5_READ_x5", 5'd5, 5'd0, 32'hAAAA5555, 32'd0);

        // ---------- Second write, simultaneous dual read ----------
        do_write(5'd10, 32'h12345678, 1'b1);
        check_read("SIMULTANEOUS_x5_x10", 5'd5, 5'd10, 32'hAAAA5555, 32'h12345678);

        // ---------- Overwrite existing register ----------
        do_write(5'd5, 32'hDEADBEEF, 1'b1);
        check_read("OVERWRITE_x5", 5'd5, 5'd0, 32'hDEADBEEF, 32'd0);

        // ---------- x0 must never be written, always reads 0 ----------
        do_write(5'd0, 32'hFFFFFFFF, 1'b1);
        check_read("X0_HARDWIRED_ZERO", 5'd0, 5'd0, 32'd0, 32'd0);

        // ---------- reg_write de-asserted: write must NOT happen ----------
        do_write(5'd7, 32'h11111111, 1'b0);
        check_read("WRITE_DISABLED_x7_still_zero", 5'd7, 5'd0, 32'd0, 32'd0);

        // ---------- Write-then-read timing: read BEFORE the write's
        // posedge must show the OLD value (write not yet committed) ----------
        @(negedge clk);
        reg_write = 1'b1;
        rd_addr   = 5'd8;
        rd_data   = 32'h55555555;
        rs1_addr  = 5'd8;
        #1;
        check_read("PRE_EDGE_READ_SHOWS_OLD_VALUE", 5'd8, 5'd0, 32'd0, 32'd0);
        @(posedge clk); // write commits now
        @(negedge clk);
        reg_write = 1'b0;
        check_read("POST_EDGE_READ_SHOWS_NEW_VALUE", 5'd8, 5'd0, 32'h55555555, 32'd0);

        // ---------- Sweep: write and read back every register 1..31 ----------
        // NOTE: loop counter must be a wide 'integer', NOT the 5-bit
        // rd_addr register -- using a 5-bit reg as a loop counter up to
        // 32 wraps (31 + 1 = 0 in 5 bits) and creates an infinite loop.
        for (loop_idx = 1; loop_idx < 32; loop_idx = loop_idx + 1) begin
            do_write(loop_idx[ADDR_BITS-1:0], loop_idx[4:0] ^ 32'hCAFE0000, 1'b1);
        end
        for (loop_idx = 1; loop_idx < 32; loop_idx = loop_idx + 1) begin
            check_read("SWEEP_ALL_REGS", loop_idx[ADDR_BITS-1:0], 5'd0,
                       (loop_idx[4:0] ^ 32'hCAFE0000), 32'd0);
        end

        $display("=========================================");
        $display(" REGISTER FILE TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
