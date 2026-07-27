class base_test;
    environment env;
    virtual dut_if vif;

    function new();
    endfunction

    function void build();
        env = new(vif);
        env.build();
    endfunction

    virtual task write(input bit[7:0] addr, input bit[7:0] data);
        packet pkt;
        pkt = new();
        pkt.addr     = addr;
        pkt.data     = data;
        pkt.transfer = packet::WRITE;
        env.stim.send_pkt(pkt);
        @(env.xfer_done);
    endtask

    virtual task read(input bit[7:0] addr);
        packet pkt;
        pkt = new();
        pkt.addr     = addr;
        pkt.data     = 8'h00;
        pkt.transfer = packet::READ;
        env.stim.send_pkt(pkt);
        @(env.xfer_done);
    endtask

    task send_pkt(packet pkt);
        env.stim.send_pkt(pkt);
    endtask

    virtual task run_scenario();
    endtask

    virtual function string get_name();
        return "base_test";
    endfunction

    task run_test();
        build();
        fork
            env.run();
            run_scenario();
        join_none

        #100us;
        $display("%0t: [base_test] End Simulation", $time);
        report();
        $finish;
    endtask

    function void report();
        env.sb.report();
    endfunction
endclass
