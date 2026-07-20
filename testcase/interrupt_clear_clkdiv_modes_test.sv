// W1C clears both interrupt sources at every supported clock divisor.

class interrupt_clear_clkdiv_base_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function bit [1:0] get_clkdiv();
        return 2'b00;
    endfunction

    task trigger_and_clear(bit underflow);
        bit [1:0] clkdiv;
        bit [7:0] status_mask;
        bit [7:0] tdr;

        clkdiv      = get_clkdiv();
        status_mask = underflow ? 8'h02 : 8'h01;
        tdr         = underflow ? 8'h02 : 8'hFD;

        write(8'h03, status_mask);
        write(8'h02, tdr);
        write(8'h00, {3'b000, clkdiv, 1'b1, underflow, 1'b1});
        write(8'h00, {3'b000, clkdiv, 1'b0, underflow, 1'b1});

        wait_interrupt_high(256);
        write(8'h00, {3'b000, clkdiv, 1'b0, underflow, 1'b0});
        wait_pclk(3);
        read(8'h01);
        env.sb.check_interrupt(vif.interrupt);

        write(8'h01, status_mask);
        wait_pclk(3);
        read(8'h01);
        env.sb.check_interrupt(vif.interrupt);
    endtask

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        trigger_and_clear(1'b0);

        toggle_reset(2, 4);
        env.sb.hard_reset();

        trigger_and_clear(1'b1);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass

class interrupt_clear_no_divide_test extends interrupt_clear_clkdiv_base_test;
    virtual function string get_name();
        return "interrupt_clear_no_divide_test";
    endfunction
endclass

class interrupt_clear_by2_test extends interrupt_clear_clkdiv_base_test;
    virtual function string get_name();
        return "interrupt_clear_by2_test";
    endfunction

    virtual function bit [1:0] get_clkdiv();
        return 2'b01;
    endfunction
endclass

class interrupt_clear_by4_test extends interrupt_clear_clkdiv_base_test;
    virtual function string get_name();
        return "interrupt_clear_by4_test";
    endfunction

    virtual function bit [1:0] get_clkdiv();
        return 2'b10;
    endfunction
endclass

class interrupt_clear_by8_test extends interrupt_clear_clkdiv_base_test;
    virtual function string get_name();
        return "interrupt_clear_by8_test";
    endfunction

    virtual function bit [1:0] get_clkdiv();
        return 2'b11;
    endfunction
endclass
