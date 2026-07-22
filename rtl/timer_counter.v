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
	logic       load_armed;

	always_ff @(posedge clk_in or negedge presetn) begin
		if (!presetn) begin
			counter <= 8'h00;
			load_armed <= 1'b0;
			s_ovf <= 1'b0;
			s_udf <= 1'b0;
		end else begin
			s_ovf <= 1'b0;
			s_udf <= 1'b0;

			if (!load) begin
				load_armed <= 1'b0;
			end

			if (load && !load_armed) begin
				counter <= reg_TDR;
				load_armed <= 1'b1;
			end else if (timer_en) begin
				if (count_down) begin
					if (counter == 8'h00) begin
						counter <= 8'hFF;
						s_udf <= 1'b1;
					end else begin
						counter <= counter - 8'd1;
					end
				end else begin
					if (counter == 8'hFF) begin
						counter <= 8'h00;
						s_ovf <= 1'b1;
					end else begin
						counter <= counter + 8'd1;
					end
				end
			end
		end
	end

endmodule
