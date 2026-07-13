// Overflow/underflow interrupt at each clk_div ratio.

class interrupt_clkdiv_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "interrupt_clkdiv_test";
    endfunction

    task run_one(bit [1:0] clkdiv, int unsigned wait_n);
        write(8'h03, 8'h01);
        write(8'h02, 8'hFC);
        write(8'h00, {3'b000, clkdiv, 1'b1, 1'b0, 1'b1});
        write(8'h00, {3'b000, clkdiv, 1'b0, 1'b0, 1'b1});
        wait_ker(wait_n);
        write(8'h00, {3'b000, clkdiv, 1'b0, 1'b0, 1'b0});
        wait_pclk(3);
        env.sb.check_interrupt(vif.interrupt);
        read(8'h01);
        write(8'h01, 8'h01);
        wait_pclk(2);

        write(8'h03, 8'h02);
        write(8'h02, 8'h03);
        write(8'h00, {3'b000, clkdiv, 1'b1, 1'b1, 1'b1});
        write(8'h00, {3'b000, clkdiv, 1'b0, 1'b1, 1'b1});
        wait_ker(wait_n);
        write(8'h00, {3'b000, clkdiv, 1'b0, 1'b1, 1'b0});
        wait_pclk(3);
        env.sb.check_interrupt(vif.interrupt);
        read(8'h01);
        write(8'h01, 8'h02);
        wait_pclk(2);
    endtask

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        run_one(2'b01, 40);
        run_one(2'b10, 70);
        run_one(2'b11, 120);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
