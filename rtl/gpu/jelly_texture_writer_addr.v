// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_writer_addr
		#(
			parameter	STRIDE_WIDTH    = 14,
			parameter	SIZE_WIDTH      = 24,
			
			parameter	COMPONENT_NUM   = 3,
			parameter	COMPONENT_WIDTH = COMPONENT_NUM <= 2 ?  1 :
			                              COMPONENT_NUM <= 4 ?  2 : 3,
			parameter	STEP_SIZE       = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	BLK_X_SIZE      = 2,		// 2^n (0:1, 1:2, 2:4, 3:8... )
			parameter	BLK_Y_SIZE      = 1			// 2^n (0:1, 1:2, 2:4, 3:8... )
		)
		(
			input	wire								reset,
			input	wire								clk,
			
			input	wire								enable,
			output	wire								busy,
			
			input	wire	[STRIDE_WIDTH-1:0]			param_width,
			input	wire	[STRIDE_WIDTH-1:0]			param_stride,
			input	wire	[SIZE_WIDTH-1:0]			param_size,
			
			output	wire								m_last,
			output	wire	[COMPONENT_WIDTH-1:0]		m_component,
			output	wire	[SIZE_WIDTH-1:0]			m_addr,
			output	wire								m_valid,
			input	wire								m_ready
		);
	
	localparam	STEP_STRIDE     = (1 << STEP_SIZE);
	localparam	BLK_X_STRIDE    = (1 << BLK_X_SIZE);
	localparam	BLK_Y_STRIDE    = (1 << BLK_Y_SIZE);
	
	localparam	STEP_WIDTH      = STEP_STRIDE   <= 2    ?  1 :
	                              STEP_STRIDE   <= 4    ?  2 :
	                              STEP_STRIDE   <= 8    ?  3 :
	                              STEP_STRIDE   <= 16   ?  4 :
	                              STEP_STRIDE   <= 32   ?  5 :
	                              STEP_STRIDE   <= 64   ?  6 :
	                              STEP_STRIDE   <= 128  ?  7 :
	                              STEP_STRIDE   <= 256  ?  8 :
	                              STEP_STRIDE   <= 512  ?  9 :
	                              STEP_STRIDE   <= 1024 ? 10 :
	                              STEP_STRIDE   <= 2048 ? 11 :
	                              STEP_STRIDE   <= 4096 ? 12 : 13;
	
	localparam	BLK_X_WIDTH     = STRIDE_WIDTH;
	localparam	BLK_Y_WIDTH     = (STRIDE_WIDTH + BLK_Y_SIZE);
	
	
	// cke
	wire							cke = m_ready;
	
	// stage 0
	reg		[STEP_WIDTH-1:0]		st0_step_addr;
	reg								st0_step_last;
	reg		[BLK_X_WIDTH-1:0]		st0_blkx_addr;
	reg								st0_blkx_last;
	reg		[BLK_Y_WIDTH-1:0]		st0_blky_addr;
	reg								st0_blky_last;
	reg		[COMPONENT_WIDTH-1:0]	st0_component_num;
	reg								st0_component_last;
	reg		[SIZE_WIDTH-1:0]		st0_base_addr;
	reg								st0_base_last;
	reg								st0_valid;
	
	always @(posedge clk) begin
		if ( !st0_valid ) begin
			st0_step_addr      <= {STEP_WIDTH{1'b0}};
			st0_step_last      <= (1'b1 == STEP_STRIDE);
			
			st0_blkx_addr      <= {BLK_X_WIDTH{1'b0}};
			st0_blkx_last      <= (STEP_STRIDE  == param_width);
			
			st0_blky_addr      <= {BLK_Y_WIDTH{1'b0}};
			st0_blky_last      <= (param_stride == (param_stride << BLK_Y_SIZE));

			st0_component_num  <= {COMPONENT_WIDTH{1'b0}};
			st0_component_last <= (1'b1 == COMPONENT_NUM);
			
			st0_base_addr      <= {SIZE_WIDTH{1'b0}};
			st0_base_last      <= ((param_stride << BLK_Y_SIZE) == param_size);
		end
		else if ( cke ) begin
			// step
			if ( st0_step_last ) begin
				st0_step_addr <= {STEP_WIDTH{1'b0}};
				st0_step_last <= ({STEP_WIDTH{1'b0}} == (STEP_STRIDE - 1));
			end
			else begin
				st0_step_addr <= st0_step_addr + 1'b1;
				st0_step_last <= ((st0_step_addr + 1'b1) == (STEP_STRIDE - 1));
			end
			
			// block x
			if ( st0_step_last ) begin
				if ( st0_step_last && st0_blkx_last ) begin
					st0_blkx_addr <= {BLK_X_WIDTH{1'b0}};
					st0_blkx_last <= ({BLK_X_WIDTH{1'b0}} == (param_width - STEP_STRIDE));
				end
				else begin
					st0_blkx_addr <= st0_blkx_addr + STEP_STRIDE;
					st0_blkx_last <= ((st0_blkx_addr + STEP_STRIDE) == (param_width - STEP_STRIDE));
				end
			end
			
			// block y
			if ( st0_step_last && st0_blkx_last ) begin
				if ( st0_blky_last ) begin
					st0_blky_addr <= {BLK_Y_WIDTH{1'b0}};
					st0_blky_last <= ({BLK_Y_WIDTH{1'b0}} == ((param_stride << BLK_Y_SIZE) - param_stride));
				end
				else begin
					st0_blky_addr <= st0_blky_addr + param_stride;
					st0_blky_last <= ((st0_blky_addr + param_stride) == ((param_stride << BLK_Y_SIZE) - param_stride));
				end
			end
			
			// component
			if ( st0_step_last && st0_blkx_last && st0_blky_last ) begin
				if ( st0_component_last ) begin
					st0_component_num  <= {COMPONENT_WIDTH{1'b0}};
					st0_component_last <= ({COMPONENT_WIDTH{1'b0}} == (COMPONENT_NUM - 1));
				end
				else begin
					st0_component_num  <= st0_component_num + 1'b1;
					st0_component_last <= ((st0_component_num + 1'b1) == (COMPONENT_NUM - 1));
				end
			end
				
			// base
			if ( st0_step_last && st0_blkx_last && st0_blky_last && st0_component_last ) begin
				if ( st0_base_last ) begin
					st0_base_addr <= {SIZE_WIDTH{1'b0}};
					st0_base_last <= ({SIZE_WIDTH{1'b0}} == (param_size - (param_stride << BLK_Y_SIZE)));
				end
				else begin
					st0_base_addr <= st0_base_addr + (param_stride << BLK_Y_SIZE);
					st0_base_last <= ((st0_base_addr + (param_stride << BLK_Y_SIZE)) == (param_size - (param_stride << BLK_Y_SIZE)));
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_valid <= 1'b0;
		end
		else if ( cke ) begin
			if ( !st0_valid ) begin
				if ( enable ) begin
					st0_valid <= 1'b1;
				end
			end
			else begin
				if ( st0_step_last && st0_blkx_last && st0_blky_last && st0_component_last && st0_base_last ) begin
					st0_valid <= 1'b0;
				end
			end
		end
	end

	
	/*
	// addr calc
	reg		[STEP_WIDTH-1:0]		st0_step_addr;
	reg								st0_step_last;
	reg		[BLK_X_WIDTH-1:0]		st0_blkx_addr;
	reg								st0_blkx_last;
	reg		[BLK_Y_WIDTH-1:0]		st0_blky_addr;
	reg								st0_blky_last;
	reg		[COMPONENT_WIDTH-1:0]	st0_component_num;
	reg								st0_component_last;
	reg		[SIZE_WIDTH-1:0]		st0_base_addr;
	reg								st0_base_last;
	reg								st0_valid;
	always @* begin
		next_step_addr      = st0_step_addr;
		next_blkx_addr      = st0_blkx_addr;
		next_blky_addr      = st0_blky_addr;
		next_component_num  = st0_component_num;
		next_base_addr      = st0_base_addr;
		next_valid          = st0_valid;
		
		if ( !st0_valid ) begin
			if ( enable ) begin
				// start
				next_step_addr     = {STEP_WIDTH{1'b0}};
				next_blkx_addr     = {BLK_X_WIDTH{1'b0}};
				next_blky_addr     = {BLK_Y_WIDTH{1'b0}};
				next_component_num = {COMPONENT_WIDTH{1'b0}};
				next_base_addr     = {SIZE_WIDTH{1'b0}};
				next_valid         = 1'b1;
			end
		end
		else begin
			// step
			if ( st0_step_last ) begin
				next_step_addr = {STEP_WIDTH{1'b0}};
			end
			else begin
				next_step_addr = st0_step_addr + 1'b1;
			end
			
			// block x
			if ( st0_step_last ) begin
				if ( st0_blkx_last ) begin
					next_blkx_addr = {BLK_X_WIDTH{1'b0}};
				end
				else begin
					next_blkx_addr = st0_blkx_addr + STEP_STRIDE;
				end
			end
			
			// block y
			if ( st0_blkx_last ) begin //  && st0_blkx_last && !st0_blky_last ) begin
				if ( st0_blky_last ) begin
					next_blky_addr = {BLK_Y_WIDTH{1'b0}};
				end
				else begin
					next_blky_addr = st0_blky_addr + param_stride;
				end
			end
			
			// component
			if ( st0_blky_last ) begin //  && st0_blkx_last && st0_blky_last && !st0_component_last ) begin
				if ( st0_component_last ) begin
					next_component_num = {COMPONENT_WIDTH{1'b0}};
				end
				else begin
					next_component_num = st0_component_num + 1'b1;
				end
			end
			
			// base
			if ( st0_component_last ) begin //  && st0_blkx_last && st0_blky_last && st0_component_last && !st0_base_last ) begin
				if ( st0_base_last ) begin
					next_base_addr = {SIZE_WIDTH{1'b0}};
				end
				else begin
					next_base_addr = st0_base_addr + (param_stride << BLK_Y_SIZE);
				end
			end
			
			// valid
			if ( st0_base_last ) begin //  && st0_blkx_last && st0_blky_last && st0_component_last && st0_base_last ) begin
				next_valid = 1'b0;
			end
		end
		
		// calc last 
		next_step_last      =                   ((next_step_addr     + 1'b1)                         == STEP_STRIDE);
		next_blkx_last      = next_step_last && ((next_blkx_addr     + );
		next_blky_last      = next_blkx_last && ((next_blky_addr     + 
		next_component_last = next_blky_last && ((next_component_num + 1'b1)                         == );
		next_base_last      = next_component_last && ((next_base_addr     + );
	end
	
	always @(posedge clk) begin
		if ( reset ) begin
			st0_step_addr      <= {STEP_WIDTH{1'bx}};
			st0_step_last      <= 1'bx;
			st0_blkx_addr      <= {BLK_X_WIDTH{1'bx}};
			st0_blkx_last      <= 1'bx;
//			st0_blky_addr      <= {BLK_Y_WIDTH{1'bx}};
			st0_blky_last      <= 1'bx;
			st0_component_num  <= {COMPONENT_WIDTH{1'bx}};
			st0_component_last <= 1'bx;
//			st0_base_addr      <= {SIZE_WIDTH{1'bx}};
			st0_base_last      <= 1'bx;
			st0_valid          <= 1'b0;
		end
		else if ( cke ) begin
			st0_step_addr      <= next_step_addr;
			st0_step_last      <= next_step_last;
			st0_blkx_addr      <= next_blkx_addr;
			st0_blkx_last      <= next_blkx_last;
//			st0_blky_addr      <= next_blky_addr;
			st0_blky_last      <= next_blky_last;
			st0_component_num  <= next_component_num;
			st0_component_last <= next_component_last;
//			st0_base_addr      <= next_base_addr;
			st0_base_last      <= next_base_last;
			st0_valid          <= next_valid;
		end
	end
	*/
	
	
	
	// sum address
	reg								st1_last;
	reg		[COMPONENT_WIDTH-1:0]	st1_component;
	reg		[SIZE_WIDTH-1:0]		st1_addr0;
	reg		[SIZE_WIDTH-1:0]		st1_addr1;
	reg								st1_valid;
	
	reg								st2_last;
	reg		[COMPONENT_WIDTH-1:0]	st2_component;
	reg		[SIZE_WIDTH-1:0]		st2_addr;
	reg								st2_valid;
	
	always @(posedge clk) begin
		if ( reset ) begin
			st1_last           <= 1'bx;
			st1_component      <= {COMPONENT_WIDTH{1'bx}};
			st1_addr0          <= {SIZE_WIDTH{1'bx}};
			st1_addr1          <= {SIZE_WIDTH{1'bx}};
			st1_valid          <= 1'b0;
			
			st2_last           <= 1'bx;
			st2_component      <= {COMPONENT_WIDTH{1'bx}};
			st2_addr           <= {SIZE_WIDTH{1'bx}};
			st2_valid          <= 1'b0;
		end
		else if ( cke ) begin
			// stage 1
			st1_last           <= (st0_step_last & st0_blkx_last & st0_blky_last & st0_component_last & st0_base_last);
			st1_component      <= st0_component_num;
			st1_addr0          <= st0_step_addr + st0_blkx_addr;
			st1_addr1          <= st0_blky_addr + st0_base_addr;
			st1_valid          <= st0_valid;
			
			// stage 2
			st2_last           <= st1_last;
			st2_component      <= st1_component;
			st2_addr           <= st1_addr0 + st1_addr1;
			st2_valid          <= st1_valid;
		end
	end
	
	assign busy        = st0_valid;
	
	assign m_last      = st2_last;
	assign m_component = st2_component;
	assign m_addr      = st2_addr;
	assign m_valid     = st2_valid;
	
endmodule



`default_nettype wire


// end of file