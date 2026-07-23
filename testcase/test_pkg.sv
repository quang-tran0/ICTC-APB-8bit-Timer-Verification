package test_pkg;
    import timer_pkg::*;
    `include "base_test.sv"

    // 1. Register test
    `include "default_value_register_test.sv"

    `include "test_factory.sv"
endpackage