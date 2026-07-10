class cpu_driver;

    virtual cpu_if vif;

    mailbox #(cpu_transaction) gen2drv;

    function new(
        virtual cpu_if vif,
        mailbox #(cpu_transaction) gen2drv
    );
        this.vif     = vif;
        this.gen2drv = gen2drv;
    endfunction

    task run();

        cpu_transaction tr;

        forever begin

            gen2drv.get(tr);

            @(posedge vif.clk);

            vif.next_pc <= tr.next_pc;

        end

    endtask

endclass
