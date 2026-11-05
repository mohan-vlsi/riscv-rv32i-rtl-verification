//=============================================================
// Module      : tb_data_memory
// Description : Self-checking testbench for data_memory.v
//               Tests initial zero contents, write/read-back,
//               read-enable gating, write-enable gating,
//               overwrite, same-cycle write-then-read timing,
//               byte-offset truncation, and out-of-range
//               address aliasing.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_data_memory;

    localparam WORD_ADDR_WIDTH = 8;
    localparam MEM_SIZE_WORDS  = (1 << WORD_ADDR_WIDTH);
    localparam CLK_PERIOD = 10;

    reg         clk;
    reg         mem_read;
    reg         mem_write;
    reg  [31:0] addr;
    reg  [31:0] write_data;

    wire [31:0] read_data;

    integer pass_count;
    integer fail_count;

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    data_memory #(
        .WORD_ADDR_WIDTH (WORD_ADDR_WIDTH),
        .MEM_SIZE_WORDS  (MEM_SIZE_WORDS)
    ) dut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (write_data),
        .read_data  (read_data)
    );

    //---------------------------------------------------------
    // Clock generation
    //---------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //---------------------------------------------------------
    // Task: synchronous write (waits for clock edge)
    //---------------------------------------------------------
    task do_write;
        input [31:0] addr_in;
        input [31:0] data_in;
        input        enable;
        begin
            @(negedge clk);
            mem_write  = enable;
            addr       = addr_in;
            write_data = data_in;
            @(posedge clk); // write commits here
            @(negedge clk);
            mem_write  = 1'b0;
        end
    endtask

    //---------------------------------------------------------
    // Task: self-checking read comparison
    //---------------------------------------------------------
    task check_read;
        input [319:0] test_name;
        input [31:0]  addr_in;
        input         read_en;
        input [31:0]  expected;
        begin
            addr     = addr_in;
            mem_read = read_en;
            #1;
            if (read_data === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : addr=0x%h mem_read=%b -> read_data=0x%h",
                          test_name, addr_in, read_en, read_data);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : addr=0x%h mem_read=%b -> got=0x%h expected=0x%h",
                          test_name, addr_in, read_en, read_data, expected);
            end
        end
    endtask

    //---------------------------------------------------------
    // Test sequence
    //---------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        addr       = 32'd0;
        write_data = 32'd0;

        $display("=========================================");
        $display(" DATA MEMORY TESTBENCH START");
        $display("=========================================");

        // ---------- Initial contents are zero ----------
        check_read("INITIAL_addr0_is_zero", 32'h00000000, 1'b1, 32'd0);

        // ---------- Basic write then read-back (models SW then LW) ----------
        do_write(32'h00000000, 32'hCAFEBABE, 1'b1);
        check_read("WRITE_THEN_READ_addr0", 32'h00000000, 1'b1, 32'hCAFEBABE);

        // ---------- mem_read=0 forces read_data=0 despite valid contents ----------
        check_read("READ_DISABLED_forces_zero", 32'h00000000, 1'b0, 32'd0);

        // ---------- Multiple independent addresses ----------
        do_write(32'h00000004, 32'h11112222, 1'b1);
        do_write(32'h00000008, 32'h33334444, 1'b1);
        check_read("READ_addr4",  32'h00000004, 1'b1, 32'h11112222);
        check_read("READ_addr8",  32'h00000008, 1'b1, 32'h33334444);
        check_read("READ_addr0_still_intact", 32'h00000000, 1'b1, 32'hCAFEBABE);

        // ---------- Overwrite existing location ----------
        do_write(32'h00000000, 32'hDEADBEEF, 1'b1);
        check_read("OVERWRITE_addr0", 32'h00000000, 1'b1, 32'hDEADBEEF);

        // ---------- Write disabled: memory must remain unchanged ----------
        do_write(32'h0000000C, 32'h99999999, 1'b0);
        check_read("WRITE_DISABLED_addr12_still_zero", 32'h0000000C, 1'b1, 32'd0);

        // ---------- Same-cycle write-then-read timing ----------
        // Read BEFORE the write's posedge must show the OLD value.
        @(negedge clk);
        mem_write  = 1'b1;
        addr       = 32'h00000010;
        write_data = 32'h55667788;
        mem_read   = 1'b1;
        #1;
        check_read("PRE_EDGE_READ_SHOWS_OLD_VALUE", 32'h00000010, 1'b1, 32'd0);
        @(posedge clk); // write commits now
        @(negedge clk);
        mem_write = 1'b0;
        check_read("POST_EDGE_READ_SHOWS_NEW_VALUE", 32'h00000010, 1'b1, 32'h55667788);

        // ---------- Byte-offset bits within a word are ignored ----------
        // addr=0x02 is not a legally aligned LW/SW address in this model,
        // but the hardware deterministically truncates to word_index=0,
        // so it aliases to the same word as addr=0x00.
        check_read("MISALIGNED_addr_0x02_aliases_word0", 32'h00000002, 1'b1, 32'hDEADBEEF);

        // ---------- Out-of-range address aliasing ----------
        // Only addr[9:2] is decoded; addr=0xFFFFFFFF aliases to word 255
        // (last word in the declared range), which is still zero (untouched).
        check_read("OUT_OF_RANGE_ADDR_ALIASES_word255", 32'hFFFFFFFF, 1'b1, 32'd0);

        $display("=========================================");
        $display(" DATA MEMORY TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
