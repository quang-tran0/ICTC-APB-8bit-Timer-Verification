// Counter freezes while timer_en=0 and resumes from the held value.

class timer_enable_disable_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "timer_enable_disable_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h02, 8'hF0);
        write(8'h00, 8'b000_00_1_0_1);
        write(8'h00, 8'b000_00_0_0_1);
        wait_ker(6);
        write(8'h00, 8'b000_00_0_0_0);

        wait_ker(30);
        read(8'h01);

        write(8'h00, 8'b000_00_0_0_1);
        wait_ker(20);
        write(8'h00, 8'b000_00_0_0_0);
        read(8'h01);
        write(8'h01, 8'h01);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
