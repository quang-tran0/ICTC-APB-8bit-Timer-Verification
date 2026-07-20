package test_pkg;
    import timer_pkg::*;
    `include "base_test.sv"

    // Register test
    `include "default_value_register_test.sv"
    `include "rw_register_test.sv"
    `include "reserved_region_test.sv"
    `include "w1c_register_test.sv"
    `include "reset_on_the_fly_test.sv"
    `include "apb_protocol_test.sv"
    `include "cdc_access_while_counting_test.sv"
    `include "random_register_test.sv"

    // Clock divisor test
    `include "clkdiv_matrix_test.sv"
    `include "clkdiv_reconfig_test.sv"

    // Counter test
    `include "count_up_test.sv"
    `include "count_down_test.sv"
    `include "load_counter_test.sv"
    `include "load_on_the_fly_test.sv"
    `include "load_hold_test.sv"
    `include "timer_enable_disable_test.sv"
    `include "counter_overflow_test.sv"
    `include "counter_underflow_test.sv"
    `include "count_direction_change_test.sv"
    `include "continuous_rollover_test.sv"
    `include "counter_random_test.sv"

    // Interrupt test
    `include "overflow_interrupt_test.sv"
    `include "underflow_interrupt_test.sv"
    `include "polling_mode_test.sv"
    `include "interrupt_clear_test.sv"
    `include "interrupt_clear_clkdiv_modes_test.sv"
    `include "interrupt_late_enable_test.sv"
    `include "interrupt_both_source_test.sv"
    `include "interrupt_mask_source_cross_test.sv"
    `include "status_set_clear_race_test.sv"
    `include "interrupt_clkdiv_test.sv"

    `include "test_factory.sv"
endpackage
