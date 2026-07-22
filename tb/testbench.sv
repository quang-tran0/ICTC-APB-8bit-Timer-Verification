`timescale 1ns/1ns

module testbench;
    import timer_pkg::*;
    import test_pkg::*;

    dut_if d_if();

    timer_top u_dut(
        .ker_clk(d_if.ker_clk),
        .pclk(d_if.pclk),
        .presetn(d_if.presetn),
        .psel(d_if.psel),
        .penable(d_if.penable),
        .pwrite(d_if.pwrite),
        .paddr(d_if.paddr),
        .pwdata(d_if.pwdata),
        .prdata(d_if.prdata),
        .pready(d_if.pready),
        .interrupt(d_if.interrupt));

    initial begin
        d_if.pwdata  = 0;
        d_if.psel    = 0;
        d_if.penable = 0;
        d_if.pwrite  = 0;
        d_if.presetn = 0;
        #100ns d_if.presetn = 1;
    end

    // Clock generation 50MHz for pclk and 200MHz for ker_clk
    initial begin
        d_if.pclk = 1;
        d_if.ker_clk = 1;

        forever #10ns d_if.pclk = ~d_if.pclk;
        forever #2.5ns d_if.ker_clk = ~d_if.ker_clk;
    end

    initial begin
        #100us;
        $display("%0t: [testbench] Simulation timeout", $time);
        $finish;
    end

    initial begin
        environment env;
        packet pkt;
        env = new(d_if);
        pkt = new();
        pkt.addr = 8'h00;
        pkt.data = 8'hAA;
        pkt.transfer = packet::WRITE;

        env.build();
        env.stim.send_pkt(pkt);
        env.run();
    end

endmodule
