// HW status-set has priority over SW W1C clear; no event lost.

class status_set_clear_race_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "status_set_clear_race_test";
    endfunction

    virtual task run_scenario();
        int i;
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h03, 8'h01);
        write(8'h02, 8'hF0);
        write(8'h00, 8'b000_00_1_0_1);
        write(8'h00, 8'b000_00_0_0_1);

        for (i = 0; i < 6; i++) begin
            wait_ker(i + 1);
            write(8'h01, 8'h01);
        end

        wait_ker(300);
        write(8'h00, 8'b000_00_0_0_0);
        wait_pclk(3);
        read(8'h01);
        env.sb.check_interrupt(vif.interrupt);
        write(8'h01, 8'h01);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
