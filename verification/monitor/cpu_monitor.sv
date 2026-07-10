class cpu_monitor;

    virtual cpu_if vif;

    mailbox #(cpu_transaction) mon2scb;

    function new(
        virtual cpu_if vif,
        mailbox #(cpu_transaction) mon2scb
    );
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();

        cpu_transaction tr;

        forever begin

            @(posedge vif.clk);

            tr = new();

            tr.current_pc = vif.pc;

            mon2scb.put(tr);

        end

    endtask

endclass
