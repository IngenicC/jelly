// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//   crossbar
//
//                                 Copyright (C) 2009 by Ryuji Fuchikami
//                                 http://homepage3.nifty.com/ryuz/
// ---------------------------------------------------------------------------



`timescale       1ns / 1ps
`default_nettype none


// selecter
module jelly_crossbar
		#(
			parameter	DATA_WIDTH      = 32,
			parameter	SRC_NUM         = 8,
			parameter	DST_NUM         = 16,
			parameter	SRC_INDEX_WIDTH = 3,
			parameter	DST_INDEX_WIDTH = 4,
			parameter	STAGE0_REG      = 1,
			parameter	STAGE1_REG      = 1,
			parameter	STAGE2_REG      = 1
		)
		(
			input	wire									clk,
			input	wire	[2:0]							cke,
			input	wire									reset,
			
			input	wire	[SRC_NUM-1:0]					in_valid,
			input	wire	[SRC_NUM*DST_INDEX_WIDTH-1:0]	in_dst_index,
			input	wire	[SRC_NUM*DATA_WIDTH-1:0]		in_data,
			
			output	wire	[DST_NUM-1:0]					out_valid,
			output	wire	[DST_NUM*SRC_INDEX_WIDTH-1:0]	out_src_index,
			output	wire	[DST_NUM*DATA_WIDTH-1:0]		out_data
		);

	integer		i, j, k;
	
	// stage0	
	wire	[SRC_NUM-1:0]					stage0_in_valid;
	wire	[SRC_NUM*DST_INDEX_WIDTH-1:0]	stage0_in_dst_index;
	wire	[SRC_NUM*DATA_WIDTH-1:0]		stage0_in_data;
	
	wire	[SRC_NUM-1:0]					stage0_out_valid;
	wire	[SRC_NUM*DST_INDEX_WIDTH-1:0]	stage0_out_dst_index;
	wire	[SRC_NUM*DATA_WIDTH-1:0]		stage0_out_data;
	
	assign stage0_in_valid     = in_valid;
	assign stage0_in_dst_index = in_dst_index;
	assign stage0_in_data      = in_data;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(SRC_NUM + SRC_NUM*DST_INDEX_WIDTH + SRC_NUM*DATA_WIDTH),
				.REG		(STAGE0_REG),
				.INIT		({{SRC_NUM{1'b0}}, {(SRC_NUM*DST_INDEX_WIDTH){1'bx}} + {(SRC_NUM*DATA_WIDTH){1'bx}}})
			)
		i_pipeline_ff_stage0
			(
				.reset		(reset),
				.enable		(cke[0]),
				.clk		(clk),
                
				.in_data	({stage0_in_valid,  stage0_in_dst_index,  stage0_in_data}),
				.out_data	({stage0_out_valid, stage0_out_dst_index, stage0_out_data})		
			);
	
	// stage1
	reg		[DST_NUM*SRC_NUM-1:0]			stage1_in_valid_map;
	wire	[SRC_NUM*DATA_WIDTH-1:0]		stage1_in_data;
	
	wire	[DST_NUM*SRC_NUM-1:0]			stage1_out_valid_map;
	wire	[SRC_NUM*DATA_WIDTH-1:0]		stage1_out_data;
	
	always @* begin
		for ( i = 0; i < DST_NUM; i = i + 1 ) begin
			for ( j = 0; j < SRC_NUM; j = j + 1 ) begin
				stage1_in_valid_map[i*SRC_NUM + j] = stage0_out_valid[j] & (stage0_out_dst_index[j*DST_INDEX_WIDTH +: DST_INDEX_WIDTH] == i);
			end
		end
	end
	
	assign stage1_in_data = stage0_out_data;
	
	jelly_pipeline_ff
			#(
				.WIDTH		(DST_NUM*SRC_NUM + SRC_NUM*DATA_WIDTH),
				.REG		(STAGE1_REG),
				.INIT		({{(DST_NUM*SRC_NUM){1'b0}}, {(SRC_NUM*DATA_WIDTH){1'bx}}})
			)
		i_pipeline_ff_stage1
			(
				.reset		(reset),
				.enable		(cke[1]),
				.clk		(clk),
                
				.in_data	({stage1_in_valid_map,  stage1_in_data}),
				.out_data	({stage1_out_valid_map, stage1_out_data})		
			);
	
	// stage2
	reg		[DST_NUM-1:0]					stage2_in_valid;
	reg		[DST_NUM*SRC_INDEX_WIDTH-1:0]	stage2_in_src_index;
	reg		[DST_NUM*DATA_WIDTH-1:0]		stage2_in_data;
	
	wire	[DST_NUM-1:0]					stage2_out_valid;
	wire	[DST_NUM*SRC_INDEX_WIDTH-1:0]	stage2_out_src_index;
	wire	[DST_NUM*DATA_WIDTH-1:0]		stage2_out_data;
	
	always @* begin
		stage2_in_valid     = {DST_NUM{1'b0}};
		stage2_in_src_index = {(DST_NUM*SRC_INDEX_WIDTH){1'b0}};
		stage2_in_data      = {(DST_NUM*DATA_WIDTH){1'b0}};
		for ( i = 0; i < DST_NUM; i = i + 1 ) begin
			for ( j = SRC_NUM-1; j >= 0; j = j - 1 ) begin 
				if ( stage1_out_valid_map[i*SRC_NUM + j] ) begin
					stage2_in_valid[i]                                        = 1'b1;
					for ( k = 0; k < SRC_INDEX_WIDTH; k = k + 1 ) begin
						stage2_in_src_index[i*SRC_INDEX_WIDTH + k] = ((j >> k) & 1);
					end
					for ( k = 0; k < DATA_WIDTH; k = k + 1 ) begin
						stage2_in_data[i*DATA_WIDTH + k] = stage1_out_data[j*DATA_WIDTH + k];
					end
				end
			end
		end
	end
	
	jelly_pipeline_ff
			#(
				.WIDTH		(DST_NUM + DST_NUM*SRC_INDEX_WIDTH + DST_NUM*DATA_WIDTH),
				.REG		(STAGE1_REG),
				.INIT		({{(DST_NUM){1'b0}}, {(DST_NUM*SRC_INDEX_WIDTH){1'bx}}, {(DST_NUM*DATA_WIDTH){1'bx}}})
			)
		i_pipeline_ff_stage2
			(
				.reset		(reset),
				.enable		(cke[2]),
				.clk		(clk),
                
				.in_data	({stage2_in_valid,  stage2_in_src_index,  stage2_in_data}),
				.out_data	({stage2_out_valid, stage2_out_src_index, stage2_out_data})		
			);
	
	assign out_valid     = stage2_out_valid;
	assign out_src_index = stage2_out_src_index;
	assign out_data      = stage2_out_data;
		
endmodule


// end of file
