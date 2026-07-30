// After reset, all registers should read their default value (0).

class default_value_register_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "default_value_register_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        $display("%0t: [%s] start", $time, get_name());

        read(8'h00);
        read(8'h01);
        read(8'h02);
        read(8'h03);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
