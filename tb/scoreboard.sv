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

    // Cờ: nếu READ TSR kế tiếp có thể bị DUT đè bit do HW race
    bit expect_tsr_race;

    function new(mailbox #(packet) m2s_mb);
        this.m2s_mb = m2s_mb;
        reset_ref();
        compare_count  = 0;
        mismatch_count = 0;
        write_count    = 0;
        read_count     = 0;
        expect_tsr_race = 1'b0;
    endfunction

    function void reset_ref();
        ref_tcr = 5'h00;
        ref_tsr = 2'b00;
        ref_tdr = 8'h00;
        ref_tie = 2'b00;
    endfunction

    function void hard_reset();
        reset_ref();
        compare_count  = 0;
        mismatch_count = 0;
        write_count    = 0;
        read_count     = 0;
        expect_tsr_race = 1'b0;
    endfunction

    // --------- Reference: apply WRITE ----------
    function void ref_write(bit [7:0] addr, bit [7:0] data);
        case (addr)
            8'h00: begin
                if (ref_tcr[0] == 1'b0) begin
                    ref_tcr = data[4:0];
                end else begin
                    ref_tcr = {ref_tcr[4:1], data[0]};
                end
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

    // Test gọi khi biết counter vừa overflow/underflow
    function void hw_set_tsr(bit overflow, bit underflow);
        if (overflow)  ref_tsr[0] = 1'b1;
        if (underflow) ref_tsr[1] = 1'b1;
    endfunction

    function void expect_next_tsr_race();
        expect_tsr_race = 1'b1;
    endfunction

    // --------- Xác định loại transaction từ packet ----------
    // Packet từ monitor không có trường `transfer` (chỉ có obs_*).
    // Lấy transfer từ obs_pwrite (0 = READ, 1 = WRITE).
    function packet::transfer_enum derive_transfer(packet pkt);
        if (pkt.obs_pwrite == 1'b1)
            return packet::WRITE;
        else
            return packet::READ;
    endfunction

    // --------- Main loop ----------
    task run();
        packet pkt;
        forever begin
            m2s_mb.get(pkt);
            if (pkt == null) begin
                $error("%0t [scoreboard] null packet", $time);
                continue;
            end

            compare_count++;

            if (derive_transfer(pkt) == packet::WRITE) begin
                compare_write(pkt);
            end else begin
                compare_read(pkt);
            end

            #1;
        end
    endtask

    task compare_write(packet pkt);
        write_count++;
        ref_write(pkt.obs_paddr, pkt.obs_pwdata);
        $display("%0t: [scoreboard] WRITE paddr=8'h%02h pwdata=8'h%02h | TCR=8'h%02h TSR=8'h%02h TDR=8'h%02h TIE=8'h%02h",
                 $time, pkt.obs_paddr, pkt.obs_pwdata,
                 {3'b000, ref_tcr}, {6'b000000, ref_tsr},
                 ref_tdr, {6'b000000, ref_tie});
    endtask

    task compare_read(packet pkt);
        bit [7:0] exp;
        bit [7:0] got;
        bit       do_compare;

        read_count++;
        exp = ref_read(pkt.obs_paddr);
        got = pkt.obs_prdata;

        if (pkt.obs_paddr == 8'h01 && expect_tsr_race) begin
            // Đồng bộ model theo giá trị thực tế, không tính mismatch
            ref_tsr = got[1:0];
            expect_tsr_race = 1'b0;
            $display("%0t: [scoreboard] READ TSR (race OK) got=%02h (sync ref_tsr)",
                     $time, got);
            do_compare = 1'b0;
        end else begin
            do_compare = 1'b1;
        end

        if (do_compare) begin
            if (got !== exp) begin
                $error("%0t: [scoreboard] READ MISMATCH paddr=%02h got=%02h exp=%02h",
                       $time, pkt.obs_paddr, got, exp);
                mismatch_count++;
            end else begin
                $display("%0t: [scoreboard] READ OK paddr=%02h prdata=%02h",
                         $time, pkt.obs_paddr, got);
            end
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