class scoreboard;
    virtual dut_if vif;
    mailbox #(obs_packet) m2s_mb;
    event ker_clk_edge;

    bit [4:0] ref_tcr;
    bit [1:0] ref_tsr;
    bit [7:0] ref_tdr;
    bit [1:0] ref_tie;

    bit [7:0] ref_counter;

    bit [1:0] ref_clkdiv;
    bit       ref_load_bit;
    bit       ref_count_down;
    bit       ref_timer_en;

    bit [2:0] ref_div_cnt;
    bit       ref_clk_out_reg;

    int unsigned compare_count;
    int unsigned mismatch_count;
    int unsigned write_count;
    int unsigned read_count;
    int unsigned irq_check_count;
    int unsigned irq_mismatch_count;
    int unsigned protocol_error_count;

    logic prev_penable;
    bit [7:0] prev_dut_counter;
    bit       prev_interrupt;

    covergroup cg_reg_access with function sample(bit [7:0] addr,
                                                   bit       write_access);
        option.per_instance = 1;
        cp_addr: coverpoint addr {
            bins tcr      = {8'h00};
            bins tsr      = {8'h01};
            bins tdr      = {8'h02};
            bins tie      = {8'h03};
            bins reserved = {[8'h04:8'hFF]};
        }
        cp_dir: coverpoint write_access {
            bins reads  = {1'b0};
            bins writes = {1'b1};
        }
        cx_addr_dir: cross cp_addr, cp_dir {
            ignore_bins reserved_write =
                binsof(cp_addr.reserved) && binsof(cp_dir.writes);
        }
    endgroup

    covergroup cg_config with function sample(bit [1:0] clkdiv,
                                               bit       count_down,
                                               bit       load,
                                               bit       previous_timer_en,
                                               bit       timer_en);
        option.per_instance = 1;
        cp_clk_div: coverpoint clkdiv {
            bins no_divide = {2'b00};
            bins div_2     = {2'b01};
            bins div_4     = {2'b10};
            bins div_8     = {2'b11};
        }
        cp_count_down: coverpoint count_down {
            bins up   = {1'b0};
            bins down = {1'b1};
        }
        cp_load: coverpoint load {
            bins clear = {1'b0};
            bins set   = {1'b1};
        }
        cp_timer_en: coverpoint {previous_timer_en, timer_en} {
            bins start = {2'b01};
            bins stop  = {2'b10};
        }
        cx_clkdiv_direction: cross cp_clk_div, cp_count_down
            iff (!previous_timer_en && timer_en);
    endgroup

    covergroup cg_counter with function sample(bit [7:0] previous_count,
                                                bit [7:0] count,
                                                bit [7:0] tdr,
                                                bit       load,
                                                bit       counting);
        option.per_instance = 1;
        cp_cnt_value: coverpoint count {
            bins zero = {8'h00};
            bins one  = {8'h01};
            bins low  = {[8'h02:8'h7E]};
            bins mid  = {8'h7F};
            bins high = {[8'h80:8'hFE]};
            bins max  = {8'hFF};
        }
        cp_cnt_transition: coverpoint {previous_count, count} iff (counting) {
            bins overflow  = {16'hFF00};
            bins underflow = {16'h00FF};
        }
        cp_tdr_load_value: coverpoint tdr iff (load) {
            bins zero   = {8'h00};
            bins max    = {8'hFF};
            bins others = {[8'h01:8'hFE]};
        }
    endgroup

    covergroup cg_interrupt with function sample(bit [1:0] tie,
                                                  bit       tie_sample,
                                                  bit       status_source,
                                                  bit       status_set,
                                                  bit       previous_irq,
                                                  bit       irq,
                                                  bit       irq_sample);
        option.per_instance = 1;
        cp_tie: coverpoint tie iff (tie_sample) {
            bins disabled = {2'b00};
            bins ovf_only = {2'b01};
            bins udf_only = {2'b10};
            bins both     = {2'b11};
        }
        cp_status_src: coverpoint status_source iff (status_set) {
            bins overflow  = {1'b0};
            bins underflow = {1'b1};
        }
        cx_tie_status: cross cp_tie, cp_status_src iff (status_set);
        cp_int_out: coverpoint {previous_irq, irq} iff (irq_sample) {
            bins asserted = {2'b01};
            bins cleared  = {2'b10};
        }
    endgroup

    function new(virtual dut_if vif,
                 mailbox #(obs_packet) m2s_mb,
                 event ker_clk_edge);
        this.vif          = vif;
        this.m2s_mb       = m2s_mb;
        this.ker_clk_edge = ker_clk_edge;
        cg_reg_access = new();
        cg_config     = new();
        cg_counter    = new();
        cg_interrupt  = new();
        reset_ref();
        compare_count        = 0;
        mismatch_count       = 0;
        write_count          = 0;
        read_count           = 0;
        irq_check_count      = 0;
        irq_mismatch_count   = 0;
        protocol_error_count = 0;
        prev_penable         = 1'b0;
        prev_dut_counter     = 8'h00;
        prev_interrupt       = 1'b0;
    endfunction

    function void reset_ref();
        ref_tcr         = 5'h00;
        ref_tsr         = 2'b00;
        ref_tdr         = 8'h00;
        ref_tie         = 2'b00;
        ref_counter     = 8'h00;
        ref_clkdiv      = 2'b00;
        ref_load_bit    = 1'b0;
        ref_count_down  = 1'b0;
        ref_timer_en    = 1'b0;
        ref_div_cnt     = 3'd0;
        ref_clk_out_reg = 1'b0;
    endfunction

    // Sync the reference model to a hardware reset (presetn asserted).
    function void hard_reset();
        reset_ref();
        prev_dut_counter = 8'h00;
        prev_interrupt   = 1'b0;
        $display("%0t: [scoreboard] hard_reset -> defaults", $time);
    endfunction

    function void refresh_ref_tcr_fields();
        ref_clkdiv     = ref_tcr[4:3];
        ref_load_bit   = ref_tcr[2];
        ref_count_down = ref_tcr[1];
        ref_timer_en   = ref_tcr[0];
    endfunction

    function void tick_count_mode();
        if (ref_count_down) begin
            if (ref_counter == 8'h00) begin
                ref_counter = 8'hFF;
                ref_tsr[1]  = 1'b1;
            end else begin
                ref_counter = ref_counter - 8'd1;
            end
        end else begin
            if (ref_counter == 8'hFF) begin
                ref_counter = 8'h00;
                ref_tsr[0]  = 1'b1;
            end else begin
                ref_counter = ref_counter + 8'd1;
            end
        end
    endfunction

    // Advance the clock divisor on every ker_clk (independent of timer_en,
    // like the RTL divisor) and return 1 on a clk_in rising edge.
    function bit clk_in_rising();
        case (ref_clkdiv)
            2'b00: return 1'b1;
            2'b01: begin
                ref_clk_out_reg = ~ref_clk_out_reg;
                ref_div_cnt     = 3'd0;
                return ref_clk_out_reg;
            end
            2'b10: begin
                if (ref_div_cnt == 3'd1) begin
                    ref_clk_out_reg = ~ref_clk_out_reg;
                    ref_div_cnt     = 3'd0;
                    return ref_clk_out_reg;
                end else begin
                    ref_div_cnt = ref_div_cnt + 3'd1;
                    return 1'b0;
                end
            end
            2'b11: begin
                if (ref_div_cnt == 3'd3) begin
                    ref_clk_out_reg = ~ref_clk_out_reg;
                    ref_div_cnt     = 3'd0;
                    return ref_clk_out_reg;
                end else begin
                    ref_div_cnt = ref_div_cnt + 3'd1;
                    return 1'b0;
                end
            end
        endcase
        return 1'b0;
    endfunction

    // On a clk_in rising edge: while load is set the counter holds the TDR
    // value (stops counting), otherwise it counts when enabled.
    function void posedge_kerclk();
        if (!clk_in_rising()) return;

        if (ref_load_bit) begin
            ref_counter = ref_tdr;
        end else if (ref_timer_en) begin
            tick_count_mode();
        end
    endfunction

    function void tcr_config_timer(bit [4:3] clkdiv, bit load, bit count_down, bit timer_en);
        ref_tcr[4:3] = clkdiv;
        ref_tcr[2]   = load;
        ref_tcr[1]   = count_down;
        ref_tcr[0]   = timer_en;
    endfunction

    function void tsr_clear_interrupt(bit underflow, bit overflow);
        ref_tsr = ref_tsr & ~{underflow, overflow};
    endfunction

    function void tdr_write_load_data(bit [7:0] data);
        ref_tdr = data;
    endfunction

    function void tie_enable_interrupt(bit underflow, bit overflow);
        ref_tie = {underflow, overflow};
    endfunction

    function void ref_write(bit [7:0] addr, bit [7:0] data);
        case (addr)
            8'h00: tcr_config_timer(data[4:3], data[2], data[1], data[0]);
            8'h01: tsr_clear_interrupt(data[1], data[0]);
            8'h02: tdr_write_load_data(data);
            8'h03: tie_enable_interrupt(data[1], data[0]);
            default: ;
        endcase
        refresh_ref_tcr_fields();
    endfunction

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

    // ---- Public API for tests ------------------------------------------
    function bit [7:0] get_ref(bit [7:0] addr);
        return ref_read(addr);
    endfunction

    function bit [7:0] get_counter();
        return ref_counter;
    endfunction

    function bit expected_interrupt();
        return (ref_tie[0] & ref_tsr[0]) | (ref_tie[1] & ref_tsr[1]);
    endfunction

    // Compare the observed interrupt output against the reference model.
    function void check_interrupt(bit got);
        bit exp;
        exp = expected_interrupt();
        irq_check_count++;
        if (got !== exp) begin
            $error("%0t: [scoreboard] IRQ MISMATCH got=%b exp=%b (tie=%b tsr=%b)",
                   $time, got, exp, ref_tie, ref_tsr);
            irq_mismatch_count++;
        end else begin
            $display("%0t: [scoreboard] IRQ OK irq=%b", $time, got);
        end
    endfunction
    // --------------------------------------------------------------------

    task run();
        obs_packet obs;
        fork
            forever begin
                @(ker_clk_edge);
                posedge_kerclk();
            end
            forever begin
                m2s_mb.get(obs);
                if (obs.psel === 1'b1 && obs.penable === 1'b1 && prev_penable === 1'b0) begin
                    cg_reg_access.sample(obs.paddr, obs.pwrite);
                    compare_count++;
                    if (obs.pready !== 1'b1) begin
                        $error("%0t: [scoreboard] PROTOCOL: pready not 1 in ACCESS", $time);
                        protocol_error_count++;
                    end
                    if (obs.pwrite === 1'b1)
                        compare_write(obs);
                    else
                        compare_read(obs);
                end
                prev_penable = obs.penable;
                if (!vif.presetn) begin
                    prev_interrupt = 1'b0;
                end else begin
                    cg_interrupt.sample(ref_tie, 1'b0, 1'b0, 1'b0,
                                        prev_interrupt, obs.interrupt, 1'b1);
                    prev_interrupt = obs.interrupt;
                end
                #1;
            end
            forever begin
                bit [7:0] current_count;
                bit       counting;

                @(posedge vif.clk_in);
                #1;
                current_count = vif.counter;
                if (!vif.presetn) begin
                    prev_dut_counter = current_count;
                end else begin
                    counting = ref_timer_en && !ref_load_bit;
                    cg_counter.sample(prev_dut_counter, current_count,
                                      ref_tdr, ref_load_bit, counting);

                    if (counting && prev_dut_counter == 8'hFF && current_count == 8'h00)
                        cg_interrupt.sample(ref_tie, 1'b1, 1'b0, 1'b1,
                                            prev_interrupt, vif.interrupt, 1'b0);
                    if (counting && prev_dut_counter == 8'h00 && current_count == 8'hFF)
                        cg_interrupt.sample(ref_tie, 1'b1, 1'b1, 1'b1,
                                            prev_interrupt, vif.interrupt, 1'b0);

                    prev_dut_counter = current_count;
                end
            end
        join_none
    endtask

    task compare_write(obs_packet obs);
        bit previous_timer_en;

        write_count++;
        previous_timer_en = ref_timer_en;
        ref_write(obs.paddr, obs.pwdata);
        if (obs.paddr == 8'h00)
            cg_config.sample(ref_clkdiv, ref_count_down, ref_load_bit,
                             previous_timer_en, ref_timer_en);
        if (obs.paddr == 8'h03)
            cg_interrupt.sample(ref_tie, 1'b1, 1'b0, 1'b0,
                                prev_interrupt, obs.interrupt, 1'b0);
        $display("%0t: [scoreboard] WRITE paddr=8'h%02h pwdata=8'h%02h | TCR=8'h%02h TSR=8'h%02h TDR=8'h%02h TIE=8'h%02h",
                 $time, obs.paddr, obs.pwdata,
                 {3'b000, ref_tcr}, {6'b000000, ref_tsr}, ref_tdr, {6'b000000, ref_tie});
    endtask

    task compare_read(obs_packet obs);
        bit [7:0] exp;
        read_count++;
        exp = ref_read(obs.paddr);
        if (obs.prdata !== exp) begin
            $error("%0t: [scoreboard] READ MISMATCH paddr=%02h got=%02h exp=%02h",
                   $time, obs.paddr, obs.prdata, exp);
            mismatch_count++;
        end else begin
            $display("%0t: [scoreboard] READ OK paddr=%02h prdata=%02h", $time, obs.paddr, obs.prdata);
        end
    endtask

    function bit passed();
        return (mismatch_count + irq_mismatch_count + protocol_error_count) == 0;
    endfunction

    function void report();
        int unsigned total_fail;
        total_fail = mismatch_count + irq_mismatch_count + protocol_error_count;
        $display("========== [scoreboard] FINAL REPORT ===========");
        $display("  compares             = %0d", compare_count);
        $display("  writes               = %0d", write_count);
        $display("  reads                = %0d", read_count);
        $display("  register mismatches  = %0d", mismatch_count);
        $display("  interrupt checks     = %0d", irq_check_count);
        $display("  interrupt mismatches = %0d", irq_mismatch_count);
        $display("  protocol errors      = %0d", protocol_error_count);
        $display("  cg_reg_access        = %0.2f%%", cg_reg_access.get_inst_coverage());
        $display("  cg_config            = %0.2f%%", cg_config.get_inst_coverage());
        $display("  cg_counter           = %0.2f%%", cg_counter.get_inst_coverage());
        $display("  cg_interrupt         = %0.2f%%", cg_interrupt.get_inst_coverage());
        $display("  STATUS               = %s", (total_fail == 0) ? "PASS" : "FAIL");
        $display("================================================");
    endfunction
endclass
