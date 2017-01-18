// ---------------------------------------------------------------------------
//  Jelly  -- the system on fpga system
//
//                                 Copyright (C) 2008-2017 by Ryuji Fuchikami
//                                 http://ryuz.my.coocan.jp/
//                                 https://github.com/ryuz/jelly.git
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



// AXI�Ȃǂ̃R�}���h���s�����p��z��


// semaphore
module jelly_semaphore
		#(
			parameter	ASYNC         = 1,
			parameter	COUNTER_WIDTH = 9,
			parameter	INIT_COUNTER  = 256
		)
		(
			// �J�E���^�l�ԋp��
			input	wire						rel_reset,
			input	wire						rel_clk,
			input	wire	[COUNTER_WIDTH-1:0]	rel_add,
			input	wire						rel_valid,
			
			// �J�E���^�l�擾��
			input	wire						req_reset,
			input	wire						req_clk,
			input	wire	[COUNTER_WIDTH-1:0]	req_sub,	// limit���ɗv�����Ȃ�����
			input	wire						req_valid,
			
			output	wire						out_limit
		);
	
	// �ԋp�l�̃N���b�N�悹����
	
	
	
	
endmodule


`default_nettype wire


// end of file
