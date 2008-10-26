`timescale 1ns / 1ps


module tb_top;
	parameter	RATE      = 20;
	parameter	UART_RATE = (1000000000 / 115200);
	
	
	initial begin
		$dumpfile("tb_plasma.vcd");
		$dumpvars(0, tb_top);
	end
	
	// reset
	reg		reset;
	initial begin
		#0			reset = 1'b1;
		#(RATE*10)	reset = 1'b0;
	end
	
	// clock
	reg		clk;
	initial begin
		clk    = 1'b1;
	end
	always #(RATE/2) begin
		clk = ~clk;
	end
	
	
	
	reg			uart_rx;

	wire				sram_ce0_n;
	wire				sram_ce1_n;
	wire				sram_we_n;
	wire				sram_oe_n;
	wire	[3:0]		sram_bls_n;
	wire	[17:0]		sram_a;
	wire	[31:0]		sram_d;
	
	top i_top
		(
			.clk_in			(clk),
			.reset_in		(reset),
			
			.uart_tx		(),
			.uart_rx		(uart_rx),

			.asram_ce0_n	(sram_ce0_n),
			.asram_ce1_n	(sram_ce1_n),
			.asram_we_n		(sram_we_n),
			.asram_oe_n		(sram_oe_n),
			.asram_bls_n	(sram_bls_n),
			.asram_a		(sram_a),
			.asram_d		(sram_d)
		);
	
	sram i_sram0 (.ce_n(sram_ce0_n), .we_n(sram_we_n | sram_bls_n[0]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[7:0]));
	sram i_sram1 (.ce_n(sram_ce0_n), .we_n(sram_we_n | sram_bls_n[1]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[15:8]));
	sram i_sram2 (.ce_n(sram_ce1_n), .we_n(sram_we_n | sram_bls_n[2]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[23:16]));
	sram i_sram3 (.ce_n(sram_ce1_n), .we_n(sram_we_n | sram_bls_n[3]), .oe_n(sram_oe_n), .addr(sram_a), .data(sram_d[31:24]));
	
	
	
	initial begin
					uart_rx = 1'b1;
		#UART_RATE 	uart_rx = 1'b1;
		#UART_RATE 	uart_rx = 1'b1;
		
		#UART_RATE 	uart_rx = 1'b0;		// start
		#UART_RATE 	uart_rx = 1'b1;		// 0 : LSB
		#UART_RATE 	uart_rx = 1'b0;		// 1
		#UART_RATE 	uart_rx = 1'b1;		// 2
		#UART_RATE 	uart_rx = 1'b0;		// 3
		#UART_RATE 	uart_rx = 1'b0;		// 4
		#UART_RATE 	uart_rx = 1'b1;		// 5
		#UART_RATE 	uart_rx = 1'b1;		// 6
		#UART_RATE 	uart_rx = 1'b1;		// 7 : MSB
		#UART_RATE 	uart_rx = 1'b1;		// stop
		
		#UART_RATE 	uart_rx = 1'b1;
		#UART_RATE 	uart_rx = 1'b1;
		
		#UART_RATE 	uart_rx = 1'b0;		// start
		#UART_RATE 	uart_rx = 1'b1;		// 0 : LSB
		#UART_RATE 	uart_rx = 1'b1;		// 1
		#UART_RATE 	uart_rx = 1'b1;		// 2
		#UART_RATE 	uart_rx = 1'b1;		// 3
		#UART_RATE 	uart_rx = 1'b1;		// 4
		#UART_RATE 	uart_rx = 1'b1;		// 5
		#UART_RATE 	uart_rx = 1'b1;		// 6
		#UART_RATE 	uart_rx = 1'b1;		// 7 : MSB
		#UART_RATE 	uart_rx = 1'b1;		// stop

		#UART_RATE 	uart_rx = 1'b0;		// start
		#UART_RATE 	uart_rx = 1'b0;		// 0 : LSB
		#UART_RATE 	uart_rx = 1'b0;		// 1
		#UART_RATE 	uart_rx = 1'b0;		// 2
		#UART_RATE 	uart_rx = 1'b0;		// 3
		#UART_RATE 	uart_rx = 1'b0;		// 4
		#UART_RATE 	uart_rx = 1'b0;		// 5
		#UART_RATE 	uart_rx = 1'b0;		// 6
		#UART_RATE 	uart_rx = 1'b0;		// 7 : MSB
		#UART_RATE 	uart_rx = 1'b1;		// stop

		#UART_RATE 	uart_rx = 1'b1;
		#UART_RATE 	uart_rx = 1'b1;
		
		#UART_RATE 	uart_rx = 1'b0;		// start
		#UART_RATE 	uart_rx = 1'b0;		// 0 : LSB
		#UART_RATE 	uart_rx = 1'b1;		// 1
		#UART_RATE 	uart_rx = 1'b0;		// 2
		#UART_RATE 	uart_rx = 1'b1;		// 3
		#UART_RATE 	uart_rx = 1'b0;		// 4
		#UART_RATE 	uart_rx = 1'b1;		// 5
		#UART_RATE 	uart_rx = 1'b0;		// 6
		#UART_RATE 	uart_rx = 1'b1;		// 7 : MSB
		#UART_RATE 	uart_rx = 1'b1;		// stop

		#UART_RATE 	uart_rx = 1'b1;
		#UART_RATE 	uart_rx = 1'b1;
		
		#UART_RATE 	uart_rx = 1'b0;		// start
		#UART_RATE 	uart_rx = 1'b1;		// 0 : LSB
		#UART_RATE 	uart_rx = 1'b0;		// 1
		#UART_RATE 	uart_rx = 1'b1;		// 2
		#UART_RATE 	uart_rx = 1'b0;		// 3
		#UART_RATE 	uart_rx = 1'b1;		// 4
		#UART_RATE 	uart_rx = 1'b0;		// 5
		#UART_RATE 	uart_rx = 1'b1;		// 6
		#UART_RATE 	uart_rx = 1'b0;		// 7 : MSB		
		#UART_RATE 	uart_rx = 1'b1;		// stop
	end
	
	// PC trace
	integer	pc_trace;
	initial begin
		pc_trace = $fopen("pc_trace.txt");
	end
	always @ ( posedge i_top.i_cpu_top.i_cpu_core.clk ) begin
		if ( !i_top.i_cpu_top.i_cpu_core.ex_out_stall ) begin
			$fdisplay(pc_trace, "%t %h", $time, i_top.i_cpu_top.i_cpu_core.ex_out_pc);
		end
	end
	
	
	// UART monitor
	always @ ( posedge i_top.i_uart0.clk ) begin
		if ( i_top.i_uart0.tx_fifo_wr_en ) begin
			$display("%t UART-TX:%h %c", $time, i_top.i_uart0.tx_fifo_wr_data, i_top.i_uart0.tx_fifo_wr_data);
		end
	end

	// Interrupt monitor
	always @ ( posedge i_top.i_cpu_top.clk ) begin
		if ( i_top.i_cpu_top.interrupt_req ) begin
			$display("%t  interrupt_req",  $time);
		end
		if ( i_top.i_cpu_top.interrupt_ack ) begin
			$display("%t  interrupt_ack",  $time);
		end
	end
		
endmodule

