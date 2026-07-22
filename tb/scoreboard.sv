class scoreboard;
    mailbox #(packet) m2s_mb;

    function new(mailbox #(packet) m2s_mb);
        this.m2s_mb = m2s_mb;
    endfunction

    function void run();
    endfunction
endclass