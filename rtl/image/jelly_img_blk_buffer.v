// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   image processing
//
//                                 Copyright (C) 2008-2016 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps
`default_nettype none



module jelly_img_blk_buffer
		#(
			parameter	DATA_WIDTH   = 8,
			parameter	PIXEL_NUM    = 5,
			parameter	LINE_NUM     = 5,
			parameter	PIXEL_CENTER = PIXEL_NUM / 2,
			parameter	LINE_CENTER  = LINE_NUM / 2,
			parameter	MAX_Y_NUM    = 1024,
			parameter	BORDER_MODE  = "REPLICATE",			// NONE, CONSTANT, REPLICATE, REFLECT, REFLECT_101
			parameter	BORDER_VALUE = {DATA_WIDTH{1'b0}},
			parameter	RAM_TYPE     = "block"
		)
		(
			input	wire										reset,
			input	wire										clk,
			input	wire										cke,
			
			// slave (input)
			input	wire										s_img_line_first,
			input	wire										s_img_line_last,
			input	wire										s_img_pixel_first,
			input	wire										s_img_pixel_last,
			input	wire	[DATA_WIDTH-1:0]					s_img_data,
			
			// master (output)
			output	wire										m_img_line_first,
			output	wire										m_img_line_last,
			output	wire										m_img_pixel_first,
			output	wire										m_img_pixel_last,
			output	wire	[LINE_NUM*PIXEL_NUM*DATA_WIDTH-1:0]	m_img_data
		);
	
	wire								img_lbuf_line_first;
	wire								img_lbuf_line_last;
	wire								img_lbuf_pixel_first;
	wire								img_lbuf_pixel_last;
	wire	[LINE_NUM*DATA_WIDTH-1:0]	img_lbuf_data;
	
	jelly_img_line_buffer
			#(
				.DATA_WIDTH				(DATA_WIDTH),
				.LINE_NUM				(LINE_NUM),
				.LINE_CENTER			(LINE_CENTER),
				.MAX_Y_NUM				(MAX_Y_NUM),
				.BORDER_MODE 			(BORDER_MODE),
				.BORDER_VALUE			(BORDER_VALUE),
				.RAM_TYPE				(RAM_TYPE)
			)
		i_img_line_buffer
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_img_line_first		(s_img_line_first),
				.s_img_line_last		(s_img_line_last),
				.s_img_pixel_first		(s_img_pixel_first),
				.s_img_pixel_last		(s_img_pixel_last),
				.s_img_data				(s_img_data),
				
				.m_img_line_first		(img_lbuf_line_first),
				.m_img_line_last		(img_lbuf_line_last),
				.m_img_pixel_first		(img_lbuf_pixel_first),
				.m_img_pixel_last		(img_lbuf_pixel_last),
				.m_img_data				(img_lbuf_data)
			);
	
	wire										img_pbuf_line_first;
	wire										img_pbuf_line_last;
	wire										img_pbuf_pixel_first;
	wire										img_pbuf_pixel_last;
	wire	[PIXEL_NUM*LINE_NUM*DATA_WIDTH-1:0]	img_pbuf_data;
	
	jelly_img_pixel_buffer
			#(
				.DATA_WIDTH				(LINE_NUM*DATA_WIDTH),
				.PIXEL_NUM				(PIXEL_NUM),
				.PIXEL_CENTER			(PIXEL_CENTER),
				.BORDER_MODE 			(BORDER_MODE),
				.BORDER_VALUE			(BORDER_VALUE)
			)
		i_img_pixel_buffer
			(
				.reset					(reset),
				.clk					(clk),
				.cke					(cke),
				
				.s_img_line_first		(img_lbuf_line_first),
				.s_img_line_last		(img_lbuf_line_last),
				.s_img_pixel_first		(img_lbuf_pixel_first),
				.s_img_pixel_last		(img_lbuf_pixel_last),
				.s_img_data				(img_lbuf_data),
				
				.m_img_line_first		(img_pbuf_line_first),
				.m_img_line_last		(img_pbuf_line_last),
				.m_img_pixel_first		(img_pbuf_pixel_first),
				.m_img_pixel_last		(img_pbuf_pixel_last),
				.m_img_data				(img_pbuf_data)
			);
	
	assign m_img_line_first  = img_pbuf_line_first;
	assign m_img_line_last   = img_pbuf_line_last;
	assign m_img_pixel_first = img_pbuf_pixel_first;
	assign m_img_pixel_last  = img_pbuf_pixel_last;
	
	genvar			x, y;
	generate
	for ( y = 0; y < LINE_NUM; y = y+1 ) begin : y_loop
		for ( x = 0; x < PIXEL_NUM; x = x+1 ) begin : x_loop
			assign m_img_data[(y*PIXEL_NUM+x)*DATA_WIDTH +: DATA_WIDTH] = img_pbuf_data[(x*LINE_NUM+y)*DATA_WIDTH +: DATA_WIDTH];
		end
	end
	endgenerate
	
endmodule


`default_nettype wire


// end of file
