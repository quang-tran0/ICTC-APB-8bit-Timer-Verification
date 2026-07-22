class environment;
    mailbox #(packet) m2s_mb;
    mailbox #(packet) s2d_mb;

    virtual dut_if vif;

    stimulus stim;
    driver drv;
    monitor mon;
    scoreboard sb;

    function new(virtual dut_if vif);
        this.vif = vif;
    endfunction

    function void build();
        $display("%0t: [environment] Building environment", $time);
        m2s_mb = new();
        s2d_mb = new();

        stim = new(s2d_mb);
        drv = new(vif, m2s_mb);
        mon = new(vif, s2d_mb);
        sb = new(m2s_mb);
    endfunction

    task run();
        $display("%0t: [environment] Running environment", $time);
        fork
            stim.start();
            drv.start();
            mon.start();
            sb.start();
        join_none
    endtask
endclass