
`timescale 1ns / 1ps
`default_nettype none


module tb_texture_cache_unit();
	localparam RATE    = 1000.0/200.0;
	
	initial begin
		$dumpfile("tb_texture_cache_unit.vcd");
		$dumpvars(0, tb_texture_cache_unit);
		
		#1000000;
			$finish;
	end
	
	reg		clk = 1'b1;
	always #(RATE/2.0)	clk = ~clk;
	
	reg		reset = 1'b1;
	initial #(RATE*100.5)	reset = 1'b0;
	
	
	parameter	S_ADDR_X_WIDTH   = 12;
	parameter	S_ADDR_Y_WIDTH   = 12;
	parameter	S_DATA_WIDTH     = 24;
	
	parameter	TAG_ADDR_WIDTH   = 6;
	
	parameter	BLK_X_SIZE       = 2;	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
	parameter	BLK_Y_SIZE       = 2;	// 0:1pixel, 1:2pixel, 2:4pixel, 3:8pixel ...
	
	parameter	PIX_ADDR_X_WIDTH = BLK_X_SIZE;
	parameter	PIX_ADDR_Y_WIDTH = BLK_Y_SIZE;
	parameter	BLK_ADDR_X_WIDTH = S_ADDR_X_WIDTH - BLK_X_SIZE;
	parameter	BLK_ADDR_Y_WIDTH = S_ADDR_Y_WIDTH - BLK_Y_SIZE;
	
	parameter	M_DATA_WIDE_SIZE = 1;
	
	parameter	M_ADDR_X_WIDTH   = BLK_ADDR_X_WIDTH;
	parameter	M_ADDR_Y_WIDTH   = BLK_ADDR_Y_WIDTH;
	parameter	M_DATA_WIDTH     = (S_DATA_WIDTH << M_DATA_WIDE_SIZE);
	
	wire									endian = 0;
	
	wire									clear_start = 0;
	wire									ckear_busy;
	
	wire	[S_ADDR_X_WIDTH-1:0]			param_width  = 640;
	wire	[S_ADDR_X_WIDTH-1:0]			param_height = 480;
	
	
	reg		signed	[S_ADDR_X_WIDTH-1:0]	s_araddrx;
	reg		signed	[S_ADDR_Y_WIDTH-1:0]	s_araddry;
	reg										s_arvalid;
	wire									s_arready;
	
	wire	[S_DATA_WIDTH-1:0]				s_rdata;
	wire									s_rvalid;
	reg										s_rready = 1;
	
	
	wire	[M_ADDR_X_WIDTH-1:0]			m_araddrx;
	wire	[M_ADDR_Y_WIDTH-1:0]			m_araddry;
	wire									m_arvalid;
	wire									m_arready = 1;
	
	reg										m_rlast  = 0;
	wire	[M_DATA_WIDTH-1:0]				m_rdata;
	reg										m_rvalid = 0;
	wire									m_rready;
	
	jelly_texture_cache_unit
			#(
				.S_ADDR_X_WIDTH		(S_ADDR_X_WIDTH),
				.S_ADDR_Y_WIDTH		(S_ADDR_Y_WIDTH),
				.S_DATA_WIDTH		(S_DATA_WIDTH),
				.TAG_ADDR_WIDTH		(TAG_ADDR_WIDTH),
				.BLK_ADDR_X_WIDTH	(BLK_ADDR_X_WIDTH),
				.BLK_ADDR_Y_WIDTH	(BLK_ADDR_Y_WIDTH),
				.M_DATA_WIDE_SIZE	(M_DATA_WIDE_SIZE),
				.BORDER_DATA		(24'haaaa5555)
			)
		i_texture_cache_unit
			(
				.reset				(reset),
				.clk				(clk),
				                     
				.endian				(endian),
				                     
				.clear_start		(clear_start),
				.clear_busy			(ckear_busy),
				                     
				.param_width		(param_width),
				.param_height		(param_height),
				                     
				.s_araddrx			(s_araddrx),
				.s_araddry			(s_araddry),
				.s_arvalid			(s_arvalid),
				.s_arready			(s_arready),
				                     
				.s_rdata			(s_rdata),
				.s_rvalid			(s_rvalid),
				.s_rready			(s_rready),
				                     
				.m_araddrx			(m_araddrx),
				.m_araddry			(m_araddry),
				.m_arvalid			(m_arvalid),
				.m_arready			(m_arready),
				                     
				.m_rlast			(m_rlast),
				.m_rdata			(m_rdata),
				.m_rvalid			(m_rvalid),
				.m_rready			(m_rready)
			);
	
	
	always @(posedge clk) begin
		if ( reset ) begin
			s_araddrx <= -10;
			s_araddry <= -10;
			s_arvalid <= 1'b0;
		end
		else begin
			if ( s_arvalid && s_arready ) begin
				s_araddrx <= s_araddrx + 1;
				if ( s_araddrx >= 31 /*640 + 10 - 1*/ ) begin
					s_araddrx <= -10;
					s_araddry <= s_araddry + 1;
					if ( s_araddry >= 480 + 10 - 1 ) begin
						s_araddry <= -10;
					end
				end
			end
			s_arvalid <= 1'b1;
		end
	end
	
	
	integer							reg_count;
	reg								reg_busy;
	reg		[M_ADDR_X_WIDTH-1:0]	reg_araddrx;
	reg		[M_ADDR_Y_WIDTH-1:0]	reg_araddry;
	reg		[1:0]					reg_x;
	reg		[1:0]					reg_y;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_busy <= 0;
			m_rlast  <= 1'bx;
			m_rvalid <= 0;
		end
		else begin
			if ( m_arvalid && m_arready ) begin
				reg_busy    <= 1;
				reg_count   <= 0;
				m_rlast     <= 0;
				reg_araddrx <= m_araddrx;
				reg_araddry <= m_araddry;
				reg_x       <= 0;
				reg_y       <= 0;
				m_rvalid    <= 1'b1;
			end
			else begin
				if ( m_rvalid && m_rready ) begin
					if ( reg_count == 4*2-1 ) begin
						m_rlast  <= 1'bx;
						m_rvalid <= 1'b0;
					end
					else begin
						reg_count <= reg_count + 1;
						m_rlast   <= (reg_count == 4*2-2);
						reg_x     <= reg_x + 2;
						if ( reg_x + 2 >= 4 ) begin
							reg_x <= 0;
							reg_y <= reg_y + 1;
						end
						
						m_rvalid  <= 1'b1;
					end
				end
			end
		end
	end
	
	assign m_rdata = {reg_araddry, reg_y, reg_araddrx, (reg_x+2'b01), reg_araddry, reg_y, reg_araddrx, reg_x};
	
	
	/////////////////
	always @(posedge clk) begin
		s_rready <= {$random()};
	end
	
	
	integer		count = 0;
	
	integer		fp;
	initial begin
		fp = $fopen("out.txt", "w");
	end
	
	always @(posedge clk) begin
		if ( !reset ) begin
			if ( s_rvalid & s_rready ) begin
				$fdisplay(fp, "%h", s_rdata);
				count = count + 1;
				if ( count > 32*500 ) begin
					$finish;
				end
			end
		end
	end
	
	
endmodule


`default_nettype wire


// end of file
