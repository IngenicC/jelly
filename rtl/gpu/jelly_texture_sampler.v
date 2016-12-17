// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_texture_sampler
		#(
			parameter	COMPONENT_NUM                 = 3,
			parameter	DATA_WIDTH                    = 8,
			parameter	ADDR_WIDTH                    = 24,
			parameter	ADDR_X_WIDTH                  = 12,
			parameter	ADDR_Y_WIDTH                  = 12,
			
			parameter	USE_BORDER                    = 1,
			parameter	BORDER_DATA                   = {(COMPONENT_NUM*DATA_WIDTH){1'b0}},
			
			parameter	SAMPLER1D_NUM                 = 0,
			
			parameter	SAMPLER2D_NUM                 = 8,
			parameter	SAMPLER2D_USER_WIDTH          = 0,
			parameter	SAMPLER2D_X_INT_WIDTH         = ADDR_X_WIDTH,
			parameter	SAMPLER2D_X_FRAC_WIDTH        = 4,
			parameter	SAMPLER2D_Y_INT_WIDTH         = ADDR_Y_WIDTH,
			parameter	SAMPLER2D_Y_FRAC_WIDTH        = 4,
			parameter	SAMPLER2D_COEFF_INT_WIDTH     = 1,
			parameter	SAMPLER2D_COEFF_FRAC_WIDTH    = SAMPLER2D_X_FRAC_WIDTH + SAMPLER2D_Y_FRAC_WIDTH,
			parameter	SAMPLER2D_S_REGS              = 1,
			parameter	SAMPLER2D_M_REGS              = 1,
			parameter	SAMPLER2D_USER_FIFO_PTR_WIDTH = 6,
			parameter	SAMPLER2D_USER_FIFO_RAM_TYPE  = "distributed",
			parameter	SAMPLER2D_USER_FIFO_M_REGS    = 0,
			parameter	SAMPLER2D_X_WIDTH             = SAMPLER2D_X_INT_WIDTH + SAMPLER2D_X_FRAC_WIDTH,
			parameter	SAMPLER2D_Y_WIDTH             = SAMPLER2D_Y_INT_WIDTH + SAMPLER2D_Y_FRAC_WIDTH,
			parameter	SAMPLER2D_COEFF_WIDTH         = SAMPLER2D_COEFF_INT_WIDTH + SAMPLER2D_COEFF_FRAC_WIDTH,
			parameter	SAMPLER2D_USER_BITS           = SAMPLER2D_USER_WIDTH > 0 ? SAMPLER2D_USER_WIDTH : 1,
			
			parameter	SAMPLER3D_NUM                 = 0,
			
			parameter	L1_CACHE_NUM                  = SAMPLER1D_NUM + SAMPLER2D_NUM + SAMPLER3D_NUM,
			parameter	L1_USE_LOOK_AHEAD             = 0,
			parameter	L1_TAG_ADDR_WIDTH             = 6,
			parameter	L1_BLK_X_SIZE                 = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L1_BLK_Y_SIZE                 = 2,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L1_TAG_RAM_TYPE               = "distributed",
			parameter	L1_MEM_RAM_TYPE               = "block",
			parameter	L1_DATA_WIDE_SIZE             = 2,
			
			parameter	L2_CACHE_X_SIZE               = 1,
			parameter	L2_CACHE_Y_SIZE               = 1,
			parameter	L2_CACHE_NUM                  = (1 << (L2_CACHE_X_SIZE + L2_CACHE_Y_SIZE)),
			parameter	L2_USE_LOOK_AHEAD             = 0,
			parameter	L2_TAG_ADDR_WIDTH             = 6,
			parameter	L2_BLK_X_SIZE                 = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L2_BLK_Y_SIZE                 = 3,	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
			parameter	L2_TAG_RAM_TYPE               = "distributed",
			parameter	L2_MEM_RAM_TYPE               = "block",
			
			parameter	M_AXI4_ID_WIDTH               = 6,
			parameter	M_AXI4_ADDR_WIDTH             = 32,
			parameter	M_AXI4_DATA_SIZE              = 3,	// 0:8bit, 1:16bit, 2:32bit, 3:64bit ...
			parameter	M_AXI4_DATA_WIDTH             = (8 << M_AXI4_DATA_SIZE),
			parameter	M_AXI4_LEN_WIDTH              = 8,
			parameter	M_AXI4_QOS_WIDTH              = 4,
			parameter	M_AXI4_ARID                   = {M_AXI4_ID_WIDTH{1'b0}},
			parameter	M_AXI4_ARSIZE                 = M_AXI4_DATA_SIZE,
			parameter	M_AXI4_ARBURST                = 2'b01,
			parameter	M_AXI4_ARLOCK                 = 1'b0,
			parameter	M_AXI4_ARCACHE                = 4'b0001,
			parameter	M_AXI4_ARPROT                 = 3'b000,
			parameter	M_AXI4_ARQOS                  = 0,
			parameter	M_AXI4_ARREGION               = 4'b0000,
			parameter	M_AXI4_REGS                   = 1,
			
			parameter	DEVICE                        = "7SERIES",	// "RTL",

			parameter	L1_LOG_ENABLE                 = 0,
			parameter	L1_LOG_FILE                   = "l1_log.txt",
			parameter	L1_LOG_ID                     = 0,
			parameter	L2_LOG_ENABLE                 = 0,
			parameter	L2_LOG_FILE                   = "l2_log.txt",
			parameter	L2_LOG_ID                     = 0
		)
		(
			// system
			input	wire													reset,
			input	wire													clk,
			input	wire													endian,
			
			// parameter
			input	wire	[M_AXI4_ADDR_WIDTH*COMPONENT_NUM-1:0]			param_addr,
			input	wire	[ADDR_X_WIDTH-1:0]								param_width,
			input	wire	[ADDR_Y_WIDTH-1:0]								param_height,
			input	wire	[ADDR_WIDTH-1:0]								param_stride,
			
			// control
			input	wire													clear_start,
			output	wire													clear_busy,
			
			// 2D sampler
			input	wire	[SAMPLER2D_NUM*SAMPLER2D_USER_BITS-1:0]			s_sampler2d_user,
			input	wire	[SAMPLER2D_NUM*SAMPLER2D_X_WIDTH-1:0]			s_sampler2d_x,
			input	wire	[SAMPLER2D_NUM*SAMPLER2D_Y_WIDTH-1:0]			s_sampler2d_y,
			input	wire	[SAMPLER2D_NUM-1:0]								s_sampler2d_valid,
			output	wire	[SAMPLER2D_NUM-1:0]								s_sampler2d_ready,
			
			output	wire	[SAMPLER2D_NUM*SAMPLER2D_USER_BITS-1:0]			m_sampler2d_user,
			output	wire	[SAMPLER2D_NUM*COMPONENT_NUM*DATA_WIDTH-1:0]	m_sampler2d_data,
			output	wire	[SAMPLER2D_NUM-1:0]								m_sampler2d_valid,
			input	wire	[SAMPLER2D_NUM-1:0]								m_sampler2d_ready,
			
			
			// AXI4 read (master)
			output	wire	[M_AXI4_ID_WIDTH-1:0]							m_axi4_arid,
			output	wire	[M_AXI4_ADDR_WIDTH-1:0]							m_axi4_araddr,
			output	wire	[M_AXI4_LEN_WIDTH-1:0]							m_axi4_arlen,
			output	wire	[2:0]											m_axi4_arsize,
			output	wire	[1:0]											m_axi4_arburst,
			output	wire	[0:0]											m_axi4_arlock,
			output	wire	[3:0]											m_axi4_arcache,
			output	wire	[2:0]											m_axi4_arprot,
			output	wire	[M_AXI4_QOS_WIDTH-1:0]							m_axi4_arqos,
			output	wire	[3:0]											m_axi4_arregion,
			output	wire													m_axi4_arvalid,
			input	wire													m_axi4_arready,
			input	wire	[M_AXI4_ID_WIDTH-1:0]							m_axi4_rid,
			input	wire	[M_AXI4_DATA_WIDTH-1:0]							m_axi4_rdata,
			input	wire	[1:0]											m_axi4_rresp,
			input	wire													m_axi4_rlast,
			input	wire													m_axi4_rvalid,
			output	wire													m_axi4_rready
		);
	
	genvar		i;
	
	// -------------------------------------------------
	//  1D sampler
	// -------------------------------------------------
	
	// ���̂����K�v�ɂȂ�����l����
	
	
	
	// -------------------------------------------------
	//  2D sampler
	// -------------------------------------------------
	
	wire	[SAMPLER2D_NUM*SAMPLER2D_COEFF_WIDTH-1:0]		sampler2d_arcoeff;
	wire	[SAMPLER2D_NUM*SAMPLER2D_X_INT_WIDTH-1:0]		sampler2d_araddrx;
	wire	[SAMPLER2D_NUM*SAMPLER2D_Y_INT_WIDTH-1:0]		sampler2d_araddry;
	wire	[SAMPLER2D_NUM-1:0]								sampler2d_arvalid;
	wire	[SAMPLER2D_NUM-1:0]								sampler2d_arready;
	wire	[SAMPLER2D_NUM*SAMPLER2D_COEFF_WIDTH-1:0]		sampler2d_rcoeff;	// ruser
	wire	[SAMPLER2D_NUM*COMPONENT_NUM*DATA_WIDTH-1:0]	sampler2d_rdata;
	wire	[SAMPLER2D_NUM-1:0]								sampler2d_rvalid;
	wire	[SAMPLER2D_NUM-1:0]								sampler2d_rready;
	
	generate
	for ( i = 0; i < SAMPLER2D_NUM; i = i+1 ) begin : loop_2d
		jelly_bilinear_unit
				#(
					.COMPONENT_NUM			(COMPONENT_NUM),
					.DATA_WIDTH				(DATA_WIDTH),
					.USER_WIDTH				(SAMPLER2D_USER_WIDTH),
					.X_INT_WIDTH			(SAMPLER2D_X_INT_WIDTH),
					.X_FRAC_WIDTH			(SAMPLER2D_X_FRAC_WIDTH),
					.Y_INT_WIDTH			(SAMPLER2D_Y_INT_WIDTH),
					.Y_FRAC_WIDTH			(SAMPLER2D_Y_FRAC_WIDTH),
					.COEFF_INT_WIDTH		(SAMPLER2D_COEFF_INT_WIDTH),
					.COEFF_FRAC_WIDTH		(SAMPLER2D_COEFF_FRAC_WIDTH),
					.S_REGS					(SAMPLER2D_S_REGS),
					.M_REGS					(SAMPLER2D_M_REGS),
					.USER_FIFO_PTR_WIDTH	(SAMPLER2D_USER_FIFO_PTR_WIDTH),
					.USER_FIFO_RAM_TYPE		(SAMPLER2D_USER_FIFO_RAM_TYPE),
					.USER_FIFO_M_REGS		(SAMPLER2D_USER_FIFO_M_REGS),
					.DEVICE					(DEVICE)
				)
			i_bilinear_unit
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(1'b1),
					
					.s_user					(s_sampler2d_user [i*SAMPLER2D_USER_BITS      +: SAMPLER2D_USER_BITS]),
					.s_x					(s_sampler2d_x    [i*SAMPLER2D_X_WIDTH        +: SAMPLER2D_X_WIDTH]),
					.s_y					(s_sampler2d_y    [i*SAMPLER2D_Y_WIDTH        +: SAMPLER2D_Y_WIDTH]),
					.s_valid				(s_sampler2d_valid[i]),
					.s_ready				(s_sampler2d_ready[i]),
					.m_user					(m_sampler2d_user [i*SAMPLER2D_USER_BITS      +: SAMPLER2D_USER_BITS]),
					.m_data					(m_sampler2d_data [i*COMPONENT_NUM*DATA_WIDTH +: COMPONENT_NUM*DATA_WIDTH]),
					.m_valid				(m_sampler2d_valid[i]),
					.m_ready				(m_sampler2d_ready[i]),
					
					.m_mem_arcoeff			(sampler2d_arcoeff[i*SAMPLER2D_COEFF_WIDTH    +: SAMPLER2D_COEFF_WIDTH]),
					.m_mem_araddrx			(sampler2d_araddrx[i*SAMPLER2D_X_INT_WIDTH    +: SAMPLER2D_X_INT_WIDTH]),
					.m_mem_araddry			(sampler2d_araddry[i*SAMPLER2D_Y_INT_WIDTH    +: SAMPLER2D_Y_INT_WIDTH]),
					.m_mem_arvalid			(sampler2d_arvalid[i]),
					.m_mem_arready			(sampler2d_arready[i]),
					.m_mem_rcoeff			(sampler2d_rcoeff [i*SAMPLER2D_COEFF_WIDTH    +: SAMPLER2D_COEFF_WIDTH]),
					.m_mem_rdata			(sampler2d_rdata  [i*COMPONENT_NUM*DATA_WIDTH +: COMPONENT_NUM*DATA_WIDTH]),
					.m_mem_rvalid			(sampler2d_rvalid [i]),
					.m_mem_rready			(sampler2d_rready [i])
				);
	end
	endgenerate
	
	
	// -------------------------------------------------
	//  3D sampler
	// -------------------------------------------------
	
	// ��������̂��H
	
	
	
	
	// -------------------------------------------------
	//  Texture cache
	// -------------------------------------------------
	
	jelly_texture_cache_core
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(DATA_WIDTH),
				
				.USER_WIDTH				(SAMPLER2D_COEFF_WIDTH),
				.USE_S_RREADY			(1),			// 0: s_rready is always 1'b1.   1: handshake mode.
				.USE_BORDER				(USE_BORDER),
				.BORDER_DATA			(BORDER_DATA),
				
				.ADDR_WIDTH				(ADDR_WIDTH),				
				.ADDR_X_WIDTH			(ADDR_X_WIDTH),
				.ADDR_Y_WIDTH			(ADDR_Y_WIDTH),
				
				.L1_CACHE_NUM			(L1_CACHE_NUM),
				.L1_USE_LOOK_AHEAD		(L1_USE_LOOK_AHEAD),
				.L1_TAG_ADDR_WIDTH		(L1_TAG_ADDR_WIDTH),
				.L1_BLK_X_SIZE			(L1_BLK_X_SIZE),
				.L1_BLK_Y_SIZE			(L1_BLK_Y_SIZE),
				.L1_TAG_RAM_TYPE		(L1_TAG_RAM_TYPE),
				.L1_MEM_RAM_TYPE		(L1_MEM_RAM_TYPE),
				.L1_DATA_WIDE_SIZE		(L1_DATA_WIDE_SIZE),
				.L1_LOG_ENABLE			(L1_LOG_ENABLE),
				.L1_LOG_FILE			(L1_LOG_FILE),
				.L1_LOG_ID				(L1_LOG_ID),
				
				.L2_CACHE_X_SIZE		(L2_CACHE_X_SIZE),
				.L2_CACHE_Y_SIZE		(L2_CACHE_Y_SIZE),
				.L2_CACHE_NUM			(L2_CACHE_NUM),
				.L2_USE_LOOK_AHEAD		(L2_USE_LOOK_AHEAD),
				.L2_TAG_ADDR_WIDTH		(L2_TAG_ADDR_WIDTH),
				.L2_BLK_X_SIZE			(L2_BLK_X_SIZE),
				.L2_BLK_Y_SIZE			(L2_BLK_Y_SIZE),
				.L2_TAG_RAM_TYPE		(L2_TAG_RAM_TYPE),
				.L2_MEM_RAM_TYPE		(L2_MEM_RAM_TYPE),
				.L2_LOG_ENABLE			(L2_LOG_ENABLE),
				.L2_LOG_FILE			(L2_LOG_FILE),
				.L2_LOG_ID				(L2_LOG_ID),
				
				.M_AXI4_ID_WIDTH		(M_AXI4_ID_WIDTH),
				.M_AXI4_ADDR_WIDTH		(M_AXI4_ADDR_WIDTH),
				.M_AXI4_DATA_SIZE		(M_AXI4_DATA_SIZE),
				.M_AXI4_DATA_WIDTH		(M_AXI4_DATA_WIDTH),
				.M_AXI4_LEN_WIDTH		(M_AXI4_LEN_WIDTH),
				.M_AXI4_QOS_WIDTH		(M_AXI4_QOS_WIDTH),
				.M_AXI4_ARID			(M_AXI4_ARID),
				.M_AXI4_ARSIZE			(M_AXI4_ARSIZE),
				.M_AXI4_ARBURST			(M_AXI4_ARBURST),
				.M_AXI4_ARLOCK			(M_AXI4_ARLOCK),
				.M_AXI4_ARCACHE			(M_AXI4_ARCACHE),
				.M_AXI4_ARPROT			(M_AXI4_ARPROT),
				.M_AXI4_ARQOS			(M_AXI4_ARQOS),
				.M_AXI4_ARREGION		(M_AXI4_ARREGION),
				.M_AXI4_REGS			(M_AXI4_REGS)				                         
			)
		i_texture_cache_core
			(
				.reset					(reset),
				.clk					(clk),
				
				.endian					(endian),
				
				.param_addr				(param_addr),
				.param_width			(param_width),
				.param_height			(param_height),
				.param_stride			(param_stride),
				                         
				.clear_start			(clear_start),
				.clear_busy				(clear_busy),
				
				.s_aruser				(sampler2d_arcoeff),
				.s_araddrx				(sampler2d_araddrx),
				.s_araddry				(sampler2d_araddry),
				.s_arvalid				(sampler2d_arvalid),
				.s_arready				(sampler2d_arready),
				.s_ruser				(sampler2d_rcoeff),
				.s_rdata				(sampler2d_rdata),
				.s_rvalid				(sampler2d_rvalid),
				.s_rready				(sampler2d_rready),
				
				.m_axi4_arid			(m_axi4_arid),
				.m_axi4_araddr			(m_axi4_araddr),
				.m_axi4_arlen			(m_axi4_arlen),
				.m_axi4_arsize			(m_axi4_arsize),
				.m_axi4_arburst			(m_axi4_arburst),
				.m_axi4_arlock			(m_axi4_arlock),
				.m_axi4_arcache			(m_axi4_arcache),
				.m_axi4_arprot			(m_axi4_arprot),
				.m_axi4_arqos			(m_axi4_arqos),
				.m_axi4_arregion		(m_axi4_arregion),
				.m_axi4_arvalid			(m_axi4_arvalid),
				.m_axi4_arready			(m_axi4_arready),
				.m_axi4_rid				(m_axi4_rid),
				.m_axi4_rdata			(m_axi4_rdata),
				.m_axi4_rresp			(m_axi4_rresp),
				.m_axi4_rlast			(m_axi4_rlast),
				.m_axi4_rvalid			(m_axi4_rvalid),
				.m_axi4_rready			(m_axi4_rready)
			);
	
	
endmodule


`default_nettype wire


// end of file
