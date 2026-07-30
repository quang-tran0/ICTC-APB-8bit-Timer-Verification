// Reserved bits (TCR[7:5], TSR[7:2], TIE[7:2]) and reserved addr region
// 0x04..0xFF must read 0 and their writes must not affect other registers.

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

        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        read(8'h00);
        read(8'h01);
        read(8'h02);
        read(8'h03);

        // Reserved bits inside each register must not be stored
        write(8'h00, 8'hE0);
        read (8'h00);
        write(8'h03, 8'hFC);
        read (8'h03);
        write(8'h01, 8'hFF);
        read (8'h01);

        // A real RW write must stick, others stay 0
        write(8'h02, 8'hA5);
        read (8'h02);
        read (8'h00);
        read (8'h01);
        read (8'h03);

        // Reserved address region 0x04..0xFF
        for (i = 0; i < 20; i++) begin
            addr = 4 + ($urandom % 252);
            write(addr[7:0], $urandom);
            read (addr[7:0]);
        end

        read(8'h00);
        read(8'h01);
        read(8'h02);
        read(8'h03);

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
