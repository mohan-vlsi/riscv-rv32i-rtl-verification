class cpu_environment;

    cpu_generator   gen;
    cpu_driver      drv;
    cpu_monitor     mon;
    cpu_scoreboard  scb;

    mailbox #(cpu_transaction) gen2drv;
    mailbox #(cpu_transaction) mon2scb;

    virtual cpu_if vif;

    function new(virtual cpu_if vif);

        this.vif = vif;

        gen2drv = new();
        mon2scb = new();

        gen = new(gen2drv);
        drv = new(vif,gen2drv);
        mon = new(vif,mon2scb);
        scb = new(mon2scb);

    endfunction

    task run();

        fork

            gen.run();

            drv.run();

            mon.run();

            scb.run();

        join

    endtask

endclass
