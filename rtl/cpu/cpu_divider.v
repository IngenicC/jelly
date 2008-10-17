// ----------------------------------------------------------------------------
//  MIPS like CPU for FPGA                                                     
//                                                                             
//                                       Copyright (C) 2008 by Ryuji Fuchikami 
// ----------------------------------------------------------------------------


`timescale 1ns / 1ps


//  7 /  3 =  2,  7 %  3 =  1
//  7 / -3 = -2,  7 % -3 =  1
// -7 /  3 = -2, -7 %  3 = -1
// -7 / -3 =  2, -7 % -3 = -1


// out_quotient  <- in_data0 / in_data1
// out_remainder <- in_data0 % in_data1
module cpu_divider
		(
			reset, clk,
			in_en, in_signed,
			in_data0, in_data1,
			out_en, out_remainder, out_quotient,
			busy
		);
	
	parameter DATA_WIDTH = 32;
	
	input						reset;
	input						clk;
	
	input						in_en;
	input						in_signed;
	input	[DATA_WIDTH-1:0]	in_data0;
	input	[DATA_WIDTH-1:0]	in_data1;
	
	output						out_en;
	output	[DATA_WIDTH-1:0]	out_quotient;
	output	[DATA_WIDTH-1:0]	out_remainder;
	
	output						busy;
	
	
	// NEG
	function [DATA_WIDTH-1:0]	neg;
	input	[DATA_WIDTH-1:0]	in_data;
		begin
			neg = ~in_data + 1;
		end
	endfunction
	
	// ABS
	function [DATA_WIDTH-1:0]	abs;
	input	[DATA_WIDTH-1:0]	in_data;
		begin
			abs = in_data[DATA_WIDTH-1] ? ~in_data + 1 : in_data;
		end
	endfunction
	
	
	
	reg		[DATA_WIDTH-1:0]	remainder;
	reg		[DATA_WIDTH-1:0]	quotient;
	reg		[DATA_WIDTH-1:0]	divisor;
	
	reg							remainder_sign;
	reg							quotient_sign;
	
	wire	[DATA_WIDTH-1:0]	remainder1;
	wire	[DATA_WIDTH-1:0]	quotient1;
	
	wire	[DATA_WIDTH:0]		quotient2;
	
	reg							busy;
	reg							out_en;
	
	reg		[4:0]				counter;
	wire	[4:0]				counter_next;
	
	assign counter_next = counter + 1;
	
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			busy    <= 1'b0;
			counter <= 0;
		end
		else begin
			if ( !busy ) begin
				if ( in_en ) begin
					busy           <= 1'b1;
					
					remainder      <= {DATA_WIDTH{1'b0}};
					quotient       <= in_signed ? abs(in_data0) : in_data0;
					divisor        <= in_signed ? abs(in_data1) : in_data1;
					
					quotient_sign  <= in_signed & (in_data0[DATA_WIDTH-1] ^ in_data1[DATA_WIDTH-1]);
					remainder_sign <= in_signed & in_data0[DATA_WIDTH-1];
				end
			end
			else begin
				counter   <= counter_next;
				
				remainder <= quotient2[DATA_WIDTH] ? remainder1 : quotient2[DATA_WIDTH-1:0];
				quotient  <= quotient1;
				
				if ( counter_next == 0 ) begin
					busy   <= 1'b0;
				end
			end
			
			out_en <= (counter_next == 0);
		end
	end
	
	assign {remainder1, quotient1} = {remainder, quotient, ~quotient2[DATA_WIDTH]};
	assign quotient2               = remainder1 - divisor;
	
	
	assign out_quotient  = quotient_sign  ? neg(quotient)  : quotient;
	assign out_remainder = remainder_sign ? neg(remainder) : remainder;
	
endmodule

