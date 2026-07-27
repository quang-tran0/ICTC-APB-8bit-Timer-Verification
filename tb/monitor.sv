// monitor.sv
// Capture APB transaction từ DUT và đóng gói thành packet (addr / data / transfer)
// gửi cho scoreboard qua mailbox m2s_mb.
//
// Lưu ý: Tại active region của @posedge pclk, các tín hiệu chưa được cập nhật
// (driver/DUT lái ở NBA region). Phải wait 1 delta (#1) sau posedge trước khi
// check điều kiện hoặc sample giá trị.

class monitor;
    mailbox #(packet) m2s_mb;
    virtual dut_if vif;

    function new(virtual dut_if vif, mailbox #(packet) m2s_mb);
        this.vif = vif;
        this.m2s_mb = m2s_mb;
    endfunction

    task run();
        packet obs_pkt;
        forever begin
            // Bước 1: đợi cycle mà psel=1, penable=1, pready=1 (transaction complete)
            @(posedge vif.pclk);
            #1;  // chờ NBA region hoàn tất
            while (!((vif.psel === 1'b1) && (vif.penable === 1'b1) && (vif.pready === 1'b1))) begin
                @(posedge vif.pclk);
                #1;
            end

            // Sample bus — paddr/pwdata/prdata đã ổn định (NBA region của cycle này
            // chưa chạy nhưng tín hiệu từ cycle trước đã có)
            obs_pkt = new();
            obs_pkt.addr = vif.paddr;
            obs_pkt.data = (vif.pwrite === 1'b1) ? vif.pwdata : vif.prdata;
            obs_pkt.transfer = (vif.pwrite === 1'b1) ? packet::WRITE : packet::READ;

            $display("%0t: [monitor] Captured %s addr=8'h%02h data=8'h%02h",
                     $time,
                     (obs_pkt.transfer == packet::WRITE) ? "WRITE" : "READ",
                     obs_pkt.addr, obs_pkt.data);

            m2s_mb.put(obs_pkt);

            // Bước 2: đợi transaction kết thúc (driver idle -> psel=0)
            @(posedge vif.pclk);
            #1;
            while (vif.psel === 1'b1) begin
                @(posedge vif.pclk);
                #1;
            end
        end
    endtask
endclass