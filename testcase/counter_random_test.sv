class counter_random_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "counter_random_test";
    endfunction

    virtual task run_scenario();
        int i;
        counter_rand_cfg cfg;

        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        cfg = new();
        for (i = 0; i < 12; i++) begin
            assert(cfg.randomize())
                else $error("%0t: [%s] randomize failed", $time, get_name());

            $display("%0t: [%s] run %0d: clkdiv=%0d count_down=%0b tdr=8'h%02h ticks=%0d",
                     $time, get_name(), i, cfg.clkdiv, cfg.count_down, cfg.tdr, cfg.ticks);

            write(8'h02, cfg.tdr);
            write(8'h00, {3'b000, cfg.clkdiv, 1'b1, cfg.count_down, 1'b1});
            write(8'h00, {3'b000, cfg.clkdiv, 1'b0, cfg.count_down, 1'b1});
            wait_ker((cfg.ticks + 20) * cfg.kpt);
            write(8'h00, {3'b000, cfg.clkdiv, 1'b0, cfg.count_down, 1'b0});
            read(8'h01);
            write(8'h01, 8'h03);
        end

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
