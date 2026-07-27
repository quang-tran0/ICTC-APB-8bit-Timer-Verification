// Walk through every RW bit and random patterns across TCR/TDR/TIE.

class rw_register_test extends base_test;
    function new();
        super.new();
    endfunction

    function string get_name();
        return "rw_register_test";
    endfunction

    virtual task run_scenario();
        int i;
        bit [7:0] pat;

        wait(vif.presetn == 1'b1);
        $display("[%s] start", get_name());

        // TCR [4:0] walking-1
        for (i = 0; i < 5; i++) begin
            pat = 8'h00;
            pat[i] = 1'b1;
            write(8'h00, pat);
            read (8'h00);
        end

        // TCR [4:0] walking-0
        for (i = 0; i < 5; i++) begin
            pat = 8'h1F;
            pat[i] = 1'b0;
            write(8'h00, pat);
            read (8'h00);
        end

        // TDR walking-1
        for (i = 0; i < 8; i++) begin
            pat = 8'h00;
            pat[i] = 1'b1;
            write(8'h02, pat);
            read (8'h02);
        end

        // TIE [1:0]: 00, 01, 10, 11
        for (i = 0; i < 4; i++) begin
            write(8'h03, {6'b0, 2'(i)});
            read (8'h03);
        end

        // Random RW
        for (i = 0; i < 10; i++) begin
            pat = $urandom;
            pat[7:5] = 3'b0;
            write(8'h00, pat);
            read (8'h00);

            write(8'h02, $urandom);
            read (8'h02);

            write(8'h03, {6'b0, $urandom & 8'h03});
            read (8'h03);
        end

        $display("[%s] done", get_name());
    endtask
endclass