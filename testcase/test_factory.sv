class test_factory;
    static function base_test create_test(string test_name, virtual dut_if vif);
        base_test test;

        case (test_name)
            // Register test
            "default_value_register_test":    test = default_value_register_test::new();
            "rw_register_test":               test = rw_register_test::new();
            "reserved_region_test":           test = reserved_region_test::new();
            "w1c_register_test":              test = w1c_register_test::new();
            "reset_on_the_fly_test":          test = reset_on_the_fly_test::new();
            "apb_write_idle_no_select_test": test = apb_write_idle_no_select_test::new();
            "apb_write_penable_without_psel_test": test = apb_write_penable_without_psel_test::new();
            "apb_write_setup_no_access_test": test = apb_write_setup_no_access_test::new();
            "apb_write_access_test":         test = apb_write_access_test::new();
            "apb_read_idle_no_select_test":  test = apb_read_idle_no_select_test::new();
            "apb_read_penable_without_psel_test": test = apb_read_penable_without_psel_test::new();
            "apb_read_setup_prdata_early_test": test = apb_read_setup_prdata_early_test::new();
            "apb_read_access_test":          test = apb_read_access_test::new();
            "apb_write_access_prdata_active_test": test = apb_write_access_prdata_active_test::new();
            "cdc_access_while_counting_test": test = cdc_access_while_counting_test::new();
            "random_register_test":           test = random_register_test::new();

            // Clock divisor test
            "clkdiv_no_divide_up_from0_test": test = clkdiv_no_divide_up_from0_test::new();
            "clkdiv_no_divide_down_from255_test": test = clkdiv_no_divide_down_from255_test::new();
            "clkdiv_no_divide_up_random_load_test": test = clkdiv_no_divide_up_random_load_test::new();
            "clkdiv_no_divide_down_random_load_test": test = clkdiv_no_divide_down_random_load_test::new();
            "clkdiv_by2_up_from0_test":        test = clkdiv_by2_up_from0_test::new();
            "clkdiv_by2_down_from255_test":   test = clkdiv_by2_down_from255_test::new();
            "clkdiv_by2_up_random_load_test": test = clkdiv_by2_up_random_load_test::new();
            "clkdiv_by2_down_random_load_test": test = clkdiv_by2_down_random_load_test::new();
            "clkdiv_by4_up_from0_test":        test = clkdiv_by4_up_from0_test::new();
            "clkdiv_by4_down_from255_test":   test = clkdiv_by4_down_from255_test::new();
            "clkdiv_by4_up_random_load_test": test = clkdiv_by4_up_random_load_test::new();
            "clkdiv_by4_down_random_load_test": test = clkdiv_by4_down_random_load_test::new();
            "clkdiv_by8_up_from0_test":        test = clkdiv_by8_up_from0_test::new();
            "clkdiv_by8_down_from255_test":   test = clkdiv_by8_down_from255_test::new();
            "clkdiv_by8_up_random_load_test": test = clkdiv_by8_up_random_load_test::new();
            "clkdiv_by8_down_random_load_test": test = clkdiv_by8_down_random_load_test::new();
            "clkdiv_reconfig_test":           test = clkdiv_reconfig_test::new();

            // Counter test
            "count_up_test":                  test = count_up_test::new();
            "count_down_test":                test = count_down_test::new();
            "load_counter_test":              test = load_counter_test::new();
            "load_on_the_fly_test":           test = load_on_the_fly_test::new();
            "load_hold_test":                 test = load_hold_test::new();
            "timer_enable_disable_test":      test = timer_enable_disable_test::new();
            "counter_overflow_test":          test = counter_overflow_test::new();
            "counter_underflow_test":         test = counter_underflow_test::new();
            "count_direction_change_test":    test = count_direction_change_test::new();
            "continuous_rollover_test":       test = continuous_rollover_test::new();
            "counter_random_test":            test = counter_random_test::new();

            // Interrupt test
            "overflow_interrupt_test":        test = overflow_interrupt_test::new();
            "underflow_interrupt_test":       test = underflow_interrupt_test::new();
            "polling_mode_test":              test = polling_mode_test::new();
            "interrupt_clear_test":           test = interrupt_clear_test::new();
            "interrupt_clear_no_divide_test": test = interrupt_clear_no_divide_test::new();
            "interrupt_clear_by2_test":       test = interrupt_clear_by2_test::new();
            "interrupt_clear_by4_test":       test = interrupt_clear_by4_test::new();
            "interrupt_clear_by8_test":       test = interrupt_clear_by8_test::new();
            "interrupt_late_enable_test":     test = interrupt_late_enable_test::new();
            "interrupt_both_source_test":     test = interrupt_both_source_test::new();
            "interrupt_mask_source_cross_test": test = interrupt_mask_source_cross_test::new();
            "status_set_clear_race_test":     test = status_set_clear_race_test::new();
            "interrupt_clkdiv_test":          test = interrupt_clkdiv_test::new();

            default: begin
                $display("[test_factory] Unknown test name: %s", test_name);
                test = null;
            end
        endcase

        return test;
    endfunction
endclass
