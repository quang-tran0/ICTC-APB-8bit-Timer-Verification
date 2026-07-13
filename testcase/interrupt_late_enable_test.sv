// Enabling interrupt while status is set asserts it (level-based).

class interrupt_late_enable_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "interrupt_late_enable_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h03, 8'h00);
        write(8'h02, 8'hFD);
        write(8'h00, 8'b000_00_1_0_1);
        write(8'h00, 8'b000_00_0_0_1);
        wait_ker(8);
        write(8'h00, 8'b000_00_0_0_0);
        wait_pclk(3);

        env.sb.check_interrupt(vif.interrupt);
        read(8'h01);

        write(8'h03, 8'h01);
        wait_pclk(3);
        env.sb.check_interrupt(vif.interrupt);

        write(8'h01, 8'h01);
        wait_pclk(3);
        env.sb.check_interrupt(vif.interrupt);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
