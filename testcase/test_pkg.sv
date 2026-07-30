package test_pkg;
    import timer_pkg::*;
    `include "base_test.sv"

    // Register test
    `include "default_value_register_test.sv"
    `include "rw_register_test.sv"
    `include "reserved_region_test.sv"
    `include "w1c_register_test.sv"

    // Clock divisor test
    `include "clkdiv_no_divide_test.sv"

    `include "test_factory.sv"
endpackage