class monitor;
    mailbox #(obs_packet) m2s_mb;
    virtual dut_if vif;

    function new(virtual dut_if vif, mailbox #(obs_packet) m2s_mb);
        this.vif = vif;
        this.m2s_mb = m2s_mb;
    endfunction

    task run();
        obs_packet obs;
        forever begin
            @(posedge vif.pclk);
            #1;

            obs = new();
            obs.psel      = vif.psel;
            obs.penable   = vif.penable;
            obs.pwrite    = vif.pwrite;
            obs.paddr     = vif.paddr;
            obs.pwdata    = vif.pwdata;
            obs.prdata    = vif.prdata;
            obs.pready    = vif.pready;
            obs.interrupt = vif.interrupt;

            m2s_mb.put(obs);
        end
    endtask
endclass