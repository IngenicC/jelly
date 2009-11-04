// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   deselector
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps



// deselector
module jelly_deselector
		#(
			parameter	SEL_WIDTH = 2,
			parameter	IN_WIDTH  = 8,
			parameter	OUT_WIDTH = (IN_WIDTH  * SEL_WIDTH)
		)
		(
			input	wire	[SEL_WIDTH-1:0]		sel,
			input	wire	[IN_WIDTH-1:0]		din,
			output	reg		[OUT_WIDTH-1:0]		dout
		);
	
	integer i;
	integer j;
	always @* begin
		dout = {OUT_WIDTH{1'b0}};
		for ( i = 0; i < SEL_WIDTH; i = i + 1 ) begin
			if ( sel[i] ) begin
				for ( j = 0; j < IN_WIDTH; j = j + 1 ) begin
					dout[IN_WIDTH*i + j] = din[j];
				end
			end
		end
	end
	
endmodule


// end of file
