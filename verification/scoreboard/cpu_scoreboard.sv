class cpu_scoreboard;

    mailbox #(cpu_transaction) mon2scb;

    function new(
        mailbox #(cpu_transaction) mon2scb
    );

        this.mon2scb = mon2scb;

    endfunction

    task run();

        cpu_transaction tr;

        forever begin

            mon2scb.get(tr);

            if(tr.current_pc[1:0] != 2'b00)
                $error("PC Alignment Error : %h",tr.current_pc);

            else
                $display("PASS : PC = %h",tr.current_pc);

        end

    endtask

endclass
