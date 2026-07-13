// Load from TDR while timer_en=0; counter starts from TDR, not 0.

class load_counter_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "load_counter_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h02, 8'hFB);
        write(8'h00, 8'b000_00_1_0_0);
        write(8'h00, 8'b000_00_0_0_1);

        wait_ker(25);
        write(8'h00, 8'b000_00_0_0_0);
        read(8'h01);
        write(8'h01, 8'h01);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
