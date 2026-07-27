// rw_register_test.sv
// Drive walking-1/walking-0 and random patterns to all RW fields and read back.
// Scoreboard tự so sánh qua ref model (write → cập nhật ref, read → so sánh exp).
// Lưu ý: TCR RW chỉ có bits [4:0]; TDR RW cả 8 bits; TIE RW chỉ có bits [1:0].

class rw_register_test extends base_test;
    function new();
        super.new();
    endfunction

    function string get_name();
        return "rw_register_test";
    endfunction

    virtual task run_scenario();
        int i;

        $display("[%s] start", get_name());

        // Walking-1 across TCR RW bits [4:0]
        for (i = 0; i < 5; i++) begin
            bit [7:0] pat;
            pat = 8'h00;
            pat[i] = 1'b1;
            write(8'h00, pat);
            read (8'h00);
        end

        // Walking-0 across TCR RW bits [4:0]
        for (i = 0; i < 5; i++) begin
            bit [7:0] pat;
            pat = 8'h1F;
            pat[i] = 1'b0;
            write(8'h00, pat);
            read (8'h00);
        end

        // Walking-1 across TDR full byte
        for (i = 0; i < 8; i++) begin
            bit [7:0] pat;
            pat = 8'h00;
            pat[i] = 1'b1;
            write(8'h02, pat);
            read (8'h02);
        end

        // Walking across TIE bits [1:0]: 00, 01, 10, 11
        for (i = 0; i < 4; i++) begin
            bit [7:0] pat;
            pat = {6'b0, 2'(i)};
            write(8'h03, pat);
            read (8'h03);
        end

        // Random RW values
        for (i = 0; i < 10; i++) begin
            bit [7:0] pat;

            // TCR: chỉ bits [4:0] là RW, mask đi
            pat = $urandom;
            pat[7:5] = 3'b0;
            write(8'h00, pat);
            read (8'h00);

            // TDR: full byte RW
            pat = $urandom;
            write(8'h02, pat);
            read (8'h02);

            // TIE: chỉ bits [1:0] là RW
            pat = {6'b0, $urandom & 8'h03};
            write(8'h03, pat);
            read (8'h03);
        end

        $display("[%s] done", get_name());
    endtask
endclass
