module timer_clock_divisor(
	input wire       presetn,
	input wire       ker_clk,
	input wire [1:0] clkdiv,
	output wire      clk_out
);

	logic clk_out_reg;
	logic [2:0] div_cnt;

	always_ff @(posedge ker_clk or negedge presetn) begin
		if (!presetn) begin
			clk_out_reg <= 1'b0;
			div_cnt <= 3'd0;
		end else begin
			unique case (clkdiv)
				2'b01: begin
					clk_out_reg <= ~clk_out_reg;
					div_cnt <= 3'd0;
				end
				2'b10: begin
					if (div_cnt == 3'd1) begin
						clk_out_reg <= ~clk_out_reg;
						div_cnt <= 3'd0;
					end else begin
						div_cnt <= div_cnt + 3'd1;
					end
				end
				2'b11: begin
					if (div_cnt == 3'd3) begin
						clk_out_reg <= ~clk_out_reg;
						div_cnt <= 3'd0;
					end else begin
						div_cnt <= div_cnt + 3'd1;
					end
				end
				default: begin
					clk_out_reg <= 1'b0;
					div_cnt <= 3'd0;
				end
			endcase
		end
	end

	assign clk_out = (clkdiv == 2'b00) ? ker_clk : clk_out_reg;

endmodule
