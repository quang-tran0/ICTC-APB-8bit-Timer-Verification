// TSR is W1C: HW sets overflow/underflow, write 1 clears, write 0 keeps,
// SW cannot set a cleared bit by writing 1.

class w1c_register_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "w1c_register_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        // Enable overflow interrupt, preload near overflow, start counting
        write(8'h03, 8'b00000001);
        write(8'h02, 8'd253);
        write(8'h00, 8'b00000_101);
        write(8'h00, 8'b00000_001);
        wait_ker(8);

        read(8'h01);

        // Write 0 must not clear
        write(8'h01, 8'b00000000);
        read(8'h01);

        // Stop timer, then write 1 clears
        write(8'h00, 8'b00000_000);
        write(8'h01, 8'b00000001);
        read(8'h01);

        // Write 1 to a cleared bit must not set it
        write(8'h01, 8'b00000001);
        read(8'h01);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
