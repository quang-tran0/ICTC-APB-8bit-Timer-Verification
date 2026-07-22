class packet;
    typedef enum bit {READ=0, WRITE=1} transfer_enum;

    bit[7:0]      addr;
    bit[7:0]      data;
    transfer_enum transfer;

    // Observability for scoreboard/reference-model debugging
    bit[7:0] paddr;
    bit[7:0] prdata;
    bit[7:0] pwdata;
    bit pwrite;
    bit psel;
    bit penable;
    bit pready;

    // CPU/ker domain clock-edge counters (used by reference model ordering)
    int unsigned  ker_edges;
    int unsigned  p_edges;

    function new();
    endfunction
endclass
