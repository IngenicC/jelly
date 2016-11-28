// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_cache_tag
		#(
			parameter	USER_WIDTH       = 1,
			
			parameter	S_ADDR_X_WIDTH   = 12,
			parameter	S_ADDR_Y_WIDTH   = 12,
			parameter	S_DATA_WIDTH     = 24,
			
			parameter	TAG_ADDR_WIDTH   = 6,
			parameter	TAG_X_RSHIFT     = 0,
			parameter	TAG_X_LSHIFT     = 0,
			parameter	TAG_Y_RSHIFT     = TAG_X_RSHIFT,
			parameter	TAG_Y_LSHIFT     = TAG_ADDR_WIDTH / 2,
			
			parameter	BLK_X_SIZE       = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	BLK_Y_SIZE       = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			
			parameter	PIX_ADDR_X_WIDTH = BLK_X_SIZE,
			parameter	PIX_ADDR_Y_WIDTH = BLK_Y_SIZE,
			parameter	BLK_ADDR_X_WIDTH = S_ADDR_X_WIDTH - BLK_X_SIZE,
			parameter	BLK_ADDR_Y_WIDTH = S_ADDR_Y_WIDTH - BLK_Y_SIZE,
			
			parameter	RAM_TYPE         = "distributed",
			
			parameter	USE_BORDER       = 1,
			
			parameter	LOG_ENABLE       = 0,
			parameter	LOG_FILE         = "cache_log.txt",
			parameter	LOG_ID           = 0         
		)
		(
			input	wire							reset,
			input	wire							clk,
			
			input	wire							clear_start,
			output	wire							clear_busy,
			
			input	wire	[S_ADDR_X_WIDTH-1:0]	param_width,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	param_height,
			
			input	wire	[USER_WIDTH-1:0]		s_user,
			input	wire	[S_ADDR_X_WIDTH-1:0]	s_addrx,
			input	wire	[S_ADDR_Y_WIDTH-1:0]	s_addry,
			input	wire							s_valid,
			output	wire							s_ready,
			
			output	wire	[USER_WIDTH-1:0]		m_user,
			output	wire	[TAG_ADDR_WIDTH-1:0]	m_tag_addr,
			output	wire	[PIX_ADDR_X_WIDTH-1:0]	m_pix_addrx,
			output	wire	[PIX_ADDR_Y_WIDTH-1:0]	m_pix_addry,
			output	wire	[BLK_ADDR_X_WIDTH-1:0]	m_blk_addrx,
			output	wire	[BLK_ADDR_Y_WIDTH-1:0]	m_blk_addry,
			output	wire							m_cache_hit,
			output	wire							m_range_out,
			output	wire							m_valid,
			input	wire							m_ready
		);
	
	
	// debug
	integer	iTAG_ADDR_WIDTH   = TAG_ADDR_WIDTH;
	integer	iTAG_X_RSHIFT     = TAG_X_RSHIFT;
	integer	iTAG_X_LSHIFT     = TAG_X_LSHIFT;
	integer	iTAG_Y_RSHIFT     = TAG_Y_RSHIFT;
	integer	iTAG_Y_LSHIFT     = TAG_Y_LSHIFT;
	
	
	
	// ---------------------------------
	//  TAG RAM
	// ---------------------------------
	
	wire							cke;
	
	reg								reg_clear_busy;
	reg								reg_read_busy;
	
	reg		[USER_WIDTH-1:0]		st0_user;
	reg								st0_tag_we;
	reg		[TAG_ADDR_WIDTH-1:0]	st0_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]	st0_pix_addrx;
	reg		[PIX_ADDR_Y_WIDTH-1:0]	st0_pix_addry;
	reg		[BLK_ADDR_X_WIDTH-1:0]	st0_blk_addrx;
	reg		[BLK_ADDR_Y_WIDTH-1:0]	st0_blk_addry;
	reg								st0_range_out;
	reg								st0_valid;
	
	reg		[USER_WIDTH-1:0]		st1_user;
	reg		[TAG_ADDR_WIDTH-1:0]	st1_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]	st1_pix_addrx;
	reg		[PIX_ADDR_Y_WIDTH-1:0]	st1_pix_addry;
	reg		[BLK_ADDR_X_WIDTH-1:0]	st1_blk_addrx;
	reg		[BLK_ADDR_Y_WIDTH-1:0]	st1_blk_addry;
	reg								st1_range_out;
	reg								st1_valid;
	
	wire							read_tag_enable;
	wire	[BLK_ADDR_X_WIDTH-1:0]	read_blk_addrx;
	wire	[BLK_ADDR_Y_WIDTH-1:0]	read_blk_addry;
	
	reg		[USER_WIDTH-1:0]		st2_user;
	reg		[TAG_ADDR_WIDTH-1:0]	st2_tag_addr;
	reg		[PIX_ADDR_X_WIDTH-1:0]	st2_pix_addrx;
	reg		[PIX_ADDR_Y_WIDTH-1:0]	st2_pix_addry;
	reg		[BLK_ADDR_X_WIDTH-1:0]	st2_blk_addrx;
	reg		[BLK_ADDR_Y_WIDTH-1:0]	st2_blk_addry;
	reg								st2_range_out;
	reg								st2_cache_hit;
	reg								st2_valid;
	
	
	// TAG-RAM
	jelly_ram_singleport
			#(
				.ADDR_WIDTH			(TAG_ADDR_WIDTH),
				.DATA_WIDTH			(1 + BLK_ADDR_X_WIDTH + BLK_ADDR_Y_WIDTH),
				.RAM_TYPE			(RAM_TYPE),
				.DOUT_REGS			(0),
				.MODE				("READ_FIRST"),
				
				.FILLMEM			(1),
				.FILLMEM_DATA		(0)
			)
		i_ram_singleport
			(
				.clk				(clk),
				.en					(cke),
				.regcke				(cke),
				
				.we					(st0_tag_we),
				.addr				(st0_tag_addr),
				.din				({~reg_clear_busy, st0_blk_addry, st0_blk_addrx}),
				.dout				({read_tag_enable, read_blk_addry, read_blk_addrx})
			);
	
	
	wire	[PIX_ADDR_X_WIDTH-1:0]	s_pix_addrx = s_addrx[BLK_X_SIZE-1:0];
	wire	[PIX_ADDR_Y_WIDTH-1:0]	s_pix_addry = s_addry[BLK_Y_SIZE-1:0];
	wire	[BLK_ADDR_X_WIDTH-1:0]	s_blk_addrx = s_addrx[S_ADDR_X_WIDTH-1:BLK_X_SIZE];
	wire	[BLK_ADDR_Y_WIDTH-1:0]	s_blk_addry = s_addry[S_ADDR_Y_WIDTH-1:BLK_Y_SIZE];
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_clear_busy <= 1'b0;
			reg_read_busy  <= 1'b0;
			
			st0_user      <= {USER_WIDTH{1'bx}};
			st0_tag_we    <= 1'b0;
			st0_tag_addr  <= {TAG_ADDR_WIDTH{1'bx}};
			st0_pix_addrx <= {PIX_ADDR_X_WIDTH{1'bx}};
			st0_pix_addry <= {PIX_ADDR_Y_WIDTH{1'bx}};
			st0_blk_addrx <= {BLK_ADDR_X_WIDTH{1'bx}};
			st0_blk_addry <= {BLK_ADDR_Y_WIDTH{1'bx}};
			st0_range_out <= 1'bx;
			st0_valid     <= 1'b0;
			
			st1_user      <= {USER_WIDTH{1'bx}};
			st1_tag_addr  <= {TAG_ADDR_WIDTH{1'bx}};
			st1_pix_addrx <= {PIX_ADDR_X_WIDTH{1'bx}};
			st1_pix_addry <= {PIX_ADDR_Y_WIDTH{1'bx}};
			st1_blk_addrx <= {BLK_ADDR_X_WIDTH{1'bx}};
			st1_blk_addry <= {BLK_ADDR_Y_WIDTH{1'bx}};
			st1_range_out <= 1'bx;
			st1_valid     <= 1'b0;
			
			st2_user      <= {USER_WIDTH{1'bx}};
			st2_tag_addr  <= {TAG_ADDR_WIDTH{1'bx}};
			st2_pix_addrx <= {PIX_ADDR_X_WIDTH{1'bx}};
			st2_pix_addry <= {PIX_ADDR_Y_WIDTH{1'bx}};
			st2_blk_addrx <= {BLK_ADDR_X_WIDTH{1'bx}};
			st2_blk_addry <= {BLK_ADDR_Y_WIDTH{1'bx}};
			st2_cache_hit <= 1'b0;
			st2_range_out <= 1'bx;
			st2_valid     <= 1'b0;
		end
		else if ( cke ) begin
			// stage0
			if ( reg_clear_busy ) begin
				// clear next
				st0_tag_addr <= st1_tag_addr + 1'b1;
				
				// clear end
				if ( st0_tag_addr == {TAG_ADDR_WIDTH{1'b1}} ) begin
					reg_clear_busy <= 1'b0;
				end
			end
			else if ( clear_start ) begin
				// start cache clear
				reg_clear_busy <= 1'b1;
				st0_tag_addr   <= {TAG_ADDR_WIDTH{1'b0}};
				st0_tag_we     <= 1'b1;
			end
			st0_user      <= s_user;
			st0_tag_we    <= (s_valid && (!USE_BORDER || (s_addrx < param_width && s_addry < param_height)));
			st0_tag_addr  <= ((s_blk_addrx >> TAG_X_RSHIFT) << TAG_X_LSHIFT) + ((s_blk_addry >> TAG_Y_RSHIFT) << TAG_Y_LSHIFT);
			st0_blk_addrx <= s_blk_addrx;
			st0_blk_addry <= s_blk_addry;
			st0_pix_addrx <= s_pix_addrx;
			st0_pix_addry <= s_pix_addry;
			st0_range_out <= (USE_BORDER && (s_addrx >= param_width || s_addry >= param_height));
			st0_valid     <= s_valid;
			
			// stage1
			st1_user      <= st0_user;
			st1_tag_addr  <= st0_tag_addr;
			st1_blk_addrx <= st0_blk_addrx;
			st1_blk_addry <= st0_blk_addry;
			st1_pix_addrx <= st0_pix_addrx;
			st1_pix_addry <= st0_pix_addry;
			st1_range_out <= st0_range_out;
			st1_valid     <= st0_valid;
			
			// stage 2
			st2_user      <= st1_user;
			st2_tag_addr  <= st1_tag_addr;
			st2_blk_addrx <= st1_blk_addrx;
			st2_blk_addry <= st1_blk_addry;
			st2_pix_addrx <= st1_pix_addrx;
			st2_pix_addry <= st1_pix_addry;
			st2_range_out <= st1_range_out;
			st2_cache_hit <= (read_tag_enable && ({st1_blk_addry, st1_blk_addrx} == {read_blk_addry, read_blk_addrx}));
			st2_valid     <= st1_valid;
		end
	end
	
	assign clear_busy      = reg_read_busy;
	
	// output
	jelly_pipeline_insert_ff
			#(
				.DATA_WIDTH			(USER_WIDTH+TAG_ADDR_WIDTH+PIX_ADDR_X_WIDTH+PIX_ADDR_Y_WIDTH+BLK_ADDR_X_WIDTH+BLK_ADDR_Y_WIDTH+1+1),
				.SLAVE_REGS			(0),
				.MASTER_REGS		(0)
			)
		i_pipeline_insert_ff
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(1'b1),
				
				.s_data				({
										st2_user,
										st2_tag_addr,
										st2_pix_addrx,
										st2_pix_addry,
										st2_blk_addrx,
										st2_blk_addry,
										st2_cache_hit,
										st2_range_out
									}),
				.s_valid			(st2_valid),
				.s_ready			(cke),
				
				.m_data				({
										m_user,
										m_tag_addr,
										m_pix_addrx,
										m_pix_addry,
										m_blk_addrx,
										m_blk_addry,
										m_cache_hit,
										m_range_out
									}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.buffered			(),
				.s_ready_next		()
			);
	
	assign s_ready = cke;
	
	
	// Log
	generate
	if ( LOG_ENABLE ) begin : blk_log
		integer	fp;
		
		initial begin
			fp = $fopen(LOG_FILE, "w");
			if ( fp != 0 ) begin
				$fclose(fp);
			end
		end
		
		always @(posedge clk) begin
			if ( !reset ) begin
				if ( cke ) begin
					if ( st1_valid && read_tag_enable && ({st1_blk_addry, st1_blk_addrx} != {read_blk_addry, read_blk_addrx}) ) begin
						fp = $fopen(LOG_FILE, "a");
						if ( fp != 0 ) begin
							$fdisplay(fp, "[%d] tag:%h (%d, %d) <= (%d,%d)", LOG_ID, st1_tag_addr, st1_blk_addry, st1_blk_addrx, read_blk_addry, read_blk_addrx);
						end
						$fclose(fp);
					end
					else if ( st1_valid && !read_tag_enable ) begin
						fp = $fopen(LOG_FILE, "a");
						if ( fp != 0 ) begin
							$fdisplay(fp, "[%d] tag:%h (%d, %d) ", LOG_ID, st1_tag_addr, st1_blk_addry, st1_blk_addrx);
						end
						$fclose(fp);
					end
				end
			end
		end
	end
	endgenerate
	
endmodule



`default_nettype wire


// end of file
