//=============================================================
// Module      : forwarding_unit
// Project     : RV32I 5-Stage Pipelined Processor (Phase 3)
// Description : Detects RAW hazards where the EX-stage
//               instruction's source register(s) match the
//               destination register of an instruction currently
//               in EX/MEM (1 instruction ahead) or MEM/WB
//               (2 instructions ahead), and selects the correct
//               forwarding source for each ALU operand.
//
//               Priority: EX/MEM (more recent result) is checked
//               before MEM/WB, so if BOTH the immediately-prior
//               instruction and the one before it wrote the same
//               register, the more recent value wins -- matching
//               real program order semantics.
//
//               NOTE: this alone does NOT solve the load-use
//               hazard (forwarding EX/MEM.alu_result for a load
//               would forward the computed ADDRESS, not the
//               loaded data, since the load hasn't reached MEM
//               yet). That case is caught by hazard_detection_
//               unit.v, which stalls for exactly one cycle; once
//               stalled, the load's data naturally becomes
//               available via the MEM/WB forwarding path below.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module forwarding_unit (
    input  wire [4:0] ex_rs1_addr,   // ID/EX: current EX-stage instruction's rs1
    input  wire [4:0] ex_rs2_addr,   // ID/EX: current EX-stage instruction's rs2

    input  wire [4:0] mem_rd_addr,   // EX/MEM: instruction 1 ahead (in MEM)
    input  wire       mem_reg_write, // EX/MEM: does it write a register?

    input  wire [4:0] wb_rd_addr,    // MEM/WB: instruction 2 ahead (in WB)
    input  wire       wb_reg_write,  // MEM/WB: does it write a register?

    output reg  [1:0] forward_a,     // 00=no forward 01=from MEM/WB 10=from EX/MEM
    output reg  [1:0] forward_b
);

    always @(*) begin
        // ---------------- operand A (rs1) ----------------
        if (mem_reg_write && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs1_addr))
            forward_a = 2'b10; // forward from EX/MEM (most recent)
        else if (wb_reg_write && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs1_addr))
            forward_a = 2'b01; // forward from MEM/WB
        else
            forward_a = 2'b00; // no hazard, use ID/EX.rs1_data as-is

        // ---------------- operand B (rs2) ----------------
        if (mem_reg_write && (mem_rd_addr != 5'd0) && (mem_rd_addr == ex_rs2_addr))
            forward_b = 2'b10;
        else if (wb_reg_write && (wb_rd_addr != 5'd0) && (wb_rd_addr == ex_rs2_addr))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end

endmodule
