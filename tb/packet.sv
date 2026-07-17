class packet;
    typedef enum bit {READ=0, WRITE=1} transfer_enum;

    bit[7:0]      addr;
    bit[7:0]      data;
    transfer_enum transfer;

endclass

// Random APB access: mostly the 4 real registers, sometimes reserved space.
class apb_rand_txn;
    rand bit [7:0] addr;
    rand bit [7:0] data;
    rand bit       wr;

    constraint c_addr { addr dist { [8'h00:8'h03] := 8, [8'h04:8'hFF] := 1 }; }
    constraint c_rw   { wr   dist { 1'b1 := 1, 1'b0 := 1 }; }

    // don't blindly enable the timer on a write to TCR
    constraint c_safe_en { (wr && addr == 8'h00) -> data[0] == 1'b0; }
endclass

// Random counter run: pick a divisor and a load value that keeps the
// number of ticks small so the simulation stays bounded.
class counter_rand_cfg;
    rand bit [1:0] clkdiv;
    rand bit       count_down;
    rand bit [7:0] tdr;

    int unsigned ticks;
    int unsigned kpt;

    // favour no-divide but still cover /2 /4 /8
    constraint c_clkdiv { clkdiv dist { 2'b00 := 3, [2'b01:2'b11] := 1 }; }

    constraint c_tdr {
        count_down  -> tdr inside {[8'h02:8'h20]};
        !count_down -> tdr inside {[8'hE0:8'hFE]};
    }

    function void post_randomize();
        kpt   = 1 << clkdiv;
        ticks = count_down ? (tdr + 1) : (256 - tdr);
    endfunction
endclass
