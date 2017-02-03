// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_writer_line_to_blk
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_SEL_WIDTH  = COMPONENT_NUM <= 2  ?  1 :
			                                   COMPONENT_NUM <= 4  ?  2 :
			                                   COMPONENT_NUM <= 8  ?  3 :
			                                   COMPONENT_NUM <= 16 ?  4 :
			                                   COMPONENT_NUM <= 32 ?  5 :
			                                   COMPONENT_NUM <= 64 ?  6 : 7,
			
			parameter	BLK_X_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	BLK_Y_SIZE           = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	STEP_Y_SIZE          = 1,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			
			parameter	X_WIDTH              = 10,
			parameter	Y_WIDTH              = 10,
			
			parameter	ADDR_WIDTH           = 24,
			parameter	S_DATA_WIDTH         = 8*3,
			parameter	M_DATA_SIZE          = 1,
			
			parameter	BUF_ADDR_WIDTH       = 1 + X_WIDTH + STEP_Y_SIZE - M_DATA_SIZE,
			parameter	BUF_RAM_TYPE         = "block"
			
			// local
			parameter	M_DATA_WIDTH         = (S_DATA_WIDTH << M_DATA_SIZE)
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire	[X_WIDTH-1:0]				param_width,
			input	wire	[Y_WIDTH-1:0]				param_height,
			
			input	wire	[S_DATA_WIDTH-1:0]			s_data,
			input	wire								s_valid,
			output	wire								s_ready,
			
			output	wire	[ADDR_WIDTH-1:0]			m_addr,
			output	wire	[M_DATA_WIDTH-1:0]			m_data,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
	
	
	
	// ---------------------------------
	//  common
	// ---------------------------------
	
	localparam	BLK_X_WIDTH = X_WIDTH - BLK_X_SIZE;
	
	wire	[BLK_X_WIDTH-1:0]	blk_x_num  = (param_width  >> BLK_X_SIZE);
	
	
	
	// ---------------------------------
	//  buffer memory
	// ---------------------------------
	
	localparam	BUF_NUM        = (1 << M_DATA_SIZE);
	localparam	BUF_UNIT_WIDTH = S_DATA_WIDTH;
	localparam	BUF_DATA_WIDTH = M_DATA_WIDTH;
	
	wire								buf_wr_cke;
	wire	[BUF_NUM-1:0]				buf_wr_en;
	wire	[BUF_NUM*ADDR_WIDTH-1:0]	buf_wr_addr;
	wire	[TAP_NUM*DATA_WIDTH-1:0]	buf_wr_din;
	
	wire								buf_rd_cke;
	wire	[ADDR_WIDTH-1:0]			buf_rd_addr;
	wire	[BUF_NUM*DATA_WIDTH-1:0]	buf_rd_dout;
	
	generate
	for ( i = 0; i < BUF_NUM; i = i+1 ) begin : loop_buf
		jelly_ram_simple_dualport
				#(
					.ADDR_WIDTH		(BUF_ADDR_WIDTH),
					.DATA_WIDTH		(BUF_UNIT_WIDTH),
					.RAM_TYPE		(BUF_RAM_TYPE),
					.DOUT_REGS		(1)
				)
			i_ram_simple_dualport
				(
					.wr_clk			(clk),
					.wr_en			(buf_wr_en[i] & buf_wr_cke),
					.wr_addr		(buf_wr_addr),
					.wr_din			(buf_wr_din[i*BUF_UNIT_WIDTH +: BUF_UNIT_WIDTH]),
					
					.rd_clk			(clk),
					.rd_en			(buf_rd_cke),
					.rd_regcke		(buf_rd_cke),
					.rd_addr		(buf_rd_addr),
					.rd_dout		(buf_rd_dout[i*BUF_UNIT_WIDTH +: BUF_UNIT_WIDTH])
				);
	end
	endgenerate
	
	
	// ---------------------------------
	//  write to buffer
	// ---------------------------------
	
	localparam	WR_PIX_X_NUM   = (1 << BLK_X_SIZE);
	localparam	WR_PIX_X_WIDTH = BLK_X_SIZE >= 0 ? BLK_X_SIZE ; 1;
	
	localparam	WR_PIX_Y_NUM   = (1 << STEP_Y_SIZE);
	localparam	WR_PIX_Y_WIDTH = STEP_Y_SIZE >= 0 ? STEP_Y_SIZE ; 1;
	
	localparam	PIX_Y_NUM      = (1 << STEP_Y_SIZE);		// �]���P�ʃu���b�N����X�����̃s�N�Z����
	
	
	reg		[WR_PIX_X_WIDTH-1:0]	wr0_x_count;
	reg								wr0_x_last;
	reg		[BLK_X_WIDTH-1:0]		wr0_blk_count;
	reg								wr0_blk_last;
	reg		[WR_PIX_Y_WIDTH-1:0]	wr0_y_count;
	reg								wr0_y_last;
	reg		[S_DATA_WIDTH-1:0]		wr0_data;
	reg								wr0_valid;
	
	wire	[BUF_ADDR_WIDTH-1:0]	wr0_addr = {st0_y_count, st0_blk_count, st0_x_count};
	wire							wr0_last = (st0_x_last && st0_blk_last && st0_y_last);
	
	reg		[ADDR_WIDTH-1:0]		wr1_base;
	reg		[ADDR_WIDTH-1:0]		wr1_addr;
	reg		[BUF_NUM-1:0]			wr1_we;
	reg								wr1_last;
	reg								wr1_data;
	reg								wr1_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			wr0_x_count   <= {WR_PIX_X_WIDTH{1'b0}};
			wr0_x_last    <= (WR_PIX_X_NUM == 1);
			wr0_blk_count <= {BLK_X_WIDTH{1'b0}};
			wr0_blk_last  <= (blk_x_num == 1);
			wr0_y_count   <= {WR_PIX_Y_WIDTH{1'b0}};
			wr0_y_last    <= (WR_PIX_Y_NUM == 1);
			wr0_data      <= {DATA_WIDTH{1'bx}};
			wr0_valid     <= 1'b0;
			
			wr1_base      <= {BUF_ADDR_WIDTH{1'b0}};
			wr1_addr      <= {BUF_ADDR_WIDTH{1'bx}};
			wr1_we        <= {BUF_NUM{1'bx}};
			wr1_last      <= 1'bx;
			wr1_data      <= {DATA_WIDTH{1'bx}};
			wr1_valid     <= 1'b0;
		end
		else if ( wr_cke ) begin
			// stage0
			if ( wr0_valid ) begin
				wr0_x_count   <= wr0_x_count + 1'b1;
				wr0_x_last    <= ((wr0_x_count + 1'b1) == (WR_PIX_X_NUM-1));
				if ( wr0_x_last ) begin
					wr0_x_count   <= {WR_PIX_X_WIDTH{1'b0}};
					wr0_x_last    <= (WR_PIX_X_NUM == 1);
					
					wr0_blk_count <= wr0_blk_count + 1'b1;
					wr0_blk_last  <= ((wr0_blk_count + 1'b1) == (blk_x_num - 1'b1));
					if ( wr0_blk_last ) begin
						wr0_blk_count <= {BLK_X_WIDTH{1'b0}};
						wr0_blk_last  <= (blk_x_num == 1);
						
						wr0_y_count   <= wr0_y_count + 1'b1;
						wr0_y_last    <= ((wr0_y_count + 1'b1) == (WR_PIX_Y_NUM - 1));
						if ( wr0_y_last ) begin
							wr0_y_count   <= {WR_PIX_Y_WIDTH{1'b0}};
							wr0_y_last    <= (WR_PIX_Y_NUM == 1);
						end
					end
				end
			end
			wr0_data  <= s_data;
			wr0_valid <= s_valid;
			
			// stage1
			if ( wr1_valid ) begin
				if ( wr1_last ) begin
					wr1_base <= wr1_addr + 1'b1;
				end
			end
			
			wr1_we    <= wr0_valid ? (1 << (wr0_addr & ~((1 << M_DATA_SIZE) - 1))) : {BUF_NUM{1'b0}};
			wr1_addr  <= wr1_base + (wr0_addr >> M_DATA_SIZE);
			wr1_last  <= wr0_last;
			wr1_data  <= wr0_data;
			wr1_valid <= wr0_valid;
		end
	end
	
	assign	buf_wr_cke  = wr_cke;
	assign	buf_wr_en   = wr1_we;
	assign	buf_wr_addr = wr1_addr;
	assign	buf_wr_din  = {BUF_NUM{wr1_data}};
	
	
	
	// ---------------------------------
	//  read from buffer
	// ---------------------------------
	
	localparam	RD_PIX_SIZE     = BLK_X_SIZE + STEP_Y_SIZE - M_DATA_SIZE;
	localparam	RD_PIX_NUM      = (1 << RD_PIX_SIZE);
	localparam	RD_PIX_WIDTH    = RD_PIX_SIZE > 0 ? RD_PIX_SIZE : 1;
	
	localparam	RD_STEP_NUM     = (1 << STEP_Y_SIZE);
	localparam	RD_STEP_WIDTH   = STEP_Y_SIZE > 0 ? STEP_Y_SIZE : 1;
	
	localparam	RD_Y_WIDTH      = Y_WIDTH - STEP_Y_SIZE;

	wire	[RD_Y_WIDTH-1:0]			blk_y_num = (param_height >> STEP_Y_SIZE);
	
	reg		[RD_PIX_WIDTH-1:0]			rd0_pix_count;
	reg									rd0_pix_last;
	reg		[COMPONENT_SEL_WIDTH-1:0]	rd0_cmp_count;
	reg									rd0_cmp_last;
	reg		[BLK_X_WIDTH-1:0]			rd0_blk_count;
	reg									rd0_blk_last;
	reg		[RD_STEP_WIDTH-1:0]			rd0_step_count;
	reg									rd0_step_last;
	reg		[RD_Y_WIDTH-1:0]			rd0_y_count;
	reg									rd0_y_last;
	wire								rd0_valid = !buf_empty;
	
	reg		[ADDR_WIDTH-1:0]			rd1_base;
	reg		[ADDR_WIDTH-1:0]			rd1_addr;
	reg									rd1_last;
	reg									rd1_data;
	reg									rd1_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			rd0_pix_count  <= {RD_PIX_WIDTH{1'b0}};
			rd0_pix_last   <= (RD_PIX_NUM == 1);
			rd0_cmp_count  <= {COMPONENT_SEL_WIDTH{1'b0}};
			rd0_cmp_last   <= (COMPONENT_NUM == 1);
			rd0_blk_count  <= {BLK_X_WIDTH{1'b0}};
			rd0_blk_last   <= (blk_x_num == 1);
			rd0_step_count <= {RD_STEP_WIDTH{1'b0}};
			rd0_step_last  <= (RD_STEP_NUM == 1);
			rd0_y_count    <= {RD_Y_WIDTH{1'b0}};
			rd0_y_last     <= (blk_y_num == 1);
			rd0_valid      <= 1'b0;
		end
		else if ( cke ) begin
			// stage0
			if ( rd0_valid ) begin
				rd0_pix_count <= rd0_pix_count + 1'b1;
				rd0_pix_last  <= ((rd0_pix_count + 1'b1) == (RD_PIX_NUM - 1));
				if ( rd0_x_last ) begin
					rd0_pix_count  <= {RD_PIX_WIDTH{1'b0}};
					rd0_pix_last   <= (RD_PIX_NUM == 1);
					
					rd0_cmp_count  <= rd0_cmp_count + 1'b1;
					rd0_cmp_last   <= ((rd0_cmp_count + 1'b1) == (COMPONENT_NUM - 1));
					if ( rd0_cmp_last ) begin
						rd0_cmp_count  <= {COMPONENT_SEL_WIDTH{1'b0}};
						rd0_cmp_last   <= (COMPONENT_NUM == 0);
						
						rd0_blk_count  <= rd0_blk_count + 1'b1;
						rd0_blk_last   <= ((rd0_blk_count + 1'b1) == (blk_x_num - 1));
						if ( rd0_blk_last ) begin
							rd0_blk_count  <= {BLK_X_WIDTH{1'b0}};
							rd0_blk_last   <= (blk_x_num == 1);
							
							rd0_step_count <= rd0_step_count + 1'b1;
							rd0_step_last  <= ((rd0_step_count + 1'b1) == (RD_STEP_NUM - 1));
							rd0_step_count <= {RD_STEP_WIDTH{1'b0}};
							rd0_step_last  <= (RD_STEP_NUM == 1);
							
					
					rd0_blk_count <= rd0_blk_count + 1'b1;
					rd0_blk_last  <= ((rd0_blk_count + 1'b1) == (param_blk_x_num - 1'b1));
					if ( rd0_blk_last ) begin
						rd0_blk_count <= {BLK_X_WIDTH{1'b0}};
						rd0_blk_last  <= (param_blk_x_num == 1);
						
						rd0_y_count   <= rd0_y_count + 1'b1;
						rd0_y_last    <= ((rd0_y_count + 1'b1) == (param_step_y_num - 1'b1));
						if ( rd0_y_last ) begin
							rd0_y_count   <= {STEP_Y_WIDTH{1'b0}};
							rd0_y_last    <= (param_step_y_num == 1);
						end
					end
				end
			end
			rd0_data  <= s_data;
			rd0_valid <= s_valid;
			
			// stage1
			if ( st1_valid ) begin
				if ( st1_last ) begin
					st1_base <= st1_addr + 1'b1;
				end
			end
			st1_addr  <= st1_base
							 + (rd0_x_count)
							 + (rd0_blk_count << (BLK_X_SIZE))
							 + (rd0_y_count   << (BLK_X_SIZE + BLK_X_WIDTH));
			st1_last  <= (rd0_x_last && rd0_blk_last && rd0_y_last);
			st1_data  <= rd0_data;
			st1_valid <= rd0_valid;
		end
	end

	
endmodule



`default_nettype wire


// end of file
