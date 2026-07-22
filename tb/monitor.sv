class monitor;
    mailbox #(packet) m2s_mb;        // gửi packet đến scoreboard
    virtual dut_if vif;
    event xfer_done;

    function new(virtual dut_if vif, mailbox #(packet) m2s_mb, event xfer_done);
        this.vif = vif;
        this.m2s_mb = m2s_mb;
        this.xfer_done = xfer_done;
    endfunction

    task run();
        packet obs_pkt;
        forever begin
            @(xfer_done);
            $display("%0t: [monitor] Observing transaction (paddr=%02h prdata=%02h pwdata=%02h pwrite=%b psel=%b penable=%b pready=%b)", $time, vif.paddr, vif.prdata, vif.pwdata, vif.pwrite, vif.psel, vif.penable, vif.pready);
            obs_pkt = new();
            obs_pkt.obs_paddr  = vif.paddr;
            obs_pkt.obs_prdata = vif.prdata;
            obs_pkt.obs_pwdata = vif.pwdata;
            obs_pkt.obs_pwrite = vif.pwrite;
            obs_pkt.obs_psel   = vif.psel;
            obs_pkt.obs_penable= vif.penable;
            obs_pkt.obs_pready = vif.pready;

            m2s_mb.put(obs_pkt);
        end
    endtask

endclass