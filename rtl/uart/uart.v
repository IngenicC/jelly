`timescale 1ns / 1ps


module uart
		(
			reset, clk,
			
			uart_clk, uart_tx, uart_rx,
			
			wb_adr_i, wb_dat_o, wb_dat_i, wb_we_i, wb_sel_i, wb_stb_i, wb_ack_o
		);
	
	parameter	WB_ADR_WIDTH  = 2;
	parameter	WB_DAT_WIDTH  = 32;
	localparam	WB_SEL_WIDTH  = (WB_DAT_WIDTH / 8);
	
	input						clk;
	input						reset;
	
	// UART
	input						uart_clk;
	output						uart_tx;
	input						uart_rx;
	
	// control
	input	[WB_ADR_WIDTH-1:0]	wb_adr_i;
	output	[WB_DAT_WIDTH-1:0]	wb_dat_o;
	input	[WB_DAT_WIDTH-1:0]	wb_dat_i;
	input						wb_we_i;
	input	[WB_SEL_WIDTH-1:0]	wb_sel_i;
	input						wb_stb_i;
	output						wb_ack_o;
	

	// -------------------------
	//  clock divider
	// -------------------------

	reg							uart_clk_dv;
	reg		[7:0]				dv_counter;
	always @ ( posedge uart_clk or posedge reset ) begin
		if ( reset ) begin
			dv_counter  <= 0;
			uart_clk_dv <= 1'b0;
		end
		else begin
			if ( dv_counter == (81 - 1) ) begin		// 38400 bps (50MHz)
				dv_counter  <= 0;
				uart_clk_dv <= ~uart_clk_dv;
			end
			else begin
				dv_counter  <= dv_counter + 1;
			end
		end
	end


	// -------------------------
	//  FIFO
	// -------------------------
	
	// TX
	wire						tx_fifo_wr_en;
	wire	[7:0]				tx_fifo_wr_data;
	wire						tx_fifo_wr_ready;
	
	wire						tx_fifo_rd_en;
	wire	[7:0]				tx_fifo_rd_data;
	wire						tx_fifo_rd_ready;
	
	pipeline_fifo_async
			#(
				.DATA_WIDTH		(8),
				.PTR_WIDTH		(11)
			)
		i_fifo_tx
			(
				.reset		(reset),

				.in_clk		(clk),
				.in_en		(tx_fifo_wr_en),
				.in_data	(tx_fifo_wr_data),
				.in_ready	(tx_fifo_wr_ready),
				
				.out_clk	(uart_clk_dv),
				.out_en		(tx_fifo_rd_en),
				.out_data	(tx_fifo_rd_data),
				.out_ready	(tx_fifo_rd_ready)
			);
	
	// RX
	wire						rx_fifo_wr_en;
	wire	[7:0]				rx_fifo_wr_data;
	wire						rx_fifo_wr_ready;
	
	wire						rx_fifo_rd_en;
	wire	[7:0]				rx_fifo_rd_data;
	wire						rx_fifo_rd_ready;

	pipeline_fifo_async
			#(
				.DATA_WIDTH		(8),
				.PTR_WIDTH		(4)
			)
		i_fifo_rx
			(
				.reset		(reset),

				.in_clk		(uart_clk_dv),
				.in_en		(rx_fifo_wr_en),
				.in_data	(rx_fifo_wr_data),
				.in_ready	(rx_fifo_wr_ready),
				
				.out_clk	(clk),
				.out_en		(rx_fifo_rd_en),
				.out_data	(rx_fifo_rd_data),
				.out_ready	(rx_fifo_rd_ready)
			);
	
	
	// -------------------------
	//  TX & RX
	// -------------------------

	// TX
	uart_tx
		i_uart_tx
			(
				.reset			(reset),
				.clk			(uart_clk_dv),
				
				.uart_tx		(uart_tx),
				
				.tx_en			(tx_fifo_rd_en),
				.tx_din			(tx_fifo_rd_data), 
				.tx_ready		(tx_fifo_rd_ready)
			);
	
	uart_rx
		i_uart_rx
			(
				.reset			(reset), 
				.clk			(uart_clk_dv),
				
				.uart_rx		(uart_rx),
				
				.rx_en			(rx_fifo_wr_en),
				.rx_dout		(rx_fifo_wr_data)
			);
	
	
	// -------------------------
	//  register
	// -------------------------
	
	// TX
	assign tx_fifo_wr_en    = wb_stb_i & wb_we_i & (wb_adr_i == 0);
	assign tx_fifo_wr_data  = wb_dat_i[7:0];
	
	// RX
	assign rx_fifo_rd_ready = wb_stb_i & !wb_we_i & (wb_adr_i == 0);
	
	
	assign wb_dat_o = (wb_stb_i && (wb_adr_i == 0)) ? rx_fifo_rd_data                   : 32'h00000000
					| (wb_stb_i && (wb_adr_i == 1)) ? {tx_fifo_wr_ready, rx_fifo_rd_en} : 32'h00000000;
	assign wb_ack_o = 1'b1;
	
	
	
endmodule

