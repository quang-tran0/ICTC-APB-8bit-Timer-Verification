class stimulus;
    mailbox #(packet) s2d_mb;
    packet pkt_q[$];
    int unsigned in_flight;

    function new(mailbox #(packet) s2d_mb);
        this.s2d_mb = s2d_mb;
        this.in_flight = 0;
    endfunction

    task send_pkt(packet pkt);
        pkt_q.push_back(pkt);
        in_flight++;
    endtask

    task run();
        packet pkt;
        forever begin
            wait(pkt_q.size() > 0);
            pkt = pkt_q.pop_front();
            s2d_mb.put(pkt);
            $display("%0t: [stimulus] Sent packet to driver (in_flight=%0d)", $time, in_flight);
        end
    endtask

    // Wait until every packet the test queued has been picked up by the driver
    task wait_done();
        wait(pkt_q.size() == 0);
    endtask
endclass
