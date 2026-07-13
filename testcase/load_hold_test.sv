// Counter holds at TDR and does not count while load stays asserted.

class load_hold_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "load_hold_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h02, 8'hFC);
        write(8'h00, 8'b000_00_1_0_1);

        wait_ker(300);
        read(8'h01);

        write(8'h00, 8'b000_00_0_0_0);
        read(8'h01);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
