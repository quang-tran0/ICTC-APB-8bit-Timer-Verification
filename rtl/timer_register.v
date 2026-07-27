module timer_register(
	input wire         pclk,
	input wire         presetn,
	input wire         pwrite,
	input wire         psel,
	input wire         penable,
	output wire        pready,
	input wire [7:0]   paddr,
	input wire [7:0]   pwdata,
	output logic [7:0] prdata,
	output logic       load,
	output logic       udf,
	output logic       ovf,
	input wire         s_udf,
	input wire         s_ovf,
	output logic [7:0] reg_TDR,
	output logic [1:0] clkdiv,
	output logic       count_down,
	output logic       timer_en,
	output logic       underflow_en,
	output logic       overflow_en
);

	logic [4:0] tcr;
	logic [1:0] tsr;
	logic [1:0] tie;

	wire write_en = psel && penable && pwrite;

	assign pready = 1'b1;

	assign load = tcr[2];
	assign count_down = tcr[1];
	assign timer_en = tcr[0];
	assign clkdiv = tcr[4:3];
	assign udf = tsr[1];
	assign ovf = tsr[0];
	assign underflow_en = tie[1];
	assign overflow_en = tie[0];

	always_ff @(posedge pclk or negedge presetn) begin
		if (!presetn) begin
			tcr <= 5'b0;
			reg_TDR <= 8'h00;
			tie <= 2'b00;
		end else if (write_en) begin
			unique case (paddr)
				8'h00: begin
					// TCR full-write: cả 5 bit đều được ghi, kể cả khi timer_en=1.
					tcr <= pwdata[4:0];
				end
				8'h02: reg_TDR <= pwdata;
				8'h03: tie <= pwdata[1:0];
				default: begin
				end
			endcase
		end
	end

	always @(posedge pclk or negedge presetn or posedge s_udf or posedge s_ovf) begin
		if (!presetn) begin
			tsr <= 2'b00;
		end else if (s_udf || s_ovf) begin
			if (s_udf) begin
				tsr[1] <= 1'b1;
			end
			if (s_ovf) begin
				tsr[0] <= 1'b1;
			end
		end else if (write_en && paddr == 8'h01) begin
			tsr <= tsr & ~pwdata[1:0];
		end
	end

	always_comb begin
		unique case (paddr)
			8'h00: prdata = {3'b000, tcr};
			8'h01: prdata = {6'b000000, tsr};
			8'h02: prdata = reg_TDR;
			8'h03: prdata = {6'b000000, tie};
			default: prdata = 8'h00;
		endcase
	end

endmodule
