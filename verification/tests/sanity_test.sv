class sanity_test;

    cpu_environment env;

    function new(cpu_environment env);

        this.env = env;

    endfunction

    task run();

        $display("--------------------------------");

        $display("Running Sanity Test");

        $display("--------------------------------");

        env.run();

    endtask

endclass
