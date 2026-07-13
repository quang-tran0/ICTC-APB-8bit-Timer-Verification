// APB SETUP->ACCESS with pready check; psel=0 / penable=0 must not update.

class apb_protocol_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "apb_protocol_test";
    endfunction

    virtual task run_scenario();
        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        write(8'h02, 8'h3C);
        read (8'h02);
        write(8'h03, 8'h02);
        read (8'h03);

        wait_pclk(4);
        read(8'h00);

        @(posedge vif.pclk);
        vif.paddr   = 8'h02;
        vif.pwdata  = 8'h99;
        vif.pwrite  = 1'b1;
        vif.psel    = 1'b0;
        vif.penable = 1'b0;
        wait_pclk(2);
        vif.paddr = 8'h00; vif.pwdata = 8'h00; vif.pwrite = 1'b0;
        read(8'h02);

        @(posedge vif.pclk);
        vif.paddr   = 8'h02;
        vif.pwdata  = 8'h77;
        vif.pwrite  = 1'b1;
        vif.psel    = 1'b1;
        vif.penable = 1'b0;
        wait_pclk(2);
        vif.psel = 1'b0; vif.paddr = 8'h00; vif.pwdata = 8'h00; vif.pwrite = 1'b0;
        read(8'h02);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
