// ---------------------------------------------------------------------------
//  AXI4Stream �� AXI4�� Write ����R�A
//
//                                      Copyright (C) 2015 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------


`timescale 1ns / 1ps
`default_nettype none


module jelly_vdma_axi4s_to_axi4_core
		#(
			parameter	AXI4_ID_WIDTH    = 6,
			parameter	AXI4_ADDR_WIDTH  = 32,
			parameter	AXI4_DATA_SIZE   = 2,	// 0:8bit, 1:16bit, 2:32bit ...
			parameter	AXI4_DATA_WIDTH  = (8 << AXI4_DATA_SIZE),
			parameter	AXI4_STRB_WIDTH  = (1 << AXI4_DATA_SIZE),
			parameter	AXI4_LEN_WIDTH   = 8,
			parameter	AXI4_QOS_WIDTH   = 4,
			parameter	AXI4S_USER_WIDTH = 1,
			parameter	AXI4S_DATA_WIDTH = AXI4_DATA_WIDTH,
			parameter	STRIDE_WIDTH     = 14,
			parameter	INDEX_WIDTH      = 8,
			parameter	H_WIDTH          = 12,
			parameter	V_WIDTH          = 12,
			parameter	SIZE_WIDTH       = H_WIDTH + V_WIDTH
		)
		(
			input	wire							aresetn,
			input	wire							aclk,
			
			// control
			input	wire							ctl_enable,
			input	wire							ctl_update,
			output	wire							ctl_busy,
			output	wire	[INDEX_WIDTH-1:0]		ctl_index,
			
			// parameter
			input	wire	[AXI4_ADDR_WIDTH-1:0]	param_addr,
			input	wire	[STRIDE_WIDTH-1:0]		param_stride,
			input	wire	[H_WIDTH-1:0]			param_width,
			input	wire	[V_WIDTH-1:0]			param_height,
			input	wire	[SIZE_WIDTH-1:0]		param_size,
			input	wire	[AXI4_LEN_WIDTH-1:0]	param_awlen,
			
			// status
			output	wire	[AXI4_ADDR_WIDTH-1:0]	monitor_addr,
			output	wire	[STRIDE_WIDTH-1:0]		monitor_stride,
			output	wire	[H_WIDTH-1:0]			monitor_width,
			output	wire	[V_WIDTH-1:0]			monitor_height,
			output	wire	[SIZE_WIDTH-1:0]		monitor_size,
			output	wire	[AXI4_LEN_WIDTH-1:0]	monitor_awlen,
			
			// master AXI4 (write)
			output	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_awid,
			output	wire	[AXI4_ADDR_WIDTH-1:0]	m_axi4_awaddr,
			output	wire	[AXI4_LEN_WIDTH-1:0]	m_axi4_awlen,
			output	wire	[2:0]					m_axi4_awsize,
			output	wire	[1:0]					m_axi4_awburst,
			output	wire	[0:0]					m_axi4_awlock,
			output	wire	[3:0]					m_axi4_awcache,
			output	wire	[2:0]					m_axi4_awprot,
			output	wire	[AXI4_QOS_WIDTH-1:0]	m_axi4_awqos,
			output	wire	[3:0]					m_axi4_awregion,
			output	wire							m_axi4_awvalid,
			input	wire							m_axi4_awready,
			
			output	wire	[AXI4_DATA_WIDTH-1:0]	m_axi4_wdata,
			output	wire	[AXI4_STRB_WIDTH-1:0]	m_axi4_wstrb,
			output	wire							m_axi4_wlast,
			output	wire							m_axi4_wvalid,
			input	wire							m_axi4_wready,
			
			input	wire	[AXI4_ID_WIDTH-1:0]		m_axi4_bid,
			input	wire	[1:0]					m_axi4_bresp,
			input	wire							m_axi4_bvalid,
			output	wire							m_axi4_bready,
			
			// slave AXI4-Stream (output)
			input	wire	[AXI4S_DATA_WIDTH-1:0]	s_axi4s_tdata,
			input	wire							s_axi4s_tlast,
			input	wire	[AXI4S_USER_WIDTH-1:0]	s_axi4s_tuser,
			input	wire							s_axi4s_tvalid,
			output	wire							s_axi4s_tready
		);
	
	// ��ԊǗ�
	reg								reg_busy;
	reg								reg_skip;

	wire							sig_awbusy;
	reg								reg_awenable;
	reg		[SIZE_WIDTH-1:0]		reg_awhcount;
	reg		[V_WIDTH-1:0]			reg_awvcount;
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_awaddr;
		
	// �V���h�[���W�X�^
	reg		[INDEX_WIDTH-1:0]		reg_index;			// ���̕ω��Ńz�X�g�͎�t�m�F
	reg		[AXI4_ADDR_WIDTH-1:0]	reg_param_addr;
	reg		[STRIDE_WIDTH-1:0]		reg_param_stride;
	reg		[H_WIDTH-1:0]			reg_param_width;
	reg		[V_WIDTH-1:0]			reg_param_height;
	reg		[SIZE_WIDTH-1:0]		reg_param_size;
	reg		[AXI4_LEN_WIDTH-1:0]	reg_param_awlen;

	wire	[AXI4S_DATA_WIDTH-1:0]	axi4s_tdata;
	wire							axi4s_tvalid;
	wire							axi4s_tready;
	
	always @(posedge aclk) begin
		if ( !aresetn ) begin
			reg_busy         <= 1'b0;
			reg_skip         <= 1'b1;
			reg_index        <= {INDEX_WIDTH{1'b0}};
			
			reg_param_addr   <= {AXI4_ADDR_WIDTH{1'bx}};
			reg_param_stride <= {STRIDE_WIDTH{1'bx}};
			reg_param_width  <= {H_WIDTH{1'bx}};
			reg_param_height <= {V_WIDTH{1'bx}};
			reg_param_size   <= {SIZE_WIDTH{1'bx}};
			reg_param_awlen  <= {AXI4_LEN_WIDTH{1'bx}};
			
			reg_awenable     <= 1'b0;
			reg_awhcount     <= {SIZE_WIDTH{1'bx}};
			reg_awvcount     <= {V_WIDTH{1'bx}};
			reg_awaddr       <= {AXI4_ADDR_WIDTH{1'bx}};
		end
		else begin
			reg_awenable <= 1'b0;
			
			if ( !reg_busy ) begin
				if ( ctl_enable ) begin
					// start
					reg_busy     <= 1'b1;
					reg_skip     <= 1'b1;
					reg_index    <= reg_index + 1'b1;
					reg_awenable <= 1'b1;
					if ( ctl_update ) begin
						reg_param_addr   <= param_addr;
						reg_param_stride <= param_stride;
						reg_param_width  <= param_width;
						reg_param_height <= param_height;
						reg_param_size   <= param_size;
						reg_param_awlen  <= param_awlen;
						
						reg_awhcount <= param_width;
						reg_awvcount <= param_height;
						if ( (param_size != 0) && (param_width << AXI4_DATA_SIZE) == param_stride ) begin
							reg_awhcount <= param_size;
							reg_awvcount <= 1;
						end
						reg_awaddr <= param_addr;
					end
					else begin
						reg_awhcount <= reg_param_width;
						reg_awvcount <= reg_param_height;
						if ( (reg_param_size != 0) && (reg_param_width << AXI4_DATA_SIZE) == reg_param_stride ) begin
							reg_awhcount <= param_size;
							reg_awvcount <= 1;
						end
						reg_awaddr <= reg_param_addr;
					end
				end
				else begin
					// idle
					reg_busy <= 1'b0;
					reg_skip <= 1'b1;
				end
			end
			else begin
				if ( !reg_awenable && !sig_awbusy ) begin
					if ( (reg_awvcount - 1'b1) == 0 ) begin
						// end
						reg_busy     <= 1'b0;
						reg_awaddr   <= {AXI4_ADDR_WIDTH{1'bx}};
						reg_awvcount <= {V_WIDTH{1'bx}};
					end
					else begin
						// next line
						reg_awenable <= 1'b1;
						reg_awaddr   <= reg_awaddr + reg_param_stride;
						reg_awvcount <= reg_awvcount - 1'b1;
					end
				end
			end

			// wait frame start
			if ( reg_busy && reg_skip ) begin
				if ( s_axi4s_tvalid && s_axi4s_tuser ) begin 
					// frame start
					reg_skip <= 1'b0;
				end
			end
		end
	end
	
	assign ctl_busy        = reg_busy;
	assign ctl_index       = reg_index;
	
	assign monitor_addr    = reg_param_addr;
	assign monitor_stride  = reg_param_stride;
	assign monitor_width   = reg_param_width;
	assign monitor_height  = reg_param_height;
	assign monitor_awlen   = reg_param_awlen;
	
	assign axi4s_tvalid    = s_axi4s_tvalid && (!reg_skip || s_axi4s_tuser);
	assign axi4s_tdata     = s_axi4s_tdata;	
	assign s_axi4s_tready  = (reg_skip || (reg_busy && axi4s_tready));

	
	// DAM writer
	jelly_axi4_dma_writer
			#(
				.AXI4_ID_WIDTH		(AXI4_ID_WIDTH),
				.AXI4_ADDR_WIDTH	(AXI4_ADDR_WIDTH),
				.AXI4_DATA_SIZE		(AXI4_DATA_SIZE),
				.AXI4_DATA_WIDTH	(AXI4_DATA_WIDTH),
				.AXI4_STRB_WIDTH	(AXI4_STRB_WIDTH),
				.AXI4_LEN_WIDTH		(AXI4_LEN_WIDTH),
				.AXI4_QOS_WIDTH		(AXI4_QOS_WIDTH),
				.AXI4S_DATA_WIDTH	(AXI4S_DATA_WIDTH),
				.COUNT_WIDTH		(SIZE_WIDTH)
			)
		i_axi4_dma_writer
			(
				.aresetn			(aresetn),
				.aclk				(aclk),
				
				.enable				(reg_awenable),
				.busy				(sig_awbusy),
				
				.param_addr			(reg_awaddr),
				.param_count		(reg_awhcount),
				.param_maxlen		(reg_param_awlen),
				
				.m_axi4_awid		(m_axi4_awid),
				.m_axi4_awaddr		(m_axi4_awaddr),
				.m_axi4_awlen		(m_axi4_awlen),
				.m_axi4_awsize		(m_axi4_awsize),
				.m_axi4_awburst		(m_axi4_awburst),
				.m_axi4_awlock		(m_axi4_awlock),
				.m_axi4_awcache		(m_axi4_awcache),
				.m_axi4_awprot		(m_axi4_awprot),
				.m_axi4_awqos		(m_axi4_awqos),
				.m_axi4_awregion	(m_axi4_awregion),
				.m_axi4_awvalid		(m_axi4_awvalid),
				.m_axi4_awready		(m_axi4_awready),
				.m_axi4_wdata		(m_axi4_wdata),
				.m_axi4_wstrb		(m_axi4_wstrb),
				.m_axi4_wlast		(m_axi4_wlast),
				.m_axi4_wvalid		(m_axi4_wvalid),
				.m_axi4_wready		(m_axi4_wready),
				.m_axi4_bid			(m_axi4_bid),
				.m_axi4_bresp		(m_axi4_bresp),
				.m_axi4_bvalid		(m_axi4_bvalid),
				.m_axi4_bready		(m_axi4_bready),
				
				.s_axi4s_tdata		(axi4s_tdata),
				.s_axi4s_tvalid		(axi4s_tvalid),
				.s_axi4s_tready		(axi4s_tready)
			);
	
	
	
endmodule


`default_nettype wire


// end of file
