// Underflow rollover 0->255 sets TSR.underflow.

class counter_underflow_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "counter_underflow_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h02, 8'h02);
        write(8'h00, 8'b000_00_1_1_1);
        write(8'h00, 8'b000_00_0_1_1);
        wait_ker(8);
        write(8'h00, 8'b000_00_0_1_0);
        read(8'h01);
        write(8'h01, 8'h02);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
