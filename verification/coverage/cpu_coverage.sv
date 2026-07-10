class cpu_coverage;

    logic [6:0] opcode;

    covergroup instruction_cg;

        opcode_cp : coverpoint opcode
        {
            bins R_TYPE = {7'b0110011};
            bins I_TYPE = {7'b0010011};
            bins LOAD   = {7'b0000011};
            bins STORE  = {7'b0100011};
            bins BRANCH = {7'b1100011};
        }

    endgroup

    function new();

        instruction_cg = new();

    endfunction

endclass
