class packet;
    typedef enum bit {READ=0, WRITE=1} transfer_enum;

    bit[7:0]      addr;
    bit[7:0]      data;
    transfer_enum transfer;

    // Observability for scoreboard/reference-model debugging
    bit[7:0] obs_paddr;
    bit[7:0] obs_prdata;
    bit[7:0] obs_pwdata;
    bit obs_pwrite;
    bit obs_psel;
    bit obs_penable;
    bit obs_pready;

    // CPU/ker domain clock-edge counters (used by reference model ordering)
    // int unsigned  ker_edges;
    // int unsigned  p_edges;
endclass
