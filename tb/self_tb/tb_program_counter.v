//=============================================================
// Module      : tb_program_counter
// Description : Self-checking testbench for program_counter.v
//               Tests reset, normal PC+4 sequencing across
//               several cycles, an external "future mux" style
//               override (simulating what a branch/jump target
//               mux will later drive), reset re-assertion
//               mid-run, and PC+4 wraparound at the 32-bit
//               boundary.
// Standard    : Synthesizable/simulatable Verilog-2001
//=============================================================
`timescale 1ns/1ps

module tb_program_counter;

    localparam WIDTH = 32;
    localparam CLK_PERIOD = 10;

    reg              clk;
    reg              rst_n;
    reg  [WIDTH-1:0] pc_next;

    wire [WIDTH-1:0] pc_out;
    wire [WIDTH-1:0] pc_plus4;

    integer pass_count;
    integer fail_count;

    //---------------------------------------------------------
    // DUT instantiation
    //---------------------------------------------------------
    program_counter #(
        .WIDTH      (WIDTH),
        .RESET_ADDR (32'h00000000)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .pc_next  (pc_next),
        .pc_out   (pc_out),
        .pc_plus4 (pc_plus4)
    );

    //---------------------------------------------------------
    // Clock generation
    //---------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //---------------------------------------------------------
    // Self-checking task: check pc_out against expected value
    //---------------------------------------------------------
    task check_pc;
        input [319:0]    test_name;
        input [WIDTH-1:0] expected;
        begin
            if (pc_out === expected) begin
                pass_count = pass_count + 1;
                $display("[PASS] %0s : pc_out=0x%h (expected 0x%h)",
                          test_name, pc_out, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %0s : pc_out=0x%h expected=0x%h",
                          test_name, pc_out, expected);
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
        pc_next    = 32'd0;

        $display("=========================================");
        $display(" PROGRAM COUNTER TESTBENCH START");
        $display("=========================================");

        // ---------- Reset ----------
        @(negedge clk);
        @(posedge clk); // reset loads RESET_ADDR here
        @(negedge clk);
        check_pc("RESET_pc_is_zero", 32'h00000000);
        rst_n = 1'b1;

        // ---------- Normal PC+4 sequencing ----------
        // Emulate the future "default next-PC mux": in the absence of a
        // taken branch/jump, pc_next is simply pc_plus4 every cycle.
        pc_next = pc_plus4;
        @(posedge clk); @(negedge clk);
        check_pc("PC_PLUS4_cycle1", 32'd4);

        pc_next = pc_plus4;
        @(posedge clk); @(negedge clk);
        check_pc("PC_PLUS4_cycle2", 32'd8);

        pc_next = pc_plus4;
        @(posedge clk); @(negedge clk);
        check_pc("PC_PLUS4_cycle3", 32'd12);

        pc_next = pc_plus4;
        @(posedge clk); @(negedge clk);
        check_pc("PC_PLUS4_cycle4", 32'd16);

        // ---------- External override (models a future branch/jump mux) ----------
        // Drive an arbitrary target address directly into pc_next, exactly
        // as a future branch/jump-target mux output would.
        pc_next = 32'h00001000;
        @(posedge clk); @(negedge clk);
        check_pc("EXTERNAL_OVERRIDE_branch_target", 32'h00001000);

        // Resume straight-line PC+4 sequencing from the new address
        pc_next = pc_plus4;
        @(posedge clk); @(negedge clk);
        check_pc("RESUME_PC_PLUS4_after_override", 32'h00001004);

        // ---------- Reset re-asserted mid-run ----------
        rst_n = 1'b0;
        @(posedge clk); @(negedge clk);
        check_pc("RESET_REASSERTED_mid_run", 32'h00000000);
        rst_n = 1'b1;

        // ---------- PC+4 wraparound at the 32-bit boundary ----------
        pc_next = 32'hFFFFFFFC; // load PC close to max address
        @(posedge clk); @(negedge clk);
        check_pc("LOAD_NEAR_MAX_ADDR", 32'hFFFFFFFC);
        if (pc_plus4 === 32'h00000000) begin
            pass_count = pass_count + 1;
            $display("[PASS] PC_PLUS4_WRAPAROUND : pc_plus4=0x%h (expected 0x00000000)", pc_plus4);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] PC_PLUS4_WRAPAROUND : pc_plus4=0x%h expected=0x00000000", pc_plus4);
        end

        $display("=========================================");
        $display(" PROGRAM COUNTER TESTBENCH COMPLETE");
        $display(" PASS = %0d  FAIL = %0d", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT : ALL TESTS PASSED");
        else
            $display(" RESULT : %0d TEST(S) FAILED", fail_count);
        $display("=========================================");

        $finish;
    end

endmodule
