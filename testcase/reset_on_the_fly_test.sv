// Async reset while running clears all registers, counter and interrupt.

class reset_on_the_fly_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "reset_on_the_fly_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h03, 8'h03);
        write(8'h02, 8'hAA);
        write(8'h00, 8'b000_00_1_0_1);
        write(8'h00, 8'b000_00_0_0_1);
        wait_ker(25);

        toggle_reset(2, 4);
        env.sb.hard_reset();

        read(8'h00);
        read(8'h01);
        read(8'h02);
        read(8'h03);
        wait_pclk(2);
        env.sb.check_interrupt(vif.interrupt);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
