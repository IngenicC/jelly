// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// demultiplexer
module jelly_demultiplexer
		#(
			parameter	SEL_WIDTH = 2,
			parameter	NUM       = (1 << SEL_WIDTH),
			parameter	IN_WIDTH  = 8,
			parameter	OUT_WIDTH = (IN_WIDTH  * NUM)
		)
		(
			input	wire						endian,
			input	wire	[SEL_WIDTH-1:0]		sel,
			input	wire	[IN_WIDTH-1:0]		din,
			output	reg		[OUT_WIDTH-1:0]		dout
		);
	
	integer i;
	integer j;
	always @* begin
		dout = {OUT_WIDTH{1'b0}};
		for ( i = 0; i < NUM; i = i + 1 ) begin
			if ( i == (sel ^ {SEL_WIDTH{endian}}) ) begin
				for ( j = 0; j < IN_WIDTH; j = j + 1 ) begin
					dout[IN_WIDTH*i + j] = din[j];
				end
			end
		end
	end
	
endmodule


`default_nettype wire


// end of file
