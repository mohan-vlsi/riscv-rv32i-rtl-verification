class cpu_transaction;

    rand bit [31:0] next_pc;

    bit [31:0] current_pc;

    function void display();

        $display("---------------------------");
        $display("Current PC : %h",current_pc);
        $display("Next PC    : %h",next_pc);
        $display("---------------------------");

    endfunction

endclass
