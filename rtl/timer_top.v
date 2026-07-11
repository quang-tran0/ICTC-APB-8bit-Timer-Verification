module timer_top( 
    input wire          pclk,
    input wire          ker_clk,
    input wire          presetn,
    input wire          pwrite,
    input wire          psel,
    input wire          penable,
    input wire [7:0]    paddr,
    input wire [7:0]    pwdata,
    output wire [7:0]   prdata,
    output wire         pready,
    output wire         interrupt
);
    wire [1:0] clkdiv;
    wire [7:0] reg_TDR;
    wire       load;
    wire       udf;
    wire       ovf;
    wire       timer_en;
    wire       underflow_en;
    wire       overflow_en;
    wire       clk_out;
    wire       s_ovf;
    wire       s_udf;

    timer_register u_register(
        .pclk(pclk),
        .presetn(presetn),
        .pwrite(pwrite),
        .psel(psel),
        .penable(penable),
        .pready(pready),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata(prdata),
        .load(load),
        .udf(udf),
        .ovf(ovf),
        .s_udf(s_udf),
        .s_ovf(s_ovf),
        .reg_TDR(reg_TDR),
        .clkdiv(clkdiv),
        .count_down(count_down),
        .timer_en(timer_en),
        .underflow_en(underflow_en),
        .overflow_en(overflow_en)
    );

    timer_clock_divisor u_clock_divisor(
        .presetn(presetn),
        .ker_clk(ker_clk),
        .clkdiv(clkdiv),
        .clk_out(clk_out)
    );

    timer_counter u_counter(
        .pclk(pclk),
        .presetn(presetn),
        .clk_in(clk_out),
        .load(load),
        .count_down(count_down),
        .timer_en(timer_en),
        .s_ovf(s_ovf),
        .s_udf(s_udf),
        .reg_TDR(reg_TDR)
    );

    timer_interrupt u_interrupt(
        .udf(udf),
        .ovf(ovf),
        .underflow_en(underflow_en),
        .overflow_en(overflow_en),
        .interrupt(interrupt)
    );

endmodule