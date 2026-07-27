class driver;
    mailbox #(packet) s2d_mb;        // nhận packet từ stimulus
    virtual dut_if vif;

    event xfer_done;
    int unsigned completed;

    function new(virtual dut_if vif, mailbox #(packet) s2d_mb, event xfer_done);
        this.vif = vif;
        this.s2d_mb = s2d_mb;
        this.xfer_done = xfer_done;

        this.completed = 0;
    endfunction

    task run();
        packet pkt;
        forever begin
            s2d_mb.get(pkt);
            @(posedge vif.pclk);

            // prepare transaction
            $display("%0t: [driver] Driving transaction (addr=8'h%02h data=8'h%02h transfer=%s)", $time, pkt.addr, pkt.data, (pkt.transfer==packet::READ)?"READ":"WRITE");
            vif.paddr = pkt.addr;
            vif.pwrite = pkt.transfer;
            vif.psel = 1'b1;
            vif.penable = 1'b0;
            if (pkt.transfer == packet::WRITE)
                vif.pwdata = pkt.data;

            @(posedge vif.pclk);           // giữ SETUP thêm 1 cycle

            vif.penable = 1'b1;
            @(posedge vif.pclk);
            while (vif.pready !== 1'b1)
                @(posedge vif.pclk);

            $display("%0t: [driver] Xfer done (pready=%b prdata=8'h%02h)", $time, vif.pready, vif.prdata);

            -> xfer_done;
            idle();
            completed++;
        end
    endtask

    // Kéo bus về IDLE (psel=0, penable=0, paddr=0)
    task idle();
        vif.psel    = 1'b0;
        vif.penable = 1'b0;
        vif.paddr   = 8'h00;
        vif.pwdata  = 8'h00;
    endtask
endclass