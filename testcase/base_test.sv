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

    virtual task wait_ker(input int unsigned n);
        repeat (n) @(posedge vif.ker_clk);
    endtask

    virtual task wait_pclk(input int unsigned n);
        repeat (n) @(posedge vif.pclk);
    endtask

    // Wait for interrupt level high (returns immediately if already high)
    virtual task wait_interrupt_high(input int unsigned timeout_cycles = 1024);
        int cyc;
        for (cyc = 0; cyc < timeout_cycles; cyc++) begin
            if (vif.interrupt == 1'b1) return;
            @(posedge vif.pclk);
        end
        $display("%0t: [%s] WARNING: interrupt not high in %0d pclk",
                 $time, get_name(), timeout_cycles);
    endtask

    // Wait for a fresh 0->1 edge of interrupt
    virtual task wait_interrupt_rise(input int unsigned timeout_cycles = 1024);
        while (vif.interrupt == 1'b1) @(posedge vif.pclk);
        repeat (timeout_cycles) begin
            @(posedge vif.pclk);
            if (vif.interrupt == 1'b1) return;
        end
        $display("%0t: [%s] WARNING: interrupt did not rise in %0d pclk",
                 $time, get_name(), timeout_cycles);
    endtask

    // Async reset pulse; caller must resync the scoreboard via hard_reset()
    virtual task toggle_reset(input int unsigned low_cycles   = 1,
                              input int unsigned settle_cycles = 2);
        vif.presetn = 1'b0;
        repeat (low_cycles) @(posedge vif.pclk);
        vif.presetn = 1'b1;
        repeat (settle_cycles) @(posedge vif.pclk);
    endtask
endclass
