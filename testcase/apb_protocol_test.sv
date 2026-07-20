class apb_phase_base_test extends base_test;
    function new();
        super.new();
    endfunction

    function void check_prdata_zero(string phase);
        if (vif.prdata !== 8'h00)
            $error("%0t: [%s] PRDATA active during %s: %02h",
                   $time, get_name(), phase, vif.prdata);
    endfunction

    task release_bus();
        @(negedge vif.pclk);
        vif.psel              = 1'b0;
        vif.penable           = 1'b0;
        vif.pwrite            = 1'b0;
        vif.paddr             = 8'h00;
        vif.pwdata            = 8'h00;
        vif.allow_invalid_apb = 1'b0;
        wait_pclk(1);
    endtask
endclass

class apb_write_idle_no_select_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_write_idle_no_select_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        write(8'h02, 8'h3C);
        @(negedge vif.pclk);
        vif.paddr = 8'h02; vif.pwdata = 8'h99; vif.pwrite = 1'b1;
        vif.psel = 1'b0; vif.penable = 1'b0;
        wait_pclk(2);
        release_bus();
        read(8'h02);
    endtask
endclass

class apb_write_penable_without_psel_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_write_penable_without_psel_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        write(8'h02, 8'h3C);
        @(negedge vif.pclk);
        vif.allow_invalid_apb = 1'b1;
        vif.paddr = 8'h02; vif.pwdata = 8'h99; vif.pwrite = 1'b1;
        vif.psel = 1'b0; vif.penable = 1'b1;
        wait_pclk(2);
        check_prdata_zero("WRITE with PENABLE=1/PSEL=0");
        release_bus();
        read(8'h02);
    endtask
endclass

class apb_write_setup_no_access_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_write_setup_no_access_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        write(8'h02, 8'h3C);
        @(negedge vif.pclk);
        vif.paddr = 8'h02; vif.pwdata = 8'h77; vif.pwrite = 1'b1;
        vif.psel = 1'b1; vif.penable = 1'b0;
        wait_pclk(2);
        check_prdata_zero("WRITE SETUP without ACCESS");
        release_bus();
        read(8'h02);
    endtask
endclass

class apb_write_access_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_write_access_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        write(8'h02, 8'hA5);
        read(8'h02);
    endtask
endclass

class apb_read_idle_no_select_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_read_idle_no_select_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        @(negedge vif.pclk);
        vif.paddr = 8'h02; vif.pwrite = 1'b0;
        vif.psel = 1'b0; vif.penable = 1'b0;
        #1;
        check_prdata_zero("READ IDLE without PSEL");
        release_bus();
    endtask
endclass

class apb_read_penable_without_psel_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_read_penable_without_psel_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        @(negedge vif.pclk);
        vif.allow_invalid_apb = 1'b1;
        vif.paddr = 8'h02; vif.pwrite = 1'b0;
        vif.psel = 1'b0; vif.penable = 1'b1;
        #1;
        check_prdata_zero("READ with PENABLE=1/PSEL=0");
        wait_pclk(2);
        release_bus();
    endtask
endclass

class apb_read_setup_prdata_early_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_read_setup_prdata_early_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        write(8'h02, 8'h5A);
        @(negedge vif.pclk);
        vif.paddr = 8'h02; vif.pwrite = 1'b0;
        vif.psel = 1'b1; vif.penable = 1'b0;
        #1;
        check_prdata_zero("READ SETUP");
        wait_pclk(1);
        release_bus();
    endtask
endclass

class apb_read_access_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_read_access_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);
        write(8'h02, 8'h5A);
        read(8'h02);
    endtask
endclass

class apb_write_access_prdata_active_test extends apb_phase_base_test;
    virtual function string get_name();
        return "apb_write_access_prdata_active_test";
    endfunction

    virtual task run_scenario();
        wait(vif.presetn == 1'b1);

        @(negedge vif.pclk);
        vif.paddr = 8'h02; vif.pwdata = 8'hC3; vif.pwrite = 1'b1;
        vif.psel = 1'b1; vif.penable = 1'b0;
        #1;
        check_prdata_zero("WRITE SETUP");

        @(negedge vif.pclk);
        vif.penable = 1'b1;
        @(posedge vif.pclk);
        #1;
        check_prdata_zero("WRITE ACCESS");

        release_bus();
        read(8'h02);
    endtask
endclass
