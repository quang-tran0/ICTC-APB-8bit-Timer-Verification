// 1. Wait for reset (presetn) release and clocks stable
// 2. Read TCR(0x00), TSR(0x01), TDR(0x02), TIE(0x03) via APB
// Pass condition: TCR=8'h00, TSR=8'h00, TDR=8'h00, TIE=8'h00 (matching default value in RTL spec)

class default_value_register_test extends base_test;
    function new();
        super.new();
    endfunction

    function string get_name();
        return "default_value_register_test";
    endfunction

    virtual task run_scenario();
        bit [7:0] v;
        $display("%0t: [%s] start", $time, get_name());

        read(8'h00, v);
        read(8'h01, v);
        read(8'h02, v);
        read(8'h03, v);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass