// scoreboard.sv
// Self-checking scoreboard: dự đoán giá trị từng APB transaction dựa trên
// reference model (TCR/TSR/TDR/TIE) rồi so sánh với packet nhận từ monitor.

class scoreboard;
    mailbox #(packet) m2s_mb;

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

    function new(mailbox #(packet) m2s_mb);
        this.m2s_mb = m2s_mb;
        reset_ref();
        compare_count  = 0;
        mismatch_count = 0;
        write_count    = 0;
        read_count     = 0;
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
            8'h00: begin
                // TCR full-write: cả 5 bit [4:0] đều được ghi, kể cả khi timer_en=1.
                ref_tcr = data[4:0];
            end
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
        packet pkt;
        forever begin
            m2s_mb.get(pkt);
            compare_count++;

            if (pkt.transfer == packet::WRITE)
                compare_write(pkt);
            else
                compare_read(pkt);

            #1;
        end
    endtask

    task compare_write(packet pkt);
        write_count++;
        ref_write(pkt.addr, pkt.data);
        $display("%0t: [scoreboard] WRITE paddr=8'h%02h pwdata=8'h%02h | TCR=8'h%02h TSR=8'h%02h TDR=8'h%02h TIE=8'h%02h",
                 $time, pkt.addr, pkt.data,
                 {3'b000, ref_tcr}, {6'b000000, ref_tsr},
                 ref_tdr, {6'b000000, ref_tie});
    endtask

    task compare_read(packet pkt);
        bit [7:0] exp;
        bit [7:0] got;

        read_count++;
        exp = ref_read(pkt.addr);
        got = pkt.data;

        if (got !== exp) begin
            $error("%0t: [scoreboard] READ MISMATCH paddr=%02h got=%02h exp=%02h",
                   $time, pkt.addr, got, exp);
            mismatch_count++;
        end else begin
            $display("%0t: [scoreboard] READ OK paddr=%02h prdata=%02h",
                     $time, pkt.addr, got);
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
