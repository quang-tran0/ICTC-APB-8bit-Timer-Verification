class scoreboard;
    mailbox #(obs_packet) m2s_mb;

    // Reference model — chỉ phản ánh DUT, cập nhật theo đặc tả
    bit [4:0] ref_tcr;        // TCR (5-bit)
    bit [1:0] ref_tsr;        // TSR (2-bit, W1C)
    bit [7:0] ref_tdr;        // TDR
    bit [1:0] ref_tie;        // TIE (2-bit)

    // Counters
    int unsigned compare_count;
    int unsigned mismatch_count;
    int unsigned write_count;
    int unsigned read_count;

    // State của cycle trước — để xác định rising edge của penable
    logic prev_penable;

    function new(mailbox #(obs_packet) m2s_mb);
        this.m2s_mb = m2s_mb;
        reset_ref();
        compare_count  = 0;
        mismatch_count = 0;
        write_count    = 0;
        read_count     = 0;
        prev_penable   = 1'b0;
    endfunction

    function void reset_ref();
        ref_tcr = 5'h00;
        ref_tsr = 2'b00;
        ref_tdr = 8'h00;
        ref_tie = 2'b00;
    endfunction

    // --------- Reference: apply WRITE ----------
    function void ref_write(bit [7:0] addr, bit [7:0] data);
        case (addr)
            8'h00: ref_tcr = data[4:0];
            8'h01: ref_tsr = ref_tsr & ~data[1:0];   // W1C
            8'h02: ref_tdr = data;
            8'h03: ref_tie = data[1:0];
            default: ; // reserved: ignore
        endcase
    endfunction

    // --------- Reference: predict READ ----------
    function bit [7:0] ref_read(bit [7:0] addr);
        bit [7:0] rv;
        case (addr)
            8'h00: rv = {3'b000, ref_tcr};
            8'h01: rv = {6'b000000, ref_tsr};
            8'h02: rv = ref_tdr;
            8'h03: rv = {6'b000000, ref_tie};
            default: rv = 8'h00;
        endcase
        return rv;
    endfunction

    // --------- Main loop ----------
    task run();
        obs_packet obs;
        forever begin
            m2s_mb.get(obs);
            compare_count++;

            if (obs.psel === 1'b1 && obs.penable === 1'b1 && prev_penable === 1'b0) begin
                if (obs.pwrite === 1'b1)
                    compare_write(obs);
                else
                    compare_read(obs);
            end

            prev_penable = obs.penable;
            #1;
        end
    endtask

    task compare_write(obs_packet obs);
        bit [7:0] addr  = obs.paddr;
        bit [7:0] data  = obs.pwdata;
        write_count++;
        ref_write(addr, data);
        $display("%0t: [scoreboard] WRITE paddr=8'h%02h pwdata=8'h%02h | TCR=8'h%02h TSR=8'h%02h TDR=8'h%02h TIE=8'h%02h",
                 $time, addr, data,
                 {3'b000, ref_tcr}, {6'b000000, ref_tsr},
                 ref_tdr, {6'b000000, ref_tie});
    endtask

    task compare_read(obs_packet obs);
        bit [7:0] addr = obs.paddr;
        bit [7:0] got  = obs.prdata;
        bit [7:0] exp;

        read_count++;
        exp = ref_read(addr);

        if (got !== exp) begin
            $error("%0t: [scoreboard] READ MISMATCH paddr=%02h got=%02h exp=%02h",
                   $time, addr, got, exp);
            mismatch_count++;
        end else begin
            $display("%0t: [scoreboard] READ OK paddr=%02h prdata=%02h",
                     $time, addr, got);
        end
    endtask

    function void report();
        $display("========== [scoreboard] FINAL REPORT ===========");
        $display("  compares   = %0d", compare_count);
        $display("  writes     = %0d", write_count);
        $display("  reads      = %0d", read_count);
        $display("  mismatches = %0d", mismatch_count);
        $display("  STATUS     = %s",
                 (mismatch_count == 0) ? "PASS" : "FAIL");
        $display("================================================");
    endfunction
endclass