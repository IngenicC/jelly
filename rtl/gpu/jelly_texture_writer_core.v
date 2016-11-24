// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2015 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// FIFO
module jelly_texture_writer_core
		#(
			parameter	COMPONENT_NUM        = 3,
			parameter	COMPONENT_DATA_WIDTH = 8,
			
			parameter	S_AXI4S_DATA_WIDTH   = COMPONENT_NUM * COMPONENT_DATA_WIDTH,

			parameter	M_AXI4_ID_WIDTH      = 6,
			parameter	M_AXI4_ADDR_WIDTH    = 32,
			parameter	M_AXI4_DATA_SIZE     = 3,	// 0:8bit, 1:16bit, 2:32bit, 3:64bit, ... ...
			parameter	M_AXI4_DATA_WIDTH    = (8 << M_AXI4_DATA_SIZE),
			parameter	M_AXI4_STRB_WIDTH    = (1 << M_AXI4_DATA_SIZE),
			parameter	M_AXI4_LEN_WIDTH     = 8,
			parameter	M_AXI4_QOS_WIDTH     = 4,
			parameter	M_AXI4_AWID          = {M_AXI4_ID_WIDTH{1'b0}},
			parameter	M_AXI4_AWSIZE        = M_AXI4_DATA_SIZE,
			parameter	M_AXI4_AWBURST       = 2'b01,
			parameter	M_AXI4_AWLOCK        = 1'b0,
			parameter	M_AXI4_AWCACHE       = 4'b0001,
			parameter	M_AXI4_AWPROT        = 3'b000,
			parameter	M_AXI4_AWQOS         = 0,
			parameter	M_AXI4_AWREGION      = 4'b0000,
			parameter	M_AXI4_AW_REGS       = 1,
			parameter	M_AXI4_W_REGS        = 1,
			
			parameter	BLK_X_SIZE           = 3,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			parameter	BLK_Y_SIZE           = 3,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			parameter	STEP_Y_SIZE          = 1,		// 2^n (0:1, 1:2, 2:4, 3:8, ... )
			
			parameter	X_WIDTH              = 10,
			parameter	Y_WIDTH              = 10,
			
			parameter	STRIDE_WIDTH         = X_WIDTH + BLK_Y_SIZE,
			parameter	SIZE_WIDTH           = 24,
			
			parameter	FIFO_ADDR_WIDTH      = 10,
			parameter	FIFO_RAM_TYPE        = "block"
		)
		(
			input	wire											reset,
			input	wire											clk,
			
			input	wire											endian,
			
			input	wire	[M_AXI4_ADDR_WIDTH*COMPONENT_NUM-1:0]	param_addr,
			input	wire	[M_AXI4_LEN_WIDTH-1:0]					param_awlen,
			input	wire	[X_WIDTH-1:0]							param_width,
			input	wire	[Y_WIDTH-1:0]							param_height,
			input	wire	[STRIDE_WIDTH-1:0]						param_stride,
			
			input	wire	[0:0]									s_axi4s_tuser,
			input	wire											s_axi4s_tlast,
			input	wire	[S_AXI4S_DATA_WIDTH-1:0]				s_axi4s_tdata,
			input	wire											s_axi4s_tvalid,
			output	wire											s_axi4s_tready,
			
			output	wire	[M_AXI4_ID_WIDTH-1:0]					m_axi4_awid,
			output	wire	[M_AXI4_ADDR_WIDTH-1:0]					m_axi4_awaddr,
			output	wire	[M_AXI4_LEN_WIDTH-1:0]					m_axi4_awlen,
			output	wire	[2:0]									m_axi4_awsize,
			output	wire	[1:0]									m_axi4_awburst,
			output	wire	[0:0]									m_axi4_awlock,
			output	wire	[3:0]									m_axi4_awcache,
			output	wire	[2:0]									m_axi4_awprot,
			output	wire	[M_AXI4_QOS_WIDTH-1:0]					m_axi4_awqos,
			output	wire	[3:0]									m_axi4_awregion,
			output	wire											m_axi4_awvalid,
			input	wire											m_axi4_awready,
			output	wire	[M_AXI4_DATA_WIDTH-1:0]					m_axi4_wdata,
			output	wire	[M_AXI4_STRB_WIDTH-1:0]					m_axi4_wstrb,
			output	wire											m_axi4_wlast,
			output	wire											m_axi4_wvalid,
			input	wire											m_axi4_wready,
			input	wire	[M_AXI4_ID_WIDTH-1:0]					m_axi4_bid,
			input	wire	[1:0]									m_axi4_bresp,
			input	wire											m_axi4_bvalid,
			output	wire											m_axi4_bready
		);
	
	
	// ---------------------------------
	//  common
	// ---------------------------------
	
	genvar		i, j;
	
	localparam	COMPONENT_SIZE      = COMPONENT_DATA_WIDTH <=   8 ? 0 :
	                                  COMPONENT_DATA_WIDTH <=  16 ? 1 :
	                                  COMPONENT_DATA_WIDTH <=  32 ? 2 :
	                                  COMPONENT_DATA_WIDTH <=  64 ? 3 :
	                                  COMPONENT_DATA_WIDTH <= 128 ? 4 :
	                                  COMPONENT_DATA_WIDTH <= 256 ? 5 :
	                                  COMPONENT_DATA_WIDTH <= 512 ? 6 : 7;
	
	localparam	COMPONENT_SEL_WIDTH = COMPONENT_NUM        <=   2 ? 1 :
	                                  COMPONENT_NUM        <=   4 ? 2 :
	                                  COMPONENT_NUM        <=   8 ? 3 :
	                                  COMPONENT_NUM        <=  16 ? 4 :
	                                  COMPONENT_NUM        <=  32 ? 5 :
	                                  COMPONENT_NUM        <=  64 ? 6 : 7;
	
	
	localparam	CNV_DATA_WIDTH      = COMPONENT_NUM*M_AXI4_DATA_WIDTH;
	localparam	CNV_SIZE            = (M_AXI4_DATA_SIZE - COMPONENT_SIZE);
	localparam	CNV_NUM             = (1 << (M_AXI4_DATA_SIZE - COMPONENT_SIZE));
	
	
	// ---------------------------------
	//  width convert
	// ---------------------------------
	
	wire							cnv_tlast;
	wire	[CNV_DATA_WIDTH-1:0]	cnv_tdata_tmp;
	wire	[CNV_DATA_WIDTH-1:0]	cnv_tdata;
	wire							cnv_tvalid;
	wire							cnv_tready;
	
	jelly_data_width_converter
			#(
				.UNIT_WIDTH		(S_AXI4S_DATA_WIDTH),
				.S_DATA_SIZE	(0),									// log2 (0:1bit, 1:2bit, 2:4bit, 3:8bit...)
				.M_DATA_SIZE	(M_AXI4_DATA_SIZE - COMPONENT_SIZE)		// log2 (0:1bit, 1:2bit, 2:4bit, 3:8bit...)
			)
		i_data_width_converter
			(
				.reset			(reset),
				.clk			(clk),
				.cke			(1'b1),
				
				.endian			(endian),
				
				
				.s_data			(s_axi4s_tdata),
				.s_first		(s_axi4s_tuser),
				.s_last			(s_axi4s_tlast),
				.s_valid		(s_axi4s_tvalid),
				.s_ready		(s_axi4s_tready),
				
				.m_data			(cnv_tdata_tmp),
				.m_first		(),
				.m_last			(cnv_tlast),
				.m_valid		(cnv_tvalid),
				.m_ready		(cnv_tready)
			);
	
	generate
	for ( i = 0; i < COMPONENT_NUM; i = i+1 ) begin : loop_cvn_i
		for ( j = 0; j < CNV_NUM; j = j+1 ) begin : loop_cvn_j
			assign cnv_tdata[i*M_AXI4_DATA_WIDTH + j*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH]
						= cnv_tdata_tmp[j*S_AXI4S_DATA_WIDTH + i*COMPONENT_DATA_WIDTH +: COMPONENT_DATA_WIDTH];
		end
	end
	endgenerate
	
	
	
	
	// ---------------------------------
	//  FIFO
	// ---------------------------------
	
	wire	[COMPONENT_SEL_WIDTH-1:0]	fifo_component;
	wire	[SIZE_WIDTH-1:0]			fifo_addr;
	wire	[CNV_DATA_WIDTH-1:0]		fifo_data;
	wire								fifo_last;
	wire								fifo_valid;
	wire								fifo_ready;
	
	jelly_texture_writer_fifo
			#(
				.COMPONENT_NUM			(COMPONENT_NUM),
				.COMPONENT_DATA_WIDTH	(COMPONENT_DATA_WIDTH << CNV_SIZE),
				
				.BLK_X_SIZE				(BLK_X_SIZE - CNV_SIZE),
				.BLK_Y_SIZE				(BLK_Y_SIZE),
				.STEP_Y_SIZE			(STEP_Y_SIZE),
				
				.X_WIDTH				(X_WIDTH - CNV_SIZE),
				.Y_WIDTH				(Y_WIDTH),
				
				.ADDR_WIDTH				(SIZE_WIDTH),
				.STRIDE_WIDTH			(STRIDE_WIDTH),
				
				.FIFO_ADDR_WIDTH		(FIFO_ADDR_WIDTH),
				.FIFO_RAM_TYPE			(FIFO_RAM_TYPE)
			)
		i_texture_writer_fifo
			(
				.reset					(reset),
				.clk					(clk),
				
				.param_width			(param_width[X_WIDTH-1:CNV_SIZE]),
				.param_height			(param_height),
				.param_stride			(param_stride >> CNV_SIZE),
				
				.s_last					(cnv_tlast),
				.s_data					(cnv_tdata),
				.s_valid				(cnv_tvalid),
				.s_ready				(cnv_tready),
				
				.m_component			(fifo_component),
				.m_addr					(fifo_addr),
				.m_data					(fifo_data),
				.m_last					(fifo_last),
				.m_valid				(fifo_valid),
				.m_ready				(fifo_ready)
			);
	
	
	// ---------------------------------
	//  AXI4 Write
	// ---------------------------------
	
	integer								cmp;
	reg		[M_AXI4_ADDR_WIDTH-1:0]		reg_dma_addr;
	reg		[M_AXI4_DATA_WIDTH-1:0]		reg_dma_data;
	reg									reg_dma_valid;
	wire								dma_ready;
	
	always @(posedge clk) begin
		if ( reset ) begin
			reg_dma_addr  <= {M_AXI4_ADDR_WIDTH{1'bx}};
			reg_dma_data  <= {M_AXI4_DATA_WIDTH{1'bx}};
			reg_dma_valid <= 1'b0;
		end
		else if ( fifo_ready ) begin
			reg_dma_addr  <= {M_AXI4_ADDR_WIDTH{1'bx}};
			reg_dma_data  <= {M_AXI4_DATA_WIDTH{1'bx}};
			for ( cmp = 0; cmp < COMPONENT_NUM; cmp = cmp+1 ) begin
				if ( fifo_component == cmp ) begin
					reg_dma_addr <= param_addr[cmp*M_AXI4_ADDR_WIDTH +: M_AXI4_ADDR_WIDTH] + (fifo_addr << CNV_SIZE);
					reg_dma_data <= fifo_data[cmp*M_AXI4_DATA_WIDTH +: M_AXI4_DATA_WIDTH];
				end
			end
			
			reg_dma_valid <= fifo_valid;
		end
	end
	
	assign fifo_ready = (!reg_dma_valid || dma_ready);
	
	
	jelly_texture_writer_axi4
			#(
				.M_AXI4_ID_WIDTH		(M_AXI4_ID_WIDTH),
				.M_AXI4_ADDR_WIDTH		(M_AXI4_ADDR_WIDTH),
				.M_AXI4_DATA_SIZE		(M_AXI4_DATA_SIZE),
				.M_AXI4_DATA_WIDTH		(M_AXI4_DATA_WIDTH),
				.M_AXI4_STRB_WIDTH		(M_AXI4_STRB_WIDTH),
				.M_AXI4_LEN_WIDTH		(M_AXI4_LEN_WIDTH),
				.M_AXI4_QOS_WIDTH		(M_AXI4_QOS_WIDTH),
				.M_AXI4_AWID			(M_AXI4_AWID),
				.M_AXI4_AWSIZE			(M_AXI4_AWSIZE),
				.M_AXI4_AWBURST			(M_AXI4_AWBURST),
				.M_AXI4_AWLOCK			(M_AXI4_AWLOCK),
				.M_AXI4_AWCACHE			(M_AXI4_AWCACHE),
				.M_AXI4_AWPROT			(M_AXI4_AWPROT),
				.M_AXI4_AWQOS			(M_AXI4_AWQOS),
				.M_AXI4_AWREGION		(M_AXI4_AWREGION),
				.M_REGS					(1),
				.S_REGS					(1)
			)
		i_texture_writer_axi4
			(
				.reset					(reset),
				.clk					(clk),
				
				.param_awlen			(param_awlen),
				
				.s_addr					(reg_dma_addr),
				.s_data					(reg_dma_data),
				.s_valid				(reg_dma_valid),
				.s_ready				(dma_ready),
				
				.m_axi4_awid			(m_axi4_awid),
				.m_axi4_awaddr			(m_axi4_awaddr),
				.m_axi4_awlen			(m_axi4_awlen),
				.m_axi4_awsize			(m_axi4_awsize),
				.m_axi4_awburst			(m_axi4_awburst),
				.m_axi4_awlock			(m_axi4_awlock),
				.m_axi4_awcache			(m_axi4_awcache),
				.m_axi4_awprot			(m_axi4_awprot),
				.m_axi4_awqos			(m_axi4_awqos),
				.m_axi4_awregion		(m_axi4_awregion),
				.m_axi4_awvalid			(m_axi4_awvalid),
				.m_axi4_awready			(m_axi4_awready),
				.m_axi4_wdata			(m_axi4_wdata),
				.m_axi4_wstrb			(m_axi4_wstrb),
				.m_axi4_wlast			(m_axi4_wlast),
				.m_axi4_wvalid			(m_axi4_wvalid),
				.m_axi4_wready			(m_axi4_wready),
				.m_axi4_bid				(m_axi4_bid),
				.m_axi4_bresp			(m_axi4_bresp),
				.m_axi4_bvalid			(m_axi4_bvalid),
				.m_axi4_bready			(m_axi4_bready)
			);
	
	/*
	jelly_axi4_dma_writer
			#(
				.AXI4_ID_WIDTH			(M_AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH		(M_AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE			(M_AXI4_DATA_SIZE),
				.AXI4_DATA_WIDTH		(M_AXI4_DATA_WIDTH),
				.AXI4_STRB_WIDTH		(M_AXI4_STRB_WIDTH),
				.AXI4_LEN_WIDTH			(M_AXI4_LEN_WIDTH),
				.AXI4_QOS_WIDTH			(M_AXI4_QOS_WIDTH),
				.AXI4_AWID				(M_AXI4_AWID),
				.AXI4_AWSIZE			(M_AXI4_AWSIZE),
				.AXI4_AWBURST			(M_AXI4_AWBURST),
				.AXI4_AWLOCK			(M_AXI4_AWLOCK),
				.AXI4_AWCACHE			(M_AXI4_AWCACHE),
				.AXI4_AWPROT			(M_AXI4_AWPROT),
				.AXI4_AWQOS				(M_AXI4_AWQOS),
				.AXI4_AWREGION			(M_AXI4_AWREGION),
				.AXI4S_DATA_WIDTH		(M_AXI4_DATA_WIDTH),
				.PACKET_ENABLE			(0),
				.AXI4_AW_REGS			(M_AXI4_AW_REGS),
				.AXI4_W_REGS			(M_AXI4_W_REGS),
				.AXI4S_REGS				(0)
			)
		i_axi4_dma_writer
			(
				.aresetn				(~reset),
				.aclk					(clk),
				
				.enable					(reg_dma_valid),
				.busy					(),
				
				.queue_counter			(1),
				
				.param_addr				(reg_dma_addr),
				.param_count			((1 << (BLK_X_SIZE - CNV_SIZE)) * STEP_Y_SIZE),
				.param_maxlen			(8'hff),
				.param_wstrb			({M_AXI4_STRB_WIDTH{1'b1}}),
				
				.s_axi4s_tdata			(reg_dma_data),
				.s_axi4s_tvalid			(reg_dma_valid),
				.s_axi4s_tready			(dma_ready),
				
				.m_axi4_awid			(m_axi4_awid),
				.m_axi4_awaddr			(m_axi4_awaddr),
				.m_axi4_awlen			(m_axi4_awlen),
				.m_axi4_awsize			(m_axi4_awsize),
				.m_axi4_awburst			(m_axi4_awburst),
				.m_axi4_awlock			(m_axi4_awlock),
				.m_axi4_awcache			(m_axi4_awcache),
				.m_axi4_awprot			(m_axi4_awprot),
				.m_axi4_awqos			(m_axi4_awqos),
				.m_axi4_awregion		(m_axi4_awregion),
				.m_axi4_awvalid			(m_axi4_awvalid),
				.m_axi4_awready			(m_axi4_awready),
				.m_axi4_wdata			(m_axi4_wdata),
				.m_axi4_wstrb			(m_axi4_wstrb),
				.m_axi4_wlast			(m_axi4_wlast),
				.m_axi4_wvalid			(m_axi4_wvalid),
				.m_axi4_wready			(m_axi4_wready),
				.m_axi4_bid				(m_axi4_bid),
				.m_axi4_bresp			(m_axi4_bresp),
				.m_axi4_bvalid			(m_axi4_bvalid),
				.m_axi4_bready			(m_axi4_bready)
			);
	*/
	
endmodule


`default_nettype wire


// end of file