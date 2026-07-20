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
        bit [7:0] expected;
        bit [7:0] status_mask;
        int unsigned ticks;
        int unsigned i;
        time ker_t0, ker_period, clk_t0, clk_period;

        wait(vif.presetn == 1'b1);
        clkdiv      = get_clkdiv();
        count_down  = get_count_down();
        start_value = choose_start_value();
        status_mask = count_down ? 8'h02 : 8'h01;
        ticks       = count_down ? (int'(start_value) + 1)
                                 : (256 - int'(start_value));

        write(8'h01, 8'h03);
        write(8'h02, start_value);
        write(8'h00, {3'b000, clkdiv, 1'b1, count_down, 1'b0});

        // Measure clk_in while load holds the counter, then check the divisor.
        @(posedge vif.ker_clk); ker_t0 = $time;
        @(posedge vif.ker_clk); ker_period = $time - ker_t0;
        @(posedge vif.clk_in);  clk_t0 = $time;
        @(posedge vif.clk_in);  clk_period = $time - clk_t0;
        if (clk_period != ker_period * (1 << clkdiv))
            $error("%0t: [%s] clock period mismatch got=%0t expected=%0t",
                   $time, get_name(), clk_period,
                   ker_period * (1 << clkdiv));
        #1;
        if (vif.counter !== start_value)
            $error("%0t: [%s] load mismatch got=%02h expected=%02h",
                   $time, get_name(), vif.counter, start_value);

        write(8'h00, {3'b000, clkdiv, 1'b0, count_down, 1'b1});
        expected = start_value;
        for (i = 0; i < ticks; i++) begin
            @(posedge vif.clk_in);
            #1;
            expected = count_down ? expected - 8'd1 : expected + 8'd1;
            if (vif.counter !== expected)
                $error("%0t: [%s] counter mismatch tick=%0d got=%02h expected=%02h",
                       $time, get_name(), i + 1, vif.counter, expected);
        end

        write(8'h00, {3'b000, clkdiv, 1'b0, count_down, 1'b0});
        wait_pclk(3);
        read(8'h01);
        write(8'h01, status_mask);
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
