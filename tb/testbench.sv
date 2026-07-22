`timescale 1ns/1ps

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
        d_if.pclk = 1'b0;
        d_if.ker_clk = 1'b0;
        d_if.presetn = 1'b0;
        d_if.psel = 1'b0;
        d_if.penable = 1'b0;
        d_if.pwrite = 1'b0;
        d_if.paddr = 8'h00;
        d_if.pwdata = 8'h00;

        $display("hello world");
        #10ns;
        $finish;
    end

endmodule
