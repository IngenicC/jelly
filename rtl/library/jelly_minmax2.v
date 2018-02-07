// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2018 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// min/max
module jelly_minmax2
		#(
			parameter	NUM               = 12,
			parameter	INDEX_WIDTH       = NUM <=     2 ?  1 :
	                                        NUM <=     4 ?  2 :
	                                        NUM <=     8 ?  3 :
	                                        NUM <=    16 ?  4 :
	                                        NUM <=    32 ?  5 :
	                                        NUM <=    64 ?  6 :
	                                        NUM <=   128 ?  7 :
	                                        NUM <=   256 ?  8 :
	                                        NUM <=   512 ?  9 :
	                                        NUM <=  1024 ? 10 :
	                                        NUM <=  2048 ? 11 :
	                                        NUM <=  4096 ? 12 :
	                                        NUM <=  8192 ? 13 :
	                                        NUM <= 16384 ? 14 :
	                                        NUM <= 32768 ? 15 : 16,
			parameter	COMMON_USER_WIDTH = 32,
			parameter	USER_WIDTH        = 32,
			parameter	DATA_WIDTH        = 32,
			parameter	DATA_SIGNED       = 1,
			parameter	CMP_MIN           = 0,		// min��max��
			parameter	CMP_EQ            = 0,		// ���l�̂Ƃ� data0 �� data1 �ǂ����D�悷�邩
			
			parameter	COMMON_USER_BITS  = COMMON_USER_WIDTH > 0 ? COMMON_USER_WIDTH : 1,
			parameter	USER_BITS         = USER_WIDTH        > 0 ? USER_WIDTH        : 1
		)
		(
			input	wire								reset,
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[COMMON_USER_BITS-1:0]		s_common_user,
			input	wire	[NUM*USER_BITS-1:0]			s_user,
			input	wire	[NUM*DATA_WIDTH-1:0]		s_data,
			input	wire	[NUM-1:0]					s_en,
			input	wire								s_valid,
			
			output	wire	[COMMON_USER_BITS-1:0]		m_common_user,
			output	wire	[USER_BITS-1:0]				m_user,
			output	wire	[DATA_WIDTH-1:0]			m_data,
			output	wire	[INDEX_WIDTH-1:0]			m_index,
			output	wire								m_en,
			output	wire								m_valid
		);
	
	
	// ���E�l��`
	wire	[DATA_WIDTH-1:0]		data_min   = DATA_SIGNED ? {1'b1, {(DATA_WIDTH-1){1'b0}}} : {DATA_WIDTH{1'b0}};
	wire	[DATA_WIDTH-1:0]		data_max   = DATA_SIGNED ? {1'b0, {(DATA_WIDTH-1){1'b1}}} : {DATA_WIDTH{1'b1}};
	wire	[DATA_WIDTH-1:0]		data_limit = CMP_MIN ? data_max : data_min;
	
	
	// �ꕔ�����n�� $clog2 �������������Ȃ��̂�
	localparam	STAGES = NUM <=     2 ?  1 :
	                     NUM <=     4 ?  2 :
	                     NUM <=     8 ?  3 :
	                     NUM <=    16 ?  4 :
	                     NUM <=    32 ?  5 :
	                     NUM <=    64 ?  6 :
	                     NUM <=   128 ?  7 :
	                     NUM <=   256 ?  8 :
	                     NUM <=   512 ?  9 :
	                     NUM <=  1024 ? 10 :
	                     NUM <=  2048 ? 11 :
	                     NUM <=  4096 ? 12 :
	                     NUM <=  8192 ? 13 :
	                     NUM <= 16384 ? 14 :
	                     NUM <= 32768 ? 15 : 16;
	
	localparam	N      = (2 << STAGES) - 1;
	
	
	genvar							i, j;
	
	wire	[N*INDEX_WIDTH-1:0]		sig_index;
	wire	[N*USER_BITS-1:0]		sig_user;
	wire	[N*DATA_WIDTH-1:0]		sig_data;
	
	generate
	for ( i = 0; i < STAGES; i = i+1 ) begin : loop_stage
		for ( j = 0; j < (1 << i); j = j+1 ) begin : loop_unit
			
			jelly_minmax_unit
					#(
						.USER_WIDTH		(INDEX_WIDTH+USER_BITS),
						.DATA_WIDTH		(DATA_WIDTH),
						.DATA_SIGNED	(DATA_SIGNED),
						.CMP_MIN		(CMP_MIN),
						.CMP_EQ			(CMP_EQ)
					)
				i_minmax_unit
					(
						.clk			(clk),
						.cke			(cke),
						
						.in_user0		({sig_index[(((1 << (i+1))-1)+2*j+0)*INDEX_WIDTH +: INDEX_WIDTH],
										  sig_user [(((1 << (i+1))-1)+2*j+0)*USER_BITS   +: USER_BITS]}),
						.in_data0		( sig_data [(((1 << (i+1))-1)+2*j+0)*DATA_WIDTH  +: DATA_WIDTH]),
						.in_user1		({sig_index[(((1 << (i+1))-1)+2*j+1)*INDEX_WIDTH +: INDEX_WIDTH],
						                  sig_user [(((1 << (i+1))-1)+2*j+1)*USER_BITS   +: USER_BITS]}),
						.in_data1		( sig_data [(((1 << (i+1))-1)+2*j+1)*DATA_WIDTH  +: DATA_WIDTH]),
						
						.out_user		({sig_index[(((1 << (i+0))-1)+j)*INDEX_WIDTH +: INDEX_WIDTH],
										  sig_user [(((1 << (i+0))-1)+j)*USER_BITS   +: USER_BITS]}),
						.out_data		( sig_data [(((1 << (i+0))-1)+j)*DATA_WIDTH  +: DATA_WIDTH])
					);
		end
	end
	
	for ( i = 0; i < (1 << STAGES); i = i+1 ) begin : loop_input
		if ( i < NUM ) begin
			assign sig_index[((1 << STAGES)-1+i)*INDEX_WIDTH +: INDEX_WIDTH] = i;
			assign sig_user [((1 << STAGES)-1+i)*USER_BITS   +: USER_BITS]   = s_user[i*USER_BITS  +: USER_BITS];
			assign sig_data [((1 << STAGES)-1+i)*DATA_WIDTH  +: DATA_WIDTH]  = s_en[i] ? s_data[i*DATA_WIDTH +: DATA_WIDTH] : data_limit;
		end
		else begin
			assign sig_index[((1 << STAGES)-1+i)*INDEX_WIDTH +: INDEX_WIDTH] = i;
			assign sig_user [((1 << STAGES)-1+i)*USER_BITS   +: USER_BITS]   = {USER_BITS{1'bx}};
			assign sig_data [((1 << STAGES)-1+i)*DATA_WIDTH  +: DATA_WIDTH]  = data_limit;
		end
	end
	endgenerate
	
	assign m_index = sig_index[0 +: INDEX_WIDTH];
	assign m_user  = sig_user [0 +: USER_BITS];
	assign m_data  = sig_data [0 +: DATA_WIDTH];
	
	
	jelly_data_delay
			#(
				.LATENCY	(STAGES),
				.DATA_WIDTH	(1 + COMMON_USER_BITS)
			)
		i_data_delay
			(
				.reset		(reset),
				.clk		(clk),
				.cke		(cke),
				
				.in_data	({|s_en, s_common_user}),
				
				.out_data	({m_en, m_common_user})
			);
	
	
	reg		[STAGES-1:0]		reg_valid;
	always @(posedge clk) begin
		if ( reset ) begin
			reg_valid <= {STAGES{1'b0}};
		end
		else if ( cke ) begin
			reg_valid <= ({s_valid, reg_valid} >> 1);
		end
	end
	
	assign m_valid = reg_valid;
	
	
endmodule


// �I�����j�b�g
module jelly_minmax_unit
		#(
			parameter	USER_WIDTH  = 32,
			parameter	DATA_WIDTH  = 32,
			parameter	DATA_SIGNED = 1,
			parameter	CMP_MIN     = 0,		// min��max��
			parameter	CMP_EQ      = 0,		// ���l�̂Ƃ� data0 �� data1 �ǂ����D�悷�邩
			
			parameter	USER_BITS   = USER_WIDTH > 0 ? USER_WIDTH : 1
		)
		(
			input	wire								clk,
			input	wire								cke,
			
			input	wire	[USER_BITS-1:0]				in_user0,
			input	wire	[DATA_WIDTH-1:0]			in_data0,
			input	wire	[USER_BITS-1:0]				in_user1,
			input	wire	[DATA_WIDTH-1:0]			in_data1,
			
			output	wire	[USER_BITS-1:0]				out_user,
			output	wire	[DATA_WIDTH-1:0]			out_data
		);
	
	// �����t���Ɋg��
	wire	signed	[DATA_WIDTH:0]	data0 = DATA_SIGNED ? {in_data0[DATA_WIDTH-1], in_data0} : {1'b0, in_data0};
	wire	signed	[DATA_WIDTH:0]	data1 = DATA_SIGNED ? {in_data1[DATA_WIDTH-1], in_data1} : {1'b0, in_data1};
	reg								tmp_sel;
	
	reg		[USER_BITS-1:0]			reg_user;
	reg		[DATA_WIDTH-1:0]		reg_data;
	
	always @(posedge clk) begin
		if ( cke ) begin
			// �I��
			if ( CMP_EQ ) begin
				tmp_sel = CMP_MIN ? (data1 <= data0) : (data1 >= data0);
			end
			else begin
				tmp_sel = CMP_MIN ? (data1 <  data0) : (data1 > data0);
			end
			
			reg_user <= tmp_sel ? in_user1 : in_user0;
			reg_data <= tmp_sel ? in_data1 : in_data0;
		end
	end
	
	assign out_user = reg_user;
	assign out_data = reg_data;
		
endmodule


`default_nettype wire


// end of file
