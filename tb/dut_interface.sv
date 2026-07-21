interface dut_if;
    logic          ker_clk;    // APB Clock
    logic          pclk;       // APB Clock
    logic          presetn;    // Active-low reset
    logic          psel;       // APB Select
    logic          penable;    // APB Enable
    logic          pwrite;     // APB Write enable
    logic [7:0]    paddr;      // APB Address
    logic [7:0]    pwdata;     // APB Write data
    logic [7:0]    prdata;     // APB Read data
    logic          pready;     // APB Read data
    logic          interrupt;  // Interrupt signal
    logic          allow_invalid_apb;

    wire access = psel && penable;

    property p_penable_needs_psel;
        @(posedge pclk) disable iff (!presetn || allow_invalid_apb)
            penable |-> psel;
    endproperty
    a_penable_needs_psel: assert property (p_penable_needs_psel)
        else $error("%0t: [assert] penable high while psel low", $time);

    property p_ready_in_access;
        @(posedge pclk) disable iff (!presetn)
            access |-> pready;
    endproperty
    a_ready_in_access: assert property (p_ready_in_access)
        else $error("%0t: [assert] pready not high in ACCESS", $time);

    property p_addr_stable;
        @(posedge pclk) disable iff (!presetn)
            access |-> $stable(paddr);
    endproperty
    a_addr_stable: assert property (p_addr_stable)
        else $error("%0t: [assert] paddr changed during transfer", $time);

    property p_pwrite_stable;
        @(posedge pclk) disable iff (!presetn)
            access |-> $stable(pwrite);
    endproperty
    a_pwrite_stable: assert property (p_pwrite_stable)
        else $error("%0t: [assert] pwrite changed during transfer", $time);

    property p_wdata_stable;
        @(posedge pclk) disable iff (!presetn)
            (access && pwrite) |-> $stable(pwdata);
    endproperty
    a_wdata_stable: assert property (p_wdata_stable)
        else $error("%0t: [assert] pwdata changed during write transfer", $time);

    property p_access_ends;
        @(posedge pclk) disable iff (!presetn || allow_invalid_apb)
            (access && pready) |=> !penable;
    endproperty
    a_access_ends: assert property (p_access_ends)
        else $error("%0t: [assert] penable did not deassert after ACCESS", $time);
endinterface
