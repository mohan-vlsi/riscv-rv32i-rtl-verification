//=============================================================
// Module      : hazard_detection
// Project     : RV32I 5-Stage Pipelined Processor (Phase 3)
// Description : Detects the load-use hazard: the instruction
//               currently in EX is a LOAD (ID/EX.mem_read=1),
//               and the instruction currently in ID (about to
//               enter EX next) reads the register that load will
//               write. Forwarding alone cannot fix this -- the
//               load's data isn't available until it reaches
//               MEM, one cycle later than a normal ALU result.
//
//               When stall=1, the top-level module must, on the
//               next clock edge:
//                 - hold the PC at its current value
//                 - hold IF/ID at its current value (replay the
//                   same fetched instruction)
//                 - force a bubble (all control signals = 0)
//                   into ID/EX instead of the real decode
//               exactly one such stall resolves the hazard, since
//               by the time the dependent instruction reaches EX
//               again, the load will be sitting in MEM/WB with
//               valid data, reachable via forwarding_unit.v's
//               normal MEM/WB forwarding path.
// Standard    : Synthesizable Verilog-2001
//=============================================================

module hazard_detection (
    input  wire       ex_mem_read,   // ID/EX.mem_read: EX-stage instr is a load
    input  wire [4:0] ex_rd_addr,    // ID/EX.rd_addr:  that load's destination

    input  wire [4:0] id_rs1_addr,   // IF/ID-derived: ID-stage instr's rs1
    input  wire [4:0] id_rs2_addr,   // IF/ID-derived: ID-stage instr's rs2

    output wire       stall
);

    assign stall = ex_mem_read &&
                   (ex_rd_addr != 5'd0) &&
                   ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

endmodule
