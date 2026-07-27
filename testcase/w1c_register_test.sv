// W1C: SW write 1 to TSR must not set the bit (it can only clear).

class w1c_register_test extends base_test;

    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "w1c_register_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        $display("[%s] start", get_name());

        // SW cannot set TSR by writing 1
        write(8'h01, 8'h03);
        read (8'h01);

        // Write 0's: nothing changes
        write(8'h01, 8'h00);
        read (8'h01);

        // Write all-1's: reserved bits [7:2] stay 0
        write(8'h01, 8'hFF);
        read (8'h01);

        $display("[%s] done", get_name());
    endtask
endclass