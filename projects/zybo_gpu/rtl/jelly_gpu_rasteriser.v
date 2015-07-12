// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//   GPU�p���X�^���C�U����
//
//                                 Copyright (C) 2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// ���X�^���C�Y���s��
module jelly_gpu_rasteriser
		#(
			// XY���W�̕�
			parameter	X_WIDTH          = 12,
			parameter	Y_WIDTH          = 12,
			
			// �̈攻�莮�̌��Ɛ��x
			parameter	EVAL_NUM         = 3,
			parameter	EVAL_INT_WIDTH   = 28,
			parameter	EVAL_FRAC_WIDTH  = 4,
			parameter	EVAL_DATA_WIDTH  = EVAL_INT_WIDTH + EVAL_FRAC_WIDTH,
			
			// �O�[���[�V�F�[�f�B���O�v�Z�p�̌Œ菬���p�����[�^�̌��Ɛ��x
			parameter	FIXED_NUM        = 3,
			parameter	FIXED_INT_WIDTH  = 28,
			parameter	FIXED_FRAC_WIDTH = 4,
			parameter	FIXED_DATA_WIDTH = FIXED_INT_WIDTH + FIXED_FRAC_WIDTH,
			
			// �O�[���[�V�F�[�f�B���O�v�Z�p�̕��������_�p�����[�^�̌��Ɛ��x
			parameter	FLOAT_NUM        = 3,
			parameter	FLOAT_EXP_WIDTH  = 8,
			parameter	FLOAT_FRAC_WIDTH = 23,
			parameter	FLOAT_DATA_WIDTH = 1 + FLOAT_EXP_WIDTH + FLOAT_FRAC_WIDTH,
			
			// �o�͂�FF�}��
			parameter	MASTER_REGS      = 1
		)
		(
			input	wire										reset,
			input	wire										clk,
			input	wire										cke,
			
			input	wire	[X_WIDTH-1:0]						s_param_x_init,
			input	wire	[Y_WIDTH-1:0]						s_param_y_init,
			
			input	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		s_param_eval_init,
			input	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		s_param_eval_xstep,
			input	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		s_param_eval_ystep,
			                
			input	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	s_param_fixed_init,
			input	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	s_param_fixed_xstep,
			input	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	s_param_fixed_ystep,
			
			input	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	s_param_float_init,
			input	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	s_param_float_xstep,
			input	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	s_param_float_ystep,
			
			input	wire										s_initial,
			input	wire										s_newline,
			input	wire										s_valid,
			output	wire										s_ready,
			
			output	wire	[X_WIDTH-1:0]						m_x,
			output	wire	[Y_WIDTH-1:0]						m_y,
			output	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	m_fixed_data,
			output	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	m_float_data,
			output	wire										m_valid,
			input	wire										m_ready
		);
	
	genvar	i;
	integer	j;
	
	
	// -------------------------------------
	//  �p�C�v���C������
	// -------------------------------------

	wire	[11:0]								stage_cke;
	wire	[11:0]								stage_valid;
	wire	[11:0]								next_valid;


	wire	[X_WIDTH-1:0]						src_param_x_init;
	wire	[Y_WIDTH-1:0]						src_param_y_init;
	
	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		src_param_eval_init;
	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		src_param_eval_xstep;
	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]		src_param_eval_ystep;
	        
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	src_param_fixed_init;
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	src_param_fixed_xstep;
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	src_param_fixed_ystep;
	
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	src_param_float_init;
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	src_param_float_xstep;
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	src_param_float_ystep;
	
	wire										src_initial;
	wire										src_newline;
	wire										src_valid;
	
	wire	[X_WIDTH-1:0]						sink_x;
	wire	[Y_WIDTH-1:0]						sink_y;
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	sink_fixed_data;
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	sink_float_data;
	
	jelly_pipeline_control
			#(
				.PIPELINE_STAGES	(12),
				.S_DATA_WIDTH		(X_WIDTH + Y_WIDTH + (EVAL_NUM*EVAL_DATA_WIDTH*3) + (FIXED_NUM*FIXED_DATA_WIDTH*3) + (FLOAT_NUM*FLOAT_DATA_WIDTH*3)),
				.M_DATA_WIDTH		(X_WIDTH + Y_WIDTH + (FIXED_NUM*FIXED_DATA_WIDTH) + (FLOAT_NUM*FLOAT_DATA_WIDTH)),
				.AUTO_VALID			(0),
				.INIT_DATA			(1),
				.MASTER_REGS		(MASTER_REGS)
			)
		i_pipeline_control
			(
				.reset				(reset),
				.clk				(clk),
				.cke				(cke),
				
				.s_data				({
										s_param_x_init,
										s_param_y_init,
										s_param_eval_init,
										s_param_eval_xstep,
										s_param_eval_ystep,
										s_param_fixed_init,
										s_param_fixed_xstep,
										s_param_fixed_ystep,
										s_param_float_init,
										s_param_float_xstep,
										s_param_float_ystep,
										s_initial,
										s_newline
									}),
				.s_valid			(s_valid),
				.s_ready			(s_ready),
				
				.m_data				({
										m_x,
										m_y,
										m_fixed_data,
										m_float_data
									}),
				.m_valid			(m_valid),
				.m_ready			(m_ready),
				
				.stage_cke			(stage_cke),
				.stage_valid		(stage_valid),
				.next_valid			(next_valid),
				
				.src_data			({
										src_param_x_init,
										src_param_y_init,
										src_param_eval_init,
										src_param_eval_xstep,
										src_param_eval_ystep,
										src_param_fixed_init,
										src_param_fixed_xstep,
										src_param_fixed_ystep,
										src_param_float_init,
										src_param_float_xstep,
										src_param_float_ystep,
										src_initial,
										src_newline
									}),
				.src_valid			(src_valid),
				.sink_data			({
										sink_x,
										sink_y,
										sink_fixed_data,
										sink_float_data
									}),
									
				.buffered			()
			);
	
	// ����M��
	reg		[10:0]	stage_initial;
	reg		[10:0]	stage_newline;
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin
			stage_initial[0] <= src_initial & src_valid;
			stage_newline[0] <= src_newline & src_valid;
		end
		for ( j = 1; j < 11; j = j+1 ) begin
			if ( stage_cke[j] ) begin
				stage_initial[j] <= stage_initial[j-1];
				stage_newline[j] <= stage_newline[j-1];
			end
		end
	end
	
	
	
	// -------------------------------------
	//  �̈攻�ʎ�
	// -------------------------------------
	
	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]	st0_eval_data;
	wire	[EVAL_NUM*EVAL_DATA_WIDTH-1:0]	st1_eval_data;
	
	reg		[EVAL_NUM*EVAL_DATA_WIDTH-1:0]	st0_param_eval_xstep;
	reg										st2_eval_valid;
	reg										st3_eval_valid;
	reg										st4_eval_valid;
	reg										st5_eval_valid;
	reg										st6_eval_valid;
	reg										st7_eval_valid;
	reg										st8_eval_valid;
	reg										st9_eval_valid;
	reg										st10_eval_valid;
	reg										st11_eval_valid;
	
	generate
	for ( i = 0; i < EVAL_NUM; i = i+1 ) begin : eval_loop
		// step y (stage0)
		jelly_integer_step
				#(
					.DATA_WIDTH		(EVAL_DATA_WIDTH)
				)
			i_integer_step_eval_y
				(
					.clk			(clk),
					.cke			(stage_cke[0]),
					
					.s_param_init	(src_param_eval_init [i*EVAL_DATA_WIDTH +: EVAL_DATA_WIDTH]),
					.s_param_step	(src_param_eval_ystep[i*EVAL_DATA_WIDTH +: EVAL_DATA_WIDTH]),					
					.s_initial		(src_valid & src_initial),
					.s_increment	(src_valid & src_newline),
					
					.m_data			(st0_eval_data       [i*EVAL_DATA_WIDTH +: EVAL_DATA_WIDTH])
				);
		
		// step x (stage1)
		jelly_integer_step
				#(
					.DATA_WIDTH		(EVAL_DATA_WIDTH)
				)
			i_integer_step_eval_x
				(
					.clk			(clk),
					.cke			(stage_cke[1]),
					
					.s_param_init	(st0_eval_data       [i*EVAL_DATA_WIDTH +: EVAL_DATA_WIDTH]),
					.s_param_step	(st0_param_eval_xstep[i*EVAL_DATA_WIDTH +: EVAL_DATA_WIDTH]),
					.s_initial		(stage_newline[1]),
					.s_increment	(stage_valid[1]),
					
					.m_data			(st1_eval_data       [i*EVAL_DATA_WIDTH +: EVAL_DATA_WIDTH])
				);			
	end
	endgenerate
	
	// ���蓝�� (stage2)
	always @(posedge clk) begin
		if ( stage_cke[2] ) begin
			st2_eval_valid <= 1'b1;
			for ( j = 0; j < EVAL_NUM; j = j+1 ) begin
				if ( st1_eval_data[(j*EVAL_DATA_WIDTH) + (EVAL_DATA_WIDTH-1)] ) begin
					st2_eval_valid <= 1'b0;
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if ( stage_cke[0] )  begin st0_param_eval_xstep <= src_param_eval_xstep;  end
		
		if ( stage_cke[3] )  begin st3_eval_valid  <= st2_eval_valid;  end
		if ( stage_cke[4] )  begin st4_eval_valid  <= st3_eval_valid;  end
		if ( stage_cke[5] )  begin st5_eval_valid  <= st4_eval_valid;  end
		if ( stage_cke[6] )  begin st6_eval_valid  <= st5_eval_valid;  end
		if ( stage_cke[7] )  begin st7_eval_valid  <= st6_eval_valid;  end
		if ( stage_cke[8] )  begin st8_eval_valid  <= st7_eval_valid;  end
		if ( stage_cke[9] )  begin st9_eval_valid  <= st8_eval_valid;  end
		if ( stage_cke[10] ) begin st10_eval_valid <= st9_eval_valid;  end
		if ( stage_cke[11] ) begin st11_eval_valid <= st10_eval_valid; end
	end
		
	
	
	// -------------------------------------
	//  �Œ菬���_���
	// -------------------------------------
	
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st0_fixed_data;
	wire	[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st1_fixed_data;
	
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st0_param_fixed_xstep;
	
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st2_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st3_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st4_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st5_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st6_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st7_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st8_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st9_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st10_fixed_data;
	reg		[FIXED_NUM*FIXED_DATA_WIDTH-1:0]	st11_fixed_data;
	
	generate
	for ( i = 0; i < FIXED_NUM; i = i+1 ) begin : fixed_loop
		// step y (stage0)
		jelly_integer_step
				#(
					.DATA_WIDTH		(FIXED_DATA_WIDTH)
				)
			i_integer_step_fixed_y
				(
					.clk			(clk),
					.cke			(stage_cke[0]),
					
					.s_param_init	(src_param_fixed_init [i*FIXED_DATA_WIDTH +: FIXED_DATA_WIDTH]),
					.s_param_step	(src_param_fixed_ystep[i*FIXED_DATA_WIDTH +: FIXED_DATA_WIDTH]),					
					.s_initial		(src_valid & src_initial),
					.s_increment	(src_valid & src_newline),
					
					.m_data			(st0_fixed_data       [i*FIXED_DATA_WIDTH +: FIXED_DATA_WIDTH])
				);
		
		// step x (stage1)
		jelly_integer_step
				#(
					.DATA_WIDTH		(FIXED_DATA_WIDTH)
				)
			i_integer_step_fixed_x
				(
					.clk			(clk),
					.cke			(stage_cke[1]),
					
					.s_param_init	(st0_fixed_data       [i*FIXED_DATA_WIDTH +: FIXED_DATA_WIDTH]),
					.s_param_step	(st0_param_fixed_xstep[i*FIXED_DATA_WIDTH +: FIXED_DATA_WIDTH]),
					.s_initial		(stage_newline[0]),
					.s_increment	(stage_valid[0]),
					
					.m_data			(st1_fixed_data       [i*FIXED_DATA_WIDTH +: FIXED_DATA_WIDTH])
				);			
	end
	endgenerate
	
	always @(posedge clk) begin
		if ( stage_cke[0] )  begin st0_param_fixed_xstep <= src_param_fixed_xstep;  end
		
		if ( stage_cke[2] )  begin st2_fixed_data  <= st1_fixed_data;  end
		if ( stage_cke[3] )  begin st3_fixed_data  <= st2_fixed_data;  end
		if ( stage_cke[4] )  begin st4_fixed_data  <= st3_fixed_data;  end
		if ( stage_cke[5] )  begin st5_fixed_data  <= st4_fixed_data;  end
		if ( stage_cke[6] )  begin st6_fixed_data  <= st5_fixed_data;  end
		if ( stage_cke[7] )  begin st7_fixed_data  <= st6_fixed_data;  end
		if ( stage_cke[8] )  begin st8_fixed_data  <= st7_fixed_data;  end
		if ( stage_cke[9] )  begin st9_fixed_data  <= st8_fixed_data;  end
		if ( stage_cke[10] ) begin st10_fixed_data <= st9_fixed_data;  end
		if ( stage_cke[11] ) begin st11_fixed_data <= st10_fixed_data; end
	end
	
	assign sink_fixed_data = st11_fixed_data;
	
	
	// -------------------------------------
	//  ���������_���
	// -------------------------------------
	
	reg		[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st0_param_float_xstep;
	reg		[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st1_param_float_xstep;
	reg		[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st2_param_float_xstep;
	reg		[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st3_param_float_xstep;
	reg		[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st4_param_float_xstep;
	reg		[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st5_param_float_xstep;
	
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st5_float_data;
	wire	[FLOAT_NUM*FLOAT_DATA_WIDTH-1:0]	st11_float_data;
	
	generate
		for ( i = 0; i < FLOAT_NUM; i = i+1 ) begin : float_loop
			// Y���W float 
			jelly_float_step
					#(
						.EXP_WIDTH		(FLOAT_EXP_WIDTH),
						.FRAC_WIDTH		(FLOAT_FRAC_WIDTH)
					)
				i_float_step_y
					(
						.clk			(clk),
						.stage_cke		(stage_cke[5:0]),
						
						.s_param_init	(src_param_float_init [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
						.s_param_step	(src_param_float_ystep[i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
						.s_initial		(src_valid & src_initial),
						.s_increment	(src_valid & src_newline),
						
						.m_data			(st5_float_data       [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH])
					);
			
			// X���W float 
			jelly_float_step
					#(
						.EXP_WIDTH		(FLOAT_EXP_WIDTH),
						.FRAC_WIDTH		(FLOAT_FRAC_WIDTH)
					)
				i_float_step_x
					(
						.clk			(clk),
						.stage_cke		(stage_cke[11:6]),
						
						.s_param_init	(st5_float_data       [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
						.s_param_step	(st5_param_float_xstep[i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH]),
						.s_initial		(stage_newline[5]),
						.s_increment	(stage_valid[5]),
						
						.m_data			(st11_float_data      [i*FLOAT_DATA_WIDTH +: FLOAT_DATA_WIDTH])
					);
		end
	endgenerate
	
	always @(posedge clk) begin
		if ( stage_cke[0] ) begin st0_param_float_xstep <= src_param_float_xstep; end
		if ( stage_cke[1] ) begin st1_param_float_xstep <= st0_param_float_xstep; end
		if ( stage_cke[2] ) begin st2_param_float_xstep <= st1_param_float_xstep; end
		if ( stage_cke[3] ) begin st3_param_float_xstep <= st2_param_float_xstep; end
		if ( stage_cke[4] ) begin st4_param_float_xstep <= st3_param_float_xstep; end
		if ( stage_cke[5] ) begin st5_param_float_xstep <= st4_param_float_xstep; end
	end
	
	// �o��
	assign sink_float_data = st11_float_data;
	
	
	
	// --------------------------------------
	//  �L���f�[�^����
	// --------------------------------------
	
	assign next_valid[0]  = src_valid;
	assign next_valid[1]  = stage_valid[0];
	assign next_valid[2]  = stage_valid[1];
	assign next_valid[3]  = stage_valid[2];
	assign next_valid[4]  = stage_valid[3];
	assign next_valid[5]  = stage_valid[4];
	assign next_valid[6]  = stage_valid[5];
	assign next_valid[7]  = stage_valid[6];
	assign next_valid[8]  = stage_valid[7] & st7_eval_valid;
	assign next_valid[9]  = stage_valid[8];
	assign next_valid[10] = stage_valid[9];
	assign next_valid[11] = stage_valid[10];
	
endmodule


`default_nettype wire


// end of file
