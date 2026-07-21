class clkdiv_matrix_base_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function bit [1:0] get_clkdiv();
        return 2'b00;
    endfunction

    virtual function bit get_count_down();
        return 1'b0;
    endfunction

    virtual function bit get_random_start();
        return 1'b0;
    endfunction

    function bit [7:0] choose_start_value();
        if (!get_random_start())
            return get_count_down() ? 8'hFF : 8'h00;
        return get_count_down() ? $urandom_range(8'h20, 8'h08)
                                : $urandom_range(8'hF8, 8'hE0);
    endfunction

    virtual task run_scenario();
        bit [1:0] clkdiv;
        bit       count_down;
        bit [7:0] start_value;
        bit [7:0] status_mask;
        int unsigned ticks;
        int unsigned divider;
        int unsigned no_irq_cycles;

        wait(vif.presetn == 1'b1);
        clkdiv      = get_clkdiv();
        count_down  = get_count_down();
        start_value = choose_start_value();
        status_mask = count_down ? 8'h02 : 8'h01;
        ticks       = count_down ? (int'(start_value) + 1)
                                 : (256 - int'(start_value));
        divider     = 1 << clkdiv;

        write(8'h01, 8'h03);
        write(8'h03, status_mask);
        write(8'h02, start_value);
        write(8'h00, {3'b000, clkdiv, 1'b1, count_down, 1'b0});

        // Allow at least one divided-clock edge to load TDR. The counter and
        // divided clock are DUT-internal, so verify them through public status
        // and interrupt behavior instead of hierarchical verification taps.
        wait_ker(2 * divider);
        if (vif.interrupt !== 1'b0)
            $error("%0t: [%s] interrupt asserted while load is held",
                   $time, get_name());
        read(8'h01);

        write(8'h00, {3'b000, clkdiv, 1'b0, count_down, 1'b1});
        no_irq_cycles = (ticks > 1) ? (ticks - 1) * divider : 0;
        wait_ker(no_irq_cycles);
        if (vif.interrupt !== 1'b0)
            $error("%0t: [%s] interrupt asserted before expected rollover",
                   $time, get_name());

        wait_interrupt_high(8);
        if (vif.interrupt !== 1'b1)
            $error("%0t: [%s] interrupt missing at expected rollover",
                   $time, get_name());

        write(8'h00, {3'b000, clkdiv, 1'b0, count_down, 1'b0});
        read(8'h01);
        write(8'h01, status_mask);
        write(8'h03, 8'h00);
    endtask
endclass

`define CLKDIV_MATRIX_TEST(CLASS_NAME, TEST_NAME, DIV_VALUE, DOWN_VALUE, RANDOM_VALUE) \
class CLASS_NAME extends clkdiv_matrix_base_test; \
    virtual function string get_name(); return TEST_NAME; endfunction \
    virtual function bit [1:0] get_clkdiv(); return DIV_VALUE; endfunction \
    virtual function bit get_count_down(); return DOWN_VALUE; endfunction \
    virtual function bit get_random_start(); return RANDOM_VALUE; endfunction \
endclass

`CLKDIV_MATRIX_TEST(clkdiv_no_divide_up_from0_test,
                    "clkdiv_no_divide_up_from0_test", 2'b00, 1'b0, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_no_divide_down_from255_test,
                    "clkdiv_no_divide_down_from255_test", 2'b00, 1'b1, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_no_divide_up_random_load_test,
                    "clkdiv_no_divide_up_random_load_test", 2'b00, 1'b0, 1'b1)
`CLKDIV_MATRIX_TEST(clkdiv_no_divide_down_random_load_test,
                    "clkdiv_no_divide_down_random_load_test", 2'b00, 1'b1, 1'b1)

`CLKDIV_MATRIX_TEST(clkdiv_by2_up_from0_test,
                    "clkdiv_by2_up_from0_test", 2'b01, 1'b0, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_by2_down_from255_test,
                    "clkdiv_by2_down_from255_test", 2'b01, 1'b1, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_by2_up_random_load_test,
                    "clkdiv_by2_up_random_load_test", 2'b01, 1'b0, 1'b1)
`CLKDIV_MATRIX_TEST(clkdiv_by2_down_random_load_test,
                    "clkdiv_by2_down_random_load_test", 2'b01, 1'b1, 1'b1)

`CLKDIV_MATRIX_TEST(clkdiv_by4_up_from0_test,
                    "clkdiv_by4_up_from0_test", 2'b10, 1'b0, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_by4_down_from255_test,
                    "clkdiv_by4_down_from255_test", 2'b10, 1'b1, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_by4_up_random_load_test,
                    "clkdiv_by4_up_random_load_test", 2'b10, 1'b0, 1'b1)
`CLKDIV_MATRIX_TEST(clkdiv_by4_down_random_load_test,
                    "clkdiv_by4_down_random_load_test", 2'b10, 1'b1, 1'b1)

`CLKDIV_MATRIX_TEST(clkdiv_by8_up_from0_test,
                    "clkdiv_by8_up_from0_test", 2'b11, 1'b0, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_by8_down_from255_test,
                    "clkdiv_by8_down_from255_test", 2'b11, 1'b1, 1'b0)
`CLKDIV_MATRIX_TEST(clkdiv_by8_up_random_load_test,
                    "clkdiv_by8_up_random_load_test", 2'b11, 1'b0, 1'b1)
`CLKDIV_MATRIX_TEST(clkdiv_by8_down_random_load_test,
                    "clkdiv_by8_down_random_load_test", 2'b11, 1'b1, 1'b1)

`undef CLKDIV_MATRIX_TEST
