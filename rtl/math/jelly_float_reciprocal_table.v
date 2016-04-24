// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   reciprocal
//
//                                 Copyright (C) 2008-2010 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_float_reciprocal_table
		#(
			parameter	FRAC_WIDTH = 23,
			parameter	D_WIDTH    = 6,
			parameter	K_WIDTH    = FRAC_WIDTH - D_WIDTH,
			parameter	GRAD_WIDTH = FRAC_WIDTH,
			parameter	OUT_REGS   = 1,
			parameter	FILE_NAME  = "float_reciprocal.hex"
		)
		(
			input	wire						reset,
			input	wire						clk,
			input	wire	[1:0]				cke,
			
			input	wire	[D_WIDTH-1:0]		in_d,
			
			output	wire	[FRAC_WIDTH-1:0]	out_frac,
			output	wire	[GRAD_WIDTH-1:0]	out_grad
		);
	
	
	// Real���牼�������o��
	function [FRAC_WIDTH:0] get_frac(input real r);
	reg		[63:0]	b;
	reg		[52:0]	f;
	begin
		b        = $realtobits(r);
		f        = {1'b0, b[51:0]};
		f        = f + (52'h8_0000_0000_0000 >> FRAC_WIDTH);	// �l�̌ܓ�
		get_frac = f[52 -: (FRAC_WIDTH+1)];
	end
	endfunction
	
	// �w����/���������� Real ����
	function real make_real(input [10:0] e, input [FRAC_WIDTH-1:0] f);
	reg		[63:0]	b;
	integer			i;
	begin
		b                   = 64'd0;
		b[52 +: 11]         = e + 11'd1023;
		b[51 -: FRAC_WIDTH] = f;
		make_real           = $bitstoreal(b);
	end
	endfunction
	

	task print_real(input real r);
	reg		[63:0]	b;
	begin
		b = $realtobits(r);
		$display("%b_%b_%b", b[63], b[62:52], b[51:0]); 
	end
	endtask
	
	
	// �e�[�u����`
	localparam	TBL_WIDTH = FRAC_WIDTH + GRAD_WIDTH;
	localparam	TBL_SIZE  = (1 << D_WIDTH);
	
	reg		[TBL_WIDTH-1:0]		mem	[0:TBL_SIZE-1];
	
	
	
	// �e�[�u��������
	integer						i;
	integer						fp;
	
	real						step;
	real						base, base_recip;
	real						next, next_recip;
	reg		[FRAC_WIDTH:0]		base_frac;
	reg		[FRAC_WIDTH:0]		next_frac;
	reg		[FRAC_WIDTH-1:0]	grad;
	reg		[FRAC_WIDTH-1:0]	grad_max;
	
	
	initial begin
		step = make_real(-D_WIDTH, 0);
		
		base       = make_real(0, 0);
		base_recip = 1.0 / base;
		base_frac  = (1 << FRAC_WIDTH);	// �ŏ��������グ�Ȃ̂ő΍�
		
//		$display("base"); print_real(base);
//		$display("step"); print_real(step);
		
		grad_max = 0;
		for ( i = 0; i < TBL_SIZE; i = i+1 ) begin
			next       = base + step;
			next_recip = 1.0 / next;
			next_frac  = get_frac(next_recip);
			
			grad       = base_frac - next_frac;
			if ( grad > grad_max ) grad_max = grad;
			
			mem[i][GRAD_WIDTH +: FRAC_WIDTH] = base_frac[0 +: FRAC_WIDTH];
			mem[i][0          +: GRAD_WIDTH] = grad[0 +: GRAD_WIDTH];
			
//			$display("<%d:%d>", i, grad);
//			$display("base:%h", base_frac);		print_real(base);	print_real(base_recip);
//			$display("next:%h", next_frac);		print_real(next);	print_real(next_recip);
			
			base       = next;
			base_recip = next_recip;
			base_frac  = next_frac;
		end
		$display("grad_max:%h", grad_max);
		
		fp = $fopen(FILE_NAME, "w");
		for ( i = 0; i < TBL_SIZE; i = i+1 ) begin
			$fdisplay(fp, "%h", mem[i]);
		end
		$fclose(fp);
	end
	
	reg		[TBL_WIDTH-1:0]		tbl_out;
	always @(posedge clk) begin
		if ( cke[0] ) begin
			tbl_out <= mem[in_d];
		end
	end
	
	reg		[TBL_WIDTH-1:0]		tbl_reg;
	always @(posedge clk) begin
		if ( cke[1] ) begin
			tbl_reg <= tbl_out;
		end
	end
	
	
	generate
	if ( OUT_REGS ) begin
		assign out_frac = tbl_reg[GRAD_WIDTH +: FRAC_WIDTH];
		assign out_grad = tbl_reg[0          +: GRAD_WIDTH];
	end
	else begin
		assign out_frac = tbl_out[GRAD_WIDTH +: FRAC_WIDTH];
		assign out_grad = tbl_out[0          +: GRAD_WIDTH];
	end
	endgenerate
	
	
endmodule



`default_nettype wire


// end of file
