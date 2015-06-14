// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//   ���������_�̏����C���N�������g/�f�N�������g�l�����R�A
//
//                                 Copyright (C) 2015 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none


// ���������_�̏����C���N�������g/�f�N�������g�l�����R�A
module jelly_float_step
		#(
			parameter	EXP_WIDTH  = 8,
			parameter	FRAC_WIDTH = 23,
			parameter	DATA_WIDTH = 1 + EXP_WIDTH + FRAC_WIDTH
		)
		(
			input	wire						clk,
			input	wire						cke,
			
			input	wire	[DATA_WIDTH-1:0]	param_init,
			input	wire	[DATA_WIDTH-1:0]	param_step,
			
			input	wire						set_param,
			input	wire						increment,
			input	wire						in_valid,
			
			output	wire	[DATA_WIDTH-1:0]	out_data,
			output	wire						out_valid
		);
	
	
	wire								st0_init_sign = param_init[DATA_WIDTH-1];
	wire			[EXP_WIDTH-1:0]		st0_init_exp  = param_init[FRAC_WIDTH +: EXP_WIDTH];
	wire			[FRAC_WIDTH-1:0]	st0_init_frac = param_init[FRAC_WIDTH-1:0];
	wire								st0_step_sign = param_step[DATA_WIDTH-1];
	wire			[EXP_WIDTH-1:0]		st0_step_exp  = param_step[FRAC_WIDTH +: EXP_WIDTH];
	wire			[FRAC_WIDTH-1:0]	st0_step_frac = param_step[FRAC_WIDTH-1:0];
	wire								st0_set_param = set_param;
	wire								st0_increment = increment;
	wire								st0_valid     = in_valid;
	
	reg									st1_init_sign;
	reg				[EXP_WIDTH-1:0]		st1_init_shift;
	reg				[EXP_WIDTH-1:0]		st1_init_exp;
	reg				[FRAC_WIDTH-1:0]	st1_init_frac;
	reg									st1_step_sign;
	reg				[EXP_WIDTH-1:0]		st1_step_shift;
	reg				[FRAC_WIDTH-1:0]	st1_step_frac;
	reg									st1_set_param;
	reg									st1_increment;
	reg									st1_valid;
	
	reg									st2_init_sign;
	reg				[EXP_WIDTH-1:0]		st2_init_exp;
	reg				[FRAC_WIDTH:0]		st2_init_frac;
	reg									st2_step_sign;
	reg				[FRAC_WIDTH:0]		st2_step_frac;
	reg									st2_set_param;
	reg									st2_increment;
	reg									st2_valid;

	reg									st3_base_sign;
	reg				[EXP_WIDTH-1:0]		st3_base_exp;
	reg		signed	[FRAC_WIDTH+2:0]	st3_base_frac;
	reg		signed	[FRAC_WIDTH+1:0]	st3_step_frac;
	reg									st3_shift;
	wire	signed	[FRAC_WIDTH+2:0]	st3_inc_frac = ((st3_base_frac >>> st3_shift) + st3_step_frac);
	reg									st3_valid;
	
	reg									st4_sign;
	reg				[EXP_WIDTH-1:0]		st4_exp;
	reg				[FRAC_WIDTH:0]		st4_frac;
	reg									st4_valid;
	
	reg									st5_sign;
	reg				[EXP_WIDTH-1:0]		st5_exp;
	reg				[FRAC_WIDTH:0]		st5_frac;
	reg				[EXP_WIDTH-1:0]		st5_shift;
	reg									st5_valid;
	
	reg									st6_sign;
	reg				[EXP_WIDTH-1:0]		st6_exp;
	reg				[FRAC_WIDTH-1:0]	st6_frac;
	reg									st6_valid;

	integer								i;
	
	always @(posedge clk) begin
		if ( cke ) begin
			// stage 1 (�w�������ǂ���ɍ��킹�邩����)
			st1_init_sign <= st0_init_sign;
			st1_init_frac <= st0_init_frac;
			st1_step_sign <= st0_step_sign;
			st1_step_frac <= st0_step_frac;
			if ( st0_init_exp >= st0_step_exp ) begin
				st1_init_exp   <= st0_init_exp;
				st1_init_shift <= 0;
				st1_step_shift <= st0_init_exp - st0_step_exp;
			end
			else begin
				st1_init_exp   <= st0_step_exp;
				st1_init_shift <= st0_step_exp - st0_init_exp;
				st1_step_shift <= 0;
			end
			st1_set_param <= st0_set_param;
			st1_increment <= st0_increment;
			st1_valid     <= st0_valid;
			
			
			// stage 2 (�����킹)
			st2_init_sign <= st1_init_sign;
			st2_init_exp  <= st1_init_exp;
			st2_init_frac <= ({1'b1, st1_init_frac} >> st1_init_shift);
			st2_step_sign <= st1_step_sign;
			st2_step_frac <= ({1'b1, st1_step_frac} >> st1_step_shift);
			st2_set_param <= st1_set_param;
			st2_increment <= st1_increment; // & st1_valid;
			st2_valid     <= st1_valid;
			
			
			// stage 3 (�C���N�������g�v�Z)
			if ( st2_set_param ) begin
				// ������
				st3_base_sign <= st2_init_sign;
				st3_base_exp  <= st2_init_exp;
				st3_base_frac <= {1'b0, st2_init_frac};
				st3_step_frac <= (st2_init_sign == st2_step_sign) ? {1'b0, st2_step_frac} : -{1'b0, st2_step_frac};
				st3_shift     <= 1'b0;
			end
			else if ( st2_increment ) begin
				// �C���N�������g
				st3_shift <= (st3_inc_frac[FRAC_WIDTH+2] != st3_inc_frac[FRAC_WIDTH+1])
								|| (st3_inc_frac[FRAC_WIDTH+1] && st3_inc_frac[FRAC_WIDTH:0] == 0);
				st3_base_exp  <= st3_base_exp + st3_shift;
				st3_base_frac <= st3_inc_frac;
			end
			st3_valid <= st2_valid;
			
			
			// stage4 (�������`)
			st4_sign  <= st3_base_frac[FRAC_WIDTH+2] ? ~st3_base_sign : st3_base_sign ;
			st4_exp   <= st3_base_exp + st3_shift;
			st4_frac  <= st3_base_frac[FRAC_WIDTH+1] ? -(st3_base_frac >>> st3_shift) : (st3_base_frac >>> st3_shift);
			st4_valid <= st3_valid;
			
			
			// stage5 (���������o)
			st5_sign  <= st4_sign;
			st5_exp   <= st4_exp;
			st5_frac  <= st4_frac;
			st5_shift <= 0;
			for ( i = FRAC_WIDTH; i >= 0; i = i - 1 ) begin
				if ( st4_frac[FRAC_WIDTH - i] ) begin
					st5_shift <= i;
				end
			end
			st5_valid <= st4_valid;
			
			
			// stage6 (�������␳)
			st6_sign  <= st5_sign;
			st6_exp   <= st5_exp - st5_shift;
			if ( st5_frac == 0 ) begin
				st6_exp   <= 0;
			end
			st6_frac  <= (st5_frac << st5_shift);
			st6_valid <= st5_valid;
		end
	end
	
	assign out_data  = {st6_sign, st6_exp, st6_frac};
	assign out_valid = st6_valid;
	
endmodule


`default_nettype wire


// end of file
