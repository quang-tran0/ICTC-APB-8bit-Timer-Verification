// Exercise every TIE mask against both hardware status sources.
class interrupt_mask_source_cross_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "interrupt_mask_source_cross_test";
    endfunction

    task run_one(bit [1:0] tie, bit underflow);
        bit [7:0] status_mask;
        bit [7:0] tdr;

        status_mask = underflow ? 8'h02 : 8'h01;
        tdr         = underflow ? 8'h02 : 8'hFD;

        write(8'h03, {6'b0, tie});
        write(8'h02, tdr);
        write(8'h00, {3'b000, 2'b00, 1'b1, underflow, 1'b1});
        write(8'h00, {3'b000, 2'b00, 1'b0, underflow, 1'b1});
        wait_ker(8);
        write(8'h00, {3'b000, 2'b00, 1'b0, underflow, 1'b0});
        wait_pclk(3);

        read(8'h01);
        env.sb.check_interrupt(vif.interrupt);
        write(8'h01, status_mask);
        wait_pclk(3);
        env.sb.check_interrupt(vif.interrupt);
    endtask

    virtual task run_scenario();
        int tie;

        wait(vif.presetn == 1'b1);
        for (tie = 0; tie < 4; tie++) begin
            run_one(tie[1:0], 1'b0);
            run_one(tie[1:0], 1'b1);
        end
    endtask
endclass
