// rw_register_test.sv
// 1. Write each register with a unique non-zero pattern
// 2. Read each register back
// Scoreboard tự so sánh qua ref model (write → cập nhật ref, read → so sánh exp)
//
// Note: TCR half-load reload behavior được test riêng (sẽ viết sau).
// Test này CHỈ verify R/W đơn giản cho cả 4 registers.

class rw_register_test extends base_test;
    function new();
        super.new();
    endfunction

    function string get_name();
        return "rw_register_test";
    endfunction

    virtual task run_scenario();
        $display("[%s] start", get_name());

        // TCR
        write(8'h00, 8'h1F);
        read(8'h00);

        // TDR
        write(8'h02, 8'hA5);
        read(8'h02);

        // TIE
        write(8'h03, 8'h03);
        read(8'h03);

        // TDR reload
        write(8'h02, 8'h5A);
        read(8'h02);

        // TIE reload
        write(8'h03, 8'h02);
        read(8'h03);

        $display("[%s] done", get_name());
    endtask
endclass