// ---------------------------------------------------------------------------
//  Jelly  -- the soft-core processor system
//    UART
//
//                                  Copyright (C) 2008-2009 by Ryuji Fuchikami
//                                      http://homepage3.nifty.com/ryuz
// ---------------------------------------------------------------------------



`timescale 1ns / 1ps



// UART debuger interface
module jelly_uart_debugger
		#(
			parameter					TX_FIFO_PTR_WIDTH = 10,
			parameter					RX_FIFO_PTR_WIDTH = 10
		)
		(
			// system
			input	wire				reset,
			input	wire				clk,
			input	wire				endian,
			
			// uart
			input	wire				uart_clk,
			output	wire				uart_tx,
			input	wire				uart_rx,
			
			// debug port (whishbone)
			output	wire	[3:0]		wb_adr_o,
			input	wire	[31:0]		wb_dat_i,
			output	wire	[31:0]		wb_dat_o,
			output	wire				wb_we_o,
			output	wire	[3:0]		wb_sel_o,
			output	wire				wb_stb_o,
			input	wire				wb_ack_i
		);
	
	
	wire			uart_tx_en;
	wire	[7:0]	uart_tx_data;
	wire			uart_tx_ready;
					   
	wire			uart_rx_en;
	wire	[7:0]	uart_rx_data;
	wire			uart_rx_ready;
	
	
	// UART core
	jelly_uart_core
			#(
				.TX_FIFO_PTR_WIDTH	(TX_FIFO_PTR_WIDTH),
				.RX_FIFO_PTR_WIDTH	(RX_FIFO_PTR_WIDTH)
			)
		i_uart_core
			(
				.reset				(reset),
				.clk				(clk),
				
				.uart_clk			(uart_clk),
				.uart_tx			(uart_tx),
				.uart_rx			(uart_rx),
				
				.tx_en				(uart_tx_en),
				.tx_data			(uart_tx_data),
				.tx_ready			(uart_tx_ready),
				
				.rx_en				(uart_rx_en),
				.rx_data			(uart_rx_data),
				.rx_ready			(uart_rx_ready),
				
				.tx_fifo_free_num	(),
				.rx_fifo_data_num	()
			);


	// debug comm
	jelly_cpu_dbg_comm
		i_cpu_dbg_comm
			(
				.reset				(reset),
				.clk				(clk),
				.endian				(endian),
				
				.comm_tx_en			(uart_tx_en),
				.comm_tx_data		(uart_tx_data),
				.comm_tx_ready		(uart_tx_ready),
				.comm_rx_en			(uart_rx_en),
				.comm_rx_data		(uart_rx_data),
				.comm_rx_ready		(uart_rx_ready),
				
				.wb_dbg_adr_o		(wb_adr_o),
				.wb_dbg_dat_i		(wb_dat_i),
				.wb_dbg_dat_o		(wb_dat_o),
				.wb_dbg_we_o		(wb_we_o),
				.wb_dbg_sel_o		(wb_sel_o),
				.wb_dbg_stb_o		(wb_stb_o),
				.wb_dbg_ack_i		(wb_ack_i)
			);

endmodule

