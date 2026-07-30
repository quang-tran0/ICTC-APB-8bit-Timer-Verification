class monitor;
    mailbox #(obs_packet) m2s_mb;
    virtual dut_if vif;
    event ker_clk_edge;

    function new(virtual dut_if vif, mailbox #(obs_packet) m2s_mb, event ker_clk_edge);
        this.vif          = vif;
        this.m2s_mb       = m2s_mb;
        this.ker_clk_edge = ker_clk_edge;
    endfunction

    task run();
        fork
            forever begin
                obs_packet obs;
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

            forever begin
                @(posedge vif.ker_clk);
                #1;
                -> ker_clk_edge;
            end
        join_none
    endtask
endclass