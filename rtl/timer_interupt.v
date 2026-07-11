module timer_interrupt(
	input wire udf,
	input wire ovf,
	input wire underflow_en,
	input wire overflow_en,
	output wire interrupt
);

	assign interrupt = (underflow_en & udf) | (overflow_en & ovf);

endmodule
