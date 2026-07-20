module timer_counter(
	input wire       pclk,
	input wire       presetn,
	input wire       clk_in,
	input wire       load,
	input wire       count_down,
	input wire       timer_en,
	output logic     s_ovf,
	output logic     s_udf,
	input wire [7:0] reg_TDR
);

	logic [7:0] counter;

	always_ff @(posedge clk_in or negedge presetn) begin
		if (!presetn) begin
			counter <= 8'h00;
			s_ovf <= 1'b0;
			s_udf <= 1'b0;
		end else begin
			// The specification requires load to take priority over counting:
			// while load is asserted, hold the counter at the TDR value.
			if (load) begin
				counter <= reg_TDR;
			end else if (timer_en) begin
				if (count_down) begin
					if (counter == 8'h00) begin
						counter <= 8'hFF;
						// Toggle events cannot be missed by the slower pclk domain.
						s_udf <= ~s_udf;
					end else begin
						counter <= counter - 8'd1;
					end
				end else begin
					if (counter == 8'hFF) begin
						counter <= 8'h00;
						s_ovf <= ~s_ovf;
					end else begin
						counter <= counter + 8'd1;
					end
				end
			end
		end
	end

endmodule
