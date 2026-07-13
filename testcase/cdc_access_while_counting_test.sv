// Register access while the counter runs at each clk_div (CDC).

class cdc_access_while_counting_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "cdc_access_while_counting_test";
    endfunction

    task run_clkdiv(bit [1:0] clkdiv);
        int j;
        bit [7:0] a;

        write(8'h02, 8'h20);
        write(8'h00, {3'b000, clkdiv, 1'b1, 1'b0, 1'b1});
        write(8'h00, {3'b000, clkdiv, 1'b0, 1'b0, 1'b1});

        for (j = 0; j < 12; j++) begin
            case ($urandom % 3)
                0: read (8'h00);
                1: read (8'h03);
                default: write(8'h03, $urandom & 8'h03);
            endcase
        end

        write(8'h00, {3'b000, clkdiv, 1'b0, 1'b0, 1'b0});
        read(8'h01);
        write(8'h01, 8'h03);
        write(8'h03, 8'h00);
    endtask

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        run_clkdiv(2'b00);
        run_clkdiv(2'b01);
        run_clkdiv(2'b10);
        run_clkdiv(2'b11);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
