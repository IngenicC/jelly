// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_blk_addr
		#(
			parameter	USER_WIDTH   = 1,
			
			parameter	ADDR_X_WIDTH = 12,
			parameter	ADDR_Y_WIDTH = 12,
			
			parameter	BLK_X_WIDTH  = 1,
			parameter	BLK_Y_WIDTH  = 1,
			
			parameter	BLK_X_NUM    = (1 << BLK_X_WIDTH),
			parameter	BLK_Y_NUM    = (1 << BLK_Y_WIDTH)
		)
		(
			input	wire						reset,
			input	wire						clk,
			
			input	wire	[USER_WIDTH-1:0]	s_user,
			input	wire	[ADDR_X_WIDTH-1:0]	s_addr_x,
			input	wire	[ADDR_Y_WIDTH-1:0]	s_addr_y,
			input	wire						s_valid,
			output	wire						s_ready,
			
			output	wire	[USER_WIDTH-1:0]	m_user,
			output	wire						m_last,
			output	wire	[ADDR_X_WIDTH-1:0]	m_addr_x,
			output	wire	[ADDR_Y_WIDTH-1:0]	m_addr_y,
			output	wire						m_valid,
			input	wire						m_ready
		);
	
	localparam	X_WIDTH = BLK_X_WIDTH > 0 ? BLK_X_WIDTH : 1;
	localparam	Y_WIDTH = BLK_Y_WIDTH > 0 ? BLK_Y_WIDTH : 1;
	
	reg		[USER_WIDTH-1:0]	reg_user;
	reg		[ADDR_X_WIDTH-1:0]	reg_addr_x;
	reg		[ADDR_Y_WIDTH-1:0]	reg_addr_y;
	reg		[X_WIDTH-1:0]		reg_x;
	reg		[Y_WIDTH-1:0]		reg_y;
	reg							reg_valid;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_user   <= {USER_WIDTH{1'bx}};
			reg_addr_x <= {ADDR_X_WIDTH{1'bx}};
			reg_addr_y <= {ADDR_Y_WIDTH{1'bx}};
			reg_x      <= {X_WIDTH{1'bx}};
			reg_y      <= {Y_WIDTH{1'bx}};
			reg_valid  <= 1'b0;
		end
		else begin
			if ( m_valid && m_ready ) begin
				reg_x <= reg_x + 1'b1;
				if ( reg_x == (BLK_X_NUM-1) ) begin
					reg_x <= {X_WIDTH{1'b0}};
					reg_y <= reg_y + 1'b1;
					if ( reg_y == (BLK_Y_NUM-1) ) begin
						reg_user   <= {USER_WIDTH{1'bx}};
						reg_x      <= {X_WIDTH{1'bx}};
						reg_y      <= {Y_WIDTH{1'bx}};
						reg_valid  <= 1'b0;
					end
				end
			end
			
			if ( s_valid & s_ready ) begin
				reg_user   <= s_user;
				reg_addr_x <= s_addr_x;
				reg_addr_y <= s_addr_y;
				reg_x      <= {X_WIDTH{1'b0}};
				reg_y      <= {Y_WIDTH{1'b0}};
				reg_valid  <= 1'b1;
			end
		end
	end
	
	assign s_ready  = (!reg_valid || (m_ready && (reg_x == (BLK_X_NUM-1)) && (reg_y == (BLK_Y_NUM-1))));
	
	assign m_user   = reg_user;
	assign m_last   = ((reg_x == (BLK_X_NUM-1)) && (reg_y == (BLK_Y_NUM-1)));
	assign m_addr_x = reg_addr_x + reg_x;
	assign m_addr_y = reg_addr_y + reg_y;
	assign m_valid  = reg_valid;
	
	
endmodule



`default_nettype wire


// end of file
