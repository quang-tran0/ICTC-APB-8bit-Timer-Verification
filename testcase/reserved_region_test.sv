// Reserved bits and reserved addr region must read 0 and not affect others.

class reserved_region_test extends base_test;

    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "reserved_region_test";
    endfunction

    virtual task run_scenario();
        int i;
        int addr;

        $display("[%s] start", get_name());

        wait(vif.presetn == 1'b1);

        // All registers after reset
        read(8'h00);
        read(8'h01);
        read(8'h02);
        read(8'h03);

        // Write TDR (full RW), other regs must stay 0
        write(8'h02, 8'hA5);
        read (8'h02);
        read(8'h00);
        read(8'h01);
        read(8'h03);

        // Reserved addr region 0x04..0xFF
        for (i = 0; i < 20; i++) begin
            addr = 4 + ($urandom % 252);
            write(addr[7:0], $urandom);
            read (addr[7:0]);
        end

        // Verify main regs still intact
        read(8'h00);
        read(8'h01);
        read(8'h02);
        read(8'h03);

        $display("[%s] done", get_name());
    endtask
endclass