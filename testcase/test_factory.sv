class test_factory;
    static function base_test create_test(string test_name, virtual dut_if vif);
        base_test test;

        case (test_name)

            // 1. Register test
            "default_value_register_test": test = default_value_register_test::new();
            "rw_register_test":            test = rw_register_test::new();


            default: begin
                $display("[test_factory] Unknown test name: %s", test_name);
                test = null;
            end
        endcase

        return test;
    endfunction
endclass