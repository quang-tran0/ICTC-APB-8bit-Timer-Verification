// Constrained-random paddr/pwrite/pwdata regression against the reference model.

class random_register_test extends base_test;
    function new();
        super.new();
    endfunction

    virtual function string get_name();
        return "random_register_test";
    endfunction

    virtual task run_scenario();
        int i;
        apb_rand_txn txn;

        $display("%0t: [%s] start", $time, get_name());
        wait(vif.presetn == 1'b1);

        txn = new();
        for (i = 0; i < 60; i++) begin
            assert(txn.randomize())
                else $error("%0t: [%s] randomize failed", $time, get_name());

            if (txn.wr)
                write(txn.addr, txn.data);
            else
                read(txn.addr);
        end

        $display("%0t: [%s] done", $time, get_name());
    endtask
endclass
