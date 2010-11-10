// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    UART
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


module jelly_uart_rx
		(
			// system
			input	wire			reset,
			input	wire			clk,
			
			// UART
			input	wire			uart_rx,
			
			// control
			output	wire	[7:0]	rx_data,
			output	wire			rx_valid
		);
	
	// recv
	reg							rx_ff_buf;
	reg		[8:0]				rx_buf;
	reg							rx_busy;
	reg		[7:0]				rx_count;
	reg							rx_wr_valid;
	always @ ( posedge clk or posedge reset ) begin
		if ( reset ) begin
			rx_ff_buf   <= 1'b1;
			rx_buf      <= {9{1'bx}};
			rx_busy     <= 1'b0;
			rx_count    <= 0;
			rx_wr_valid <= 1'b0;
		end
		else begin
			rx_ff_buf <= uart_rx;
			
			if ( !rx_busy ) begin
				rx_wr_valid <= 1'b0;
				if ( rx_ff_buf == 1'b0 ) begin
					rx_busy  <= 1'b1;
					rx_count <= 0;
				end
			end
			else begin
				rx_count <= rx_count + 1;
				if ( rx_count[2:0] == 3'h3 ) begin
					rx_buf <= {rx_ff_buf, rx_buf[8:1]};
					if ( rx_count[6:3] == 9 ) begin
						rx_busy     <= 1'b0;
						rx_wr_valid <= 1'b1;
					end
				end
			end
		end
	end
	
	assign rx_valid = rx_wr_valid;
	assign rx_data  = rx_buf[7:0];
	
endmodule


`default_nettype wire


// end of file