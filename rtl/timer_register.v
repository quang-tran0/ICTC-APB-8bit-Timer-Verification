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
	logic       s_udf_meta;
	logic       s_udf_sync;
	logic       s_udf_seen;
	logic       s_ovf_meta;
	logic       s_ovf_sync;
	logic       s_ovf_seen;

	wire write_en = psel && penable && pwrite;
	wire read_en = psel && penable && !pwrite;
	wire [1:0] hw_set = {s_udf_sync ^ s_udf_seen,
	                     s_ovf_sync ^ s_ovf_seen};
	wire [1:0] sw_clear = (write_en && paddr == 8'h01) ?
	                      pwdata[1:0] : 2'b00;

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

	// Synchronize the counter-domain event toggles into pclk. A toggle is
	// consumed once, so a slow divided clock cannot continuously re-set TSR
	// while software is issuing a W1C transfer.
	always_ff @(posedge pclk or negedge presetn) begin
		if (!presetn) begin
			tsr <= 2'b00;
			s_udf_meta <= 1'b0;
			s_udf_sync <= 1'b0;
			s_udf_seen <= 1'b0;
			s_ovf_meta <= 1'b0;
			s_ovf_sync <= 1'b0;
			s_ovf_seen <= 1'b0;
		end else begin
			s_udf_meta <= s_udf;
			s_udf_sync <= s_udf_meta;
			s_udf_seen <= s_udf_sync;
			s_ovf_meta <= s_ovf;
			s_ovf_sync <= s_ovf_meta;
			s_ovf_seen <= s_ovf_sync;

			// A simultaneous hardware event has priority over software clear.
			tsr <= (tsr & ~sw_clear) | hw_set;
		end
	end

	always_comb begin
		prdata = 8'h00;
		if (read_en) begin
			unique case (paddr)
				8'h00: prdata = {3'b000, tcr};
				8'h01: prdata = {6'b000000, tsr};
				8'h02: prdata = reg_TDR;
				8'h03: prdata = {6'b000000, tie};
				default: prdata = 8'h00;
			endcase
		end
	end

endmodule
