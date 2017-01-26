// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   math
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// �Œ菬���_�Ŏˉe�ϊ����s���ꍇ�̏��Z��
// ���������_�������t�����P�������e������Z

module jelly_fixed_matrix_divider
		#(
			parameter	USER_WIDTH                = 0,
			
			parameter	NUM                       = 3,
			parameter	S_DIVIDEND_INT_WIDTH      = 16,
			parameter	S_DIVIDEND_FRAC_WIDTH     = 16,
			parameter	S_DIVISOR_INT_WIDTH       = 16,
			parameter	S_DIVISOR_FRAC_WIDTH      = 16,
			parameter	M_QUOTIENT_INT_WIDTH      = 12,
			parameter	M_QUOTIENT_FRAC_WIDTH     = 4,
			
			parameter	DIVIDEND_FIXED_INT_WIDTH  = 16,
			parameter	DIVIDEND_FIXED_FRAC_WIDTH = 8,
			
			parameter	DIVISOR_FLOAT_EXP_WIDTH   = 6,
			parameter	DIVISOR_FLOAT_EXP_OFFSET  = (1 << (DIVISOR_FLOAT_EXP_WIDTH-1)) - 1,
			parameter	DIVISOR_FLOAT_FRAC_WIDTH  = 16,
			
			parameter	CLIP                      = 1,
			
			parameter	D_WIDTH                   = 8,	// interpolation table addr bits
			parameter	K_WIDTH                   = DIVISOR_FLOAT_FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH                = DIVISOR_FLOAT_FRAC_WIDTH,
			parameter	RAM_TYPE                  = "block",
			
			parameter	MASTER_IN_REGS            = 1,
			parameter	MASTER_OUT_REGS           = 1,
			
			parameter	DEVICE                    = "RTL"
		)
		(
			input	wire										reset,
			input	wire										clk,
			input	wire										cke,
			
			input	wire			[USER_BITS-1:0]				s_user,
			input	wire			[NUM*S_DIVIDEND_WIDTH-1:0]	s_dividend,
			input	wire	signed	[S_DIVISOR_WIDTH-1:0]		s_divisor,
			input	wire										s_valid,
			output	wire										s_ready,
			
			output	wire			[USER_BITS-1:0]				m_user,
			output	wire			[NUM*M_QUOTIENT_WIDTH-1:0]	m_quotient,
			output	wire										m_valid,
			input	wire										m_ready
		);
	
	genvar									i;
	
	
	// -------------------------------------
	//  localparam
	// -------------------------------------
	
	localparam	USER_BITS            = USER_WIDTH > 0 ? USER_WIDTH : 1;
	localparam	S_DIVIDEND_WIDTH     = S_DIVIDEND_INT_WIDTH + S_DIVIDEND_FRAC_WIDTH;
	localparam	S_DIVISOR_WIDTH      = S_DIVISOR_INT_WIDTH  + S_DIVISOR_FRAC_WIDTH;
	localparam	M_QUOTIENT_WIDTH     = M_QUOTIENT_INT_WIDTH + M_QUOTIENT_FRAC_WIDTH;
	
	localparam	DIVIDEND_FIXED_WIDTH = DIVIDEND_FIXED_INT_WIDTH + DIVIDEND_FIXED_FRAC_WIDTH;
	localparam	DIVISOR_FLOAT_WIDTH  = 1 + DIVISOR_FLOAT_EXP_WIDTH + DIVISOR_FLOAT_FRAC_WIDTH;
	
	
	// -------------------------------------
	//  input
	// -------------------------------------
	
	wire	[NUM*DIVIDEND_FIXED_WIDTH-1:0]	s_fixed_dividend;
	
	generate
	for ( i = 0; i < NUM; i = i+1 ) begin : loop_input
		wire	signed	[S_DIVIDEND_WIDTH-1:0]		src_dividend = s_dividend[i*S_DIVIDEND_WIDTH +: S_DIVIDEND_WIDTH];
		
		wire	signed	[DIVIDEND_FIXED_WIDTH-1:0]	src_fixed_dividend;
		if ( S_DIVISOR_FRAC_WIDTH > DIVIDEND_FIXED_FRAC_WIDTH ) begin
			assign src_fixed_dividend = (src_dividend >>> (S_DIVISOR_FRAC_WIDTH - DIVIDEND_FIXED_FRAC_WIDTH));
		end
		else begin
			assign src_fixed_dividend = (src_dividend <<< (DIVIDEND_FIXED_FRAC_WIDTH - S_DIVISOR_FRAC_WIDTH));
		end
		
		assign s_fixed_dividend[i*DIVIDEND_FIXED_WIDTH +: DIVIDEND_FIXED_WIDTH] = src_fixed_dividend;
	end
	endgenerate
	
	
	
	
	// -------------------------------------
	//  fixed to float (divisor)
	// -------------------------------------
	
	wire	[USER_BITS-1:0]					float_user;
	wire	[NUM*DIVIDEND_FIXED_WIDTH-1:0]	float_fixed_dividend;
	wire	[DIVISOR_FLOAT_WIDTH-1:0]		float_divisor;
	wire									float_valid;
	wire									float_ready;
	
	jelly_fixed_to_float
				#(
					.USER_WIDTH				(USER_BITS + NUM*DIVIDEND_FIXED_WIDTH),
					
					.FIXED_SIGNED			(1),
					.FIXED_INT_WIDTH		(S_DIVISOR_INT_WIDTH),
					.FIXED_FRAC_WIDTH		(S_DIVISOR_FRAC_WIDTH),
					.FIXED_EXP_WIDTH		(0),
					
					.FLOAT_EXP_WIDTH		(DIVISOR_FLOAT_EXP_WIDTH),
					.FLOAT_EXP_OFFSET		(DIVISOR_FLOAT_EXP_OFFSET),
					.FLOAT_FRAC_WIDTH		(DIVISOR_FLOAT_FRAC_WIDTH),
					
					.MASTER_IN_REGS			(0),
					.MASTER_OUT_REGS		(0)
				)
			i_fixed_to_float_divisor
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(cke),
					
					.s_user					({s_user, s_fixed_dividend}),
					.s_fixed				(s_divisor),
					.s_exp					(1'b0),
					.s_valid				(s_valid),
					.s_ready				(s_ready),
					
					.m_user					({float_user, float_fixed_dividend}),
					.m_float				(float_divisor),
					.m_valid				(float_valid),
					.m_ready				(float_ready)
				);
	
	
	
	// -------------------------------------
	//  reciprocal
	// -------------------------------------
	
	wire	[USER_BITS-1:0]					recip_user;
	wire	[NUM*DIVIDEND_FIXED_WIDTH-1:0]	recip_fixed_dividend;
	wire	[DIVISOR_FLOAT_WIDTH-1:0]		recip_divisor;
	wire									recip_valid;
	wire									recip_ready;
	
	jelly_float_reciprocal
			#(
				.USER_WIDTH				(USER_BITS + NUM*DIVIDEND_FIXED_WIDTH),
				
				.EXP_WIDTH				(DIVISOR_FLOAT_EXP_WIDTH),
				.EXP_OFFSET				(DIVISOR_FLOAT_EXP_OFFSET),
				.FRAC_WIDTH				(DIVISOR_FLOAT_FRAC_WIDTH),
				
				.D_WIDTH				(D_WIDTH),
				.K_WIDTH				(K_WIDTH),
				.GRAD_WIDTH				(GRAD_WIDTH),
				.RAM_TYPE				(RAM_TYPE),
				
				.MASTER_IN_REGS			(0),
				.MASTER_OUT_REGS		(0),
				
				.MAKE_TABLE				(1)
			)
		i_float_reciprocal
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_user					({float_user, float_fixed_dividend}),
				.s_float				(float_divisor),
				.s_valid				(float_valid),
				.s_ready				(float_ready),
				
				.m_user					({recip_user, recip_fixed_dividend}),
				.m_float				(recip_divisor),
				.m_valid				(recip_valid),
				.m_ready				(recip_ready)
			);
	
	
	
	// -------------------------------------
	//  multiplication
	// -------------------------------------
	
	jelly_fixed_float_mul
			#(
				.USER_WIDTH				(USER_WIDTH),
				
				.S_FLOAT_EXP_WIDTH		(DIVISOR_FLOAT_EXP_WIDTH),
				.S_FLOAT_EXP_OFFSET		(DIVISOR_FLOAT_EXP_OFFSET),
				.S_FLOAT_FRAC_WIDTH		(DIVISOR_FLOAT_FRAC_WIDTH),
				
				.S_FIXED_INT_WIDTH		(DIVIDEND_FIXED_INT_WIDTH),
				.S_FIXED_FRAC_WIDTH		(DIVIDEND_FIXED_FRAC_WIDTH),
				
				.M_FIXED_INT_WIDTH		(M_QUOTIENT_INT_WIDTH),
				.M_FIXED_FRAC_WIDTH		(M_QUOTIENT_FRAC_WIDTH),
				
				.CLIP					(CLIP),
				
				.MASTER_IN_REGS			(MASTER_IN_REGS),
				.MASTER_OUT_REGS		(MASTER_OUT_REGS),
				
				.DEVICE					(DEVICE)
			)
		i_fixed_float_mul_0
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_user					(recip_user),
				.s_float				(recip_divisor),
				.s_fixed				(recip_fixed_dividend[DIVIDEND_FIXED_WIDTH-1:0]),
				.s_valid				(recip_valid),
				.s_ready				(recip_ready),
				
				.m_user					(m_user),
				.m_fixed				(m_quotient[M_QUOTIENT_WIDTH-1:0]),
				.m_valid				(m_valid),
				.m_ready				(m_ready)
			);
	
	generate
	for ( i = 1; i < NUM; i = i+1 ) begin : loop_mul
		jelly_fixed_float_mul
				#(
					.USER_WIDTH				(0),
					
					.S_FLOAT_EXP_WIDTH		(DIVISOR_FLOAT_EXP_WIDTH),
					.S_FLOAT_EXP_OFFSET		(DIVISOR_FLOAT_EXP_OFFSET),
					.S_FLOAT_FRAC_WIDTH		(DIVISOR_FLOAT_FRAC_WIDTH),
					
					.S_FIXED_INT_WIDTH		(DIVIDEND_FIXED_INT_WIDTH),
					.S_FIXED_FRAC_WIDTH		(DIVIDEND_FIXED_FRAC_WIDTH),
					
					.M_FIXED_INT_WIDTH		(M_QUOTIENT_INT_WIDTH),
					.M_FIXED_FRAC_WIDTH		(M_QUOTIENT_FRAC_WIDTH),
					
					.CLIP					(CLIP),
					
					.MASTER_IN_REGS			(MASTER_IN_REGS),
					.MASTER_OUT_REGS		(MASTER_OUT_REGS),
					
					.DEVICE					(DEVICE)
				)
			i_fixed_float_mul_1
				(
					.reset					(reset),
					.clk					(clk),
					.cke					(cke),
					
					.s_user					(1'b0),
					.s_float				(recip_divisor),
					.s_fixed				(recip_fixed_dividend[i*DIVIDEND_FIXED_WIDTH +: DIVIDEND_FIXED_WIDTH]),
					.s_valid				(recip_valid),
					.s_ready				(),
					
					.m_user					(),
					.m_fixed				(m_quotient[i*M_QUOTIENT_WIDTH +: M_QUOTIENT_WIDTH]),
					.m_valid				(),
					.m_ready				(m_ready)
				);
	end
	endgenerate
	
endmodule



`default_nettype wire



// end of file