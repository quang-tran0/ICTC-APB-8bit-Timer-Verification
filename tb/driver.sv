class driver;
    mailbox #(packet) s2d_mb;        // nhận packet từ stimulus
    virtual dut_if dut_vif;

    event xfer_done;
    int unsigned completed;

    function new(virtual dut_if dut_vif, mailbox #(packet) s2d_mb, event xfer_done);
        this.dut_vif = dut_vif;
        this.s2d_mb = s2d_mb;
        this.xfer_done = xfer_done;

        this.completed = 0;
    endfunction

    task run();
        packet pkt;
        forever begin
            s2d_mb.get(pkt);
            @(posedge dut_vif.pclk);

            // prepare transaction
            $display("%0t: [driver] Driving transaction (addr=%02h data=%02h transfer=%s)", $time, pkt.addr, pkt.data, (pkt.transfer==packet::READ)?"READ":"WRITE");
            dut_vif.paddr = pkt.addr;
            dut_vif.pwrite = pkt.transfer;
            dut_vif.psel = 1'b1;
            dut_vif.penable = 1'b0;
            if (pkt.transfer == packet::WRITE)
                dut_vif.pwdata = pkt.data;

            @(posedge dut_vif.pclk);           // giữ SETUP thêm 1 cycle

            dut_vif.penable = 1'b1;
            @(posedge dut_vif.pclk);
            while (dut_vif.pready !== 1'b1)
                @(posedge dut_vif.pclk);

            $display("%0t: [driver] Xfer done (pready=%b prdata=%02h)", $time, dut_vif.pready, dut_vif.prdata);

            idle();
            completed++;
            -> xfer_done;
        end
    endtask

    // Kéo bus về IDLE (psel=0, penable=0, paddr=0)
    task idle();
        dut_vif.psel    = 1'b0;
        dut_vif.penable = 1'b0;
        dut_vif.paddr   = 8'h00;
        dut_vif.pwdata  = 8'h00;
    endtask
endclass