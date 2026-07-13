// clk_div=10: counter advances every 4 ker_clk.

class clkdiv_by4_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "clkdiv_by4_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h02, 8'hF0);
        write(8'h00, 8'b000_10_1_0_1);
        write(8'h00, 8'b000_10_0_0_1);

        wait_ker(8);
        read(8'h01);

        wait_ker(120);
        write(8'h00, 8'b000_10_0_0_0);
        read(8'h01);
        write(8'h01, 8'h01);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
