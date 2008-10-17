`timescale 1ns / 1ps


module pipeline_fifo_async
			(
				reset,
				in_clk, in_en, in_data, in_ready, in_free_num,
				out_clk, out_en, out_data, out_ready, out_data_num
			);
	
	parameter	DATA_WIDTH = 8;
	parameter	PTR_WIDTH  = 8;
	
	
	input						reset;
	
	input						in_clk;
	input						in_en;
	input	[DATA_WIDTH-1:0]	in_data;
	output						in_ready;
	output	[PTR_WIDTH:0]		in_free_num;
	
	input						out_clk;
	output						out_en;
	output	[DATA_WIDTH-1:0]	out_data;
	input						out_ready;
	output	[PTR_WIDTH:0]		out_data_num;

	
	
	// ---------------------------------
	//  RAM
	// ---------------------------------
	
	wire						ram_wr_en;
	wire	[PTR_WIDTH-1:0]		ram_wr_addr;
	wire	[DATA_WIDTH-1:0]	ram_wr_data;
	
	wire						ram_rd_en;
	wire	[PTR_WIDTH-1:0]		ram_rd_addr;
	wire	[DATA_WIDTH-1:0]	ram_rd_data;
	
	// ram
	ram_dualport
			#(
				.DATA_WIDTH		(DATA_WIDTH),
				.ADDR_WIDTH		(PTR_WIDTH)
			)
		i_ram_dualport
			(
				.clk0			(in_clk),
				.en0			(ram_wr_en),
				.we0			(1'b1),
				.addr0			(ram_wr_addr),
				.din0			(ram_wr_data),
				.dout0			(),
				
				.clk1			(out_clk),
				.en1			(ram_rd_en),
				.we1			(1'b0),
				.addr1			(ram_rd_addr),
				.din1			(0),
				.dout1			(ram_rd_data)
			);	
	
	
	
	// ---------------------------------
	//  FIFO pointer
	// ---------------------------------
	
	// write
	reg		[PTR_WIDTH:0]		wr_wptr;
	wire	[PTR_WIDTH:0]		wr_wptr_gray;
	reg		[PTR_WIDTH:0]		wr_wptr_gray_out_async;
	wire						wr_full;
	
	reg		[PTR_WIDTH:0]		wr_rptr_gray_in_ff;
	reg		[PTR_WIDTH:0]		wr_rptr_gray_in;
	wire	[PTR_WIDTH:0]		wr_rptr_in;
	reg		[PTR_WIDTH:0]		wr_rptr;
	

	// read
	reg		[PTR_WIDTH:0]		rd_rptr;
	wire	[PTR_WIDTH:0]		rd_rptr_gray;
	reg		[PTR_WIDTH:0]		rd_rptr_gray_out_async;
	wire						rd_empty;
	
	reg		[PTR_WIDTH:0]		rd_wptr_gray_in_ff;
	reg		[PTR_WIDTH:0]		rd_wptr_gray_in;
	wire	[PTR_WIDTH:0]		rd_wptr_in;
	reg		[PTR_WIDTH:0]		rd_wptr;
	
	
	// write pointer
	binary_to_graycode
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_binary_to_graycode_wr
			(
				.binary		(wr_wptr),
				.graycode	(wr_wptr_gray)
			);
	
	graycode_to_binary
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_graycode_to_binary_wr
			(
				.graycode	(wr_rptr_gray_in),
				.binary		(wr_rptr_in)
			);
		
	always @ ( posedge in_clk or posedge reset ) begin
		if ( reset ) begin
			wr_wptr                <= 0;
			wr_wptr_gray_out_async <= 0;

			wr_rptr_gray_in_ff     <= 0;
			wr_rptr_gray_in        <= 0;
			wr_rptr                <= 0;
		end
		else begin
			// async
			wr_wptr_gray_out_async <= wr_wptr_gray;
			wr_rptr_gray_in_ff     <= rd_rptr_gray_out_async;
			wr_rptr_gray_in        <= wr_rptr_gray_in_ff;
			wr_rptr                <= wr_rptr_in;
			
			// pinter
			if ( in_en & in_ready ) begin
				wr_wptr <= wr_wptr + 1;
			end
		end
	end

	assign wr_full     = (wr_wptr[PTR_WIDTH] != wr_rptr[PTR_WIDTH]) && (wr_wptr[PTR_WIDTH-1:0] == wr_rptr[PTR_WIDTH-1:0]);
	
	assign ram_wr_en   = in_en & in_ready;
	assign ram_wr_addr = wr_wptr[PTR_WIDTH-1:0];
	assign ram_wr_data = in_data;
	
	assign in_ready    = !wr_full;
    assign in_free_num = ((wr_rptr - wr_wptr) + (1 << PTR_WIDTH));
	
		
	// read pointer
	binary_to_graycode
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_binary_to_graycode_rd
			(
				.binary		(rd_rptr),
				.graycode	(rd_rptr_gray)
			);
	
	graycode_to_binary
			#(
				.WIDTH		(PTR_WIDTH+1)
			)
		i_graycode_to_binary_rd
			(
				.graycode	(rd_wptr_gray_in),
				.binary		(rd_wptr_in)
			);
	
	reg							rd_valid;
	reg		[DATA_WIDTH:0]		rd_data;
	reg							rd_data_valid;
	always @ ( posedge out_clk or posedge reset ) begin
		if ( reset ) begin
			rd_rptr                <= 0;
			rd_rptr_gray_out_async <= 0;

			rd_wptr_gray_in_ff     <= 0;
			rd_wptr_gray_in        <= 0;
			rd_wptr                <= 0;
			
			rd_valid               <= 1'b0;
			rd_data_valid          <= 1'b0;
		end
		else begin
			// async
			rd_rptr_gray_out_async <= rd_rptr_gray;
			rd_wptr_gray_in_ff     <= wr_wptr_gray_out_async;
			rd_wptr_gray_in        <= rd_wptr_gray_in_ff;
			rd_wptr                <= rd_wptr_in;
			
			// read pointer
			if ( ~rd_empty & (out_ready | ~out_en) ) begin
				rd_rptr <= rd_rptr + 1;
			end
			
			rd_valid <= !rd_empty;
			if ( out_ready ) begin
				rd_data_valid <= 1'b0;
			end
			else begin
				if ( !rd_data_valid ) begin
					rd_data       <= ram_rd_data;
					rd_data_valid <= rd_valid;
				end
			end
		end
	end
	
	assign rd_empty     = (rd_wptr == rd_rptr);

	assign ram_rd_en    = 1'b1;	// ~rd_empty & (out_ready | ~out_en);
	assign ram_rd_addr  = rd_rptr[PTR_WIDTH-1:0];

	assign out_en       = rd_data_valid | rd_valid;
	assign out_data     = rd_data_valid ? rd_data : ram_rd_data;
	assign out_data_num = (rd_wptr - rd_rptr);
	
endmodule
