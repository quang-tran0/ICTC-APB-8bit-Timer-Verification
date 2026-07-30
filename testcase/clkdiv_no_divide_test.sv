// clk_div = 00: clk_in = ker_clk, counter advances once per ker_clk edge.

class clkdiv_no_divide_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "clkdiv_no_divide_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        // Preload near overflow, load and start with clkdiv=00
        write(8'h02, 8'hFD);
        write(8'h00, 8'b00000_101);
        write(8'h00, 8'b00000_001);
        wait_ker(8);

        read(8'h01);

        // Stop and clear
        write(8'h00, 8'b00000_000);
        write(8'h01, 8'b00000001);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
