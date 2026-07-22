class base_test;
    environment env;
    virtual dut_if vif;

    function new(virtual dut_if vif);
    endfunction

    function void build();
        env = new(vif);
        env.build();
    endfunction

    task send_pkt(packet pkt);
        env.stim.send_pkt(pkt);
    endtask

    virtual task run_scenario();
    endtask

    task run();
        build();
        fork
            env.run();
            run_scenario();
        join_any

        #100us;
        $display("%0t: [base_test] End Simulation", $time);
        $finish;
    endtask
endclass