module debug_host (
  input clk,
  input reset_n,
  output reg [31:0] axi_addr,
  input axi_busy,
  output reg [31:0] axi_data_in,
  input [31:0] axi_data_out,
  output reg axi_rd,
  output reg axi_wr,
  output txd_out,
  input rxd_in,
  input cts_in,
  output rts_out
);
	parameter CRC_BYPASS = 1'b0;
	parameter START_FLAG = 8'had;
	parameter DEBUG_ID = 8'hff;
	parameter WR_ID = 8'h82;
	parameter RD_ID = 8'h02;
	
	reg feadback_start;
	reg [15:0] wsize;
	reg [7:0] rid;
	reg [7:0] rdata_0,rdata_1,rdata_2,rdata_3;
	reg [7:0] w_crc,r_crc;
	
	wire [7:0] tx_fifo_dout;
	reg tx_fifo_rd;
	wire tx_fifo_empty;
	reg [7:0] rx_fifo_din;
	reg rx_fifo_wr;
	wire rx_fifo_full;
	
	reg [3:0] tx_state;
	reg [3:0] tx_next_state;
	reg rx_busy;
	
	reg [15:0] cnt1;
	reg [1:0] cnt2;
	reg [15:0] data_cnt;
	
	reg [31:0] addr;
	reg [31:0] data;
	
	reg cmd_type;	//0: read; 1: write
	
	reg [1:0] rx_state;
	reg first_flag;
	reg [3:0] rx_cnt;
	reg [79:0] rx_data_w;
	
	wire [10:0] fifo_data_cnt;
	
	wire [7:0] tx_fifo_din;
	wire tx_fifo_wr;
	wire tx_fifo_full;
	wire [7:0] rx_fifo_dout;
	wire rx_fifo_rd;
	wire rx_fifo_empty;
	
	always @ (posedge clk)
		if (~reset_n)	begin
			first_flag <= 1'b1;
			rx_state <= 2'd0;
			rx_cnt <= 4'd0;
			rx_fifo_wr <= 1'b0;
		end
		else	begin
			case (rx_state)
				2'd0:	if (feadback_start | first_flag)	begin
					first_flag <= 1'b0;
					rx_data_w <= {8'had,8'h00,8'h06,8'hff,rid,rdata_0,rdata_1,rdata_2,rdata_3,r_crc};
					rx_state <= 2'd1;
				end
				2'd1:	begin
					if (~rx_fifo_full)	begin
						rx_fifo_wr <= 1'b1;
						rx_fifo_din <= rx_data_w[79:72];
						rx_cnt <= rx_cnt + 1'b1;
						rx_data_w <= {rx_data_w[71:0],8'd0};
					end
					if (rx_cnt == 4'd9)
						rx_state <= 2'd2;
				end
				2'd2:	begin
					rx_cnt <= 4'd0;
					rx_fifo_wr <= 1'b0;
					rx_state <= 2'd0;
				end
				default:
					rx_state <= 2'd2;
			endcase
		end
						
	always @ (posedge clk)
		if (~reset_n)	begin
			rid <= 0;
			rdata_0 <= 8'hff;
			rdata_1 <= 8'hff;
			rdata_2 <= 8'hff;
			rdata_3 <= 8'hff;
			r_crc <= 8'hff;
			feadback_start <= 1'b0;
			tx_fifo_rd <= 1'b0;
			cmd_type <= 1'b0;
			tx_state <= 4'd0;
			tx_next_state <= 4'd0;
			cnt2 <= 2'd0;
			data_cnt <= 16'd0;
			addr <= 32'd0;
			data <= 32'd0;
			axi_wr <= 1'b0;
			axi_rd <= 1'b0;
		end
		else	begin
			case (tx_state)
				4'd0:	begin
					cnt2 <= 2'd0;
					feadback_start <= 1'b0;	
			        addr <= 32'd0;
                    data <= 32'd0;
                    axi_wr <= 1'b0;
                    axi_rd <= 1'b0;					
//					if (~tx_fifo_empty)	begin
					if (fifo_data_cnt >= 11'd10)	begin
						tx_fifo_rd <= 1'b1;
						tx_state <= 4'd14;
						tx_next_state <= 4'd1;
					end
				end
				4'd1:	begin
					if (tx_fifo_dout != START_FLAG)	begin
						tx_state <= 4'd0;
						tx_fifo_rd <= 1'b0;
					end
					else if (~tx_fifo_empty)
						tx_state <= 4'd2;
					else	begin
						tx_next_state <= 4'd2;
						tx_state <= 4'd14;
					end
				end
				4'd2:	begin
					rid <= 0;
					rdata_0 <= 8'd0;
					rdata_1 <= 8'd0;
					rdata_2 <= 8'd0;
					rdata_3 <= 8'd0;
					cnt1[15:8] <= tx_fifo_dout;
					if (~tx_fifo_empty)
						tx_state <= 4'd3;
					else	begin
						tx_state <= 4'd14;
						tx_next_state <= 4'd3;
					end
				end
				4'd3:	begin
					cnt1[7:0] <= tx_fifo_dout;
					if (~tx_fifo_empty)
						tx_state <= 4'd4;
					else	begin
						tx_state <= 4'd14;
						tx_next_state <= 4'd4;
					end
				end
				4'd4:	begin
					data_cnt <= cnt1 - 6 ;
					w_crc = tx_fifo_dout;
					if (tx_fifo_dout != DEBUG_ID)	begin
						tx_state <= 4'd15;
						rdata_0 <= 8'd2;
						tx_fifo_rd <= 1'b0;
					end
					else if (~tx_fifo_empty)
						tx_state <= 4'd5;
					else	begin
						tx_state <= 4'd14;
						tx_next_state <= 4'd5;
					end
				end
				4'd5:	begin
					w_crc <= w_crc ^ tx_fifo_dout;
					if ((tx_fifo_dout != WR_ID) & (tx_fifo_dout != RD_ID))	begin
						tx_state <= 4'd15;
						rdata_0 <= 8'd3;
						tx_fifo_rd <= 1'b0;
					end				
					else if (tx_fifo_dout == WR_ID)	begin
						if (~tx_fifo_empty)
							tx_state <= 4'd6;
						else begin
							tx_state <= 4'd14;
							tx_next_state <= 4'd6;
						end
						cmd_type = 1'b1;
					end
					else begin
						if (~tx_fifo_empty)
							tx_state <= 4'd6;
						else begin
							tx_state <= 4'd14;
							tx_next_state <= 4'd6;
						end
						cmd_type = 1'b0;
					end 
				end
				4'd6:	begin
					w_crc <= w_crc ^ tx_fifo_dout;;
//					addr <= {addr[23:0],tx_fifo_dout[7:0]};
					addr <= {tx_fifo_dout[7:0],addr[31:8]};
					cnt2 <= cnt2 + 1'b1;
					if (cnt2 == 2'd3)	begin
						cnt2 <= 2'd0;
						if (~tx_fifo_empty)
							tx_state <= 4'd7;
						else	begin
							tx_state <= 4'd14;
							tx_next_state <= 4'd7;
						end
					end
					else	if (tx_fifo_empty)	begin
						tx_state <= 4'd14;
						tx_next_state <= 4'd6;
					end
				end
				4'd7:	begin
					if (cmd_type == 1)	begin
						if (data_cnt[1:0] != 0)	begin
							tx_state <= 4'd15;
							rdata_0 <= 8'd4;
							tx_fifo_rd <= 1'b0;
						end	
						else begin
							w_crc <= w_crc ^ tx_fifo_dout;;
//							data <= {data[23:0],tx_fifo_dout[7:0]};
							data <= {tx_fifo_dout[7:0],data[31:8]};        
							cnt2 <= cnt2 + 1'b1;
							if (cnt2 == 2'd3)	begin
								cnt2 <= 2'd0;
								tx_state <= 4'd9;
								tx_fifo_rd <= 1'b0;
							end
							else	if (tx_fifo_empty)	begin
								tx_state <= 4'd14;
								tx_next_state <= 4'd7;
							end
						end
					end
					else	begin
						if (data_cnt != 1)	begin
							tx_state <= 4'd15;
							rdata_0 <= 8'd5;
							tx_fifo_rd <= 1'b0;
						end	
						else	begin
							w_crc <= w_crc ^ tx_fifo_dout;;
							rid <= tx_fifo_dout;
							if (~tx_fifo_empty)
								tx_state <= 4'd8;
							else	begin
								tx_state <= 4'd14;
								tx_next_state <= 4'd8;
							end
						end
					end
				end
				4'd8:	begin
					tx_fifo_rd <= 1'b0;
					if ((w_crc == tx_fifo_dout)|CRC_BYPASS)
						tx_state <= 4'd12;
					else begin
						tx_state <= 4'd15;
						rdata_0 <= 8'd6;
					end
				end
				4'd9:	if (~axi_busy) begin
					axi_addr <= addr;
					axi_data_in <= data;
					axi_wr <= 1'b1;
					data_cnt <= data_cnt -4;
					tx_state <= 4'd10;
				end
				4'd10:	begin
					axi_wr <= 1'b0;
					if (~axi_busy) begin
						tx_fifo_rd <= 1'b1;
						tx_state <= 4'd14;
						addr <= addr + 4 ;
						if (data_cnt!=0)	
							tx_next_state <= 4'd7;
						else
							tx_next_state <= 4'd11;
					end
				end
				4'd11:	begin	
					tx_fifo_rd <= 1'b0;
					tx_state <= 4'd15;
					if ((w_crc == tx_fifo_dout)|CRC_BYPASS)
						rdata_0 <= 8'd0;
					else 
						rdata_0 <= 8'd7;
				end
				4'd12:	if (~axi_busy) begin
					axi_addr <= addr;
					axi_rd <= 1'b1;
					tx_state <= 4'd13;
				end
				4'd13:	begin
					axi_rd <= 1'b0;
					if (~axi_busy)	begin
						rdata_0 <= axi_data_out[7:0];
						rdata_1 <= axi_data_out[15:8];
						rdata_2 <= axi_data_out[23:16];
						rdata_3 <= axi_data_out[31:24];
						tx_state <= 4'd15;
					end
				end
				4'd14:	if (~tx_fifo_empty)
					tx_state <= tx_next_state;
				4'd15:	begin
					tx_fifo_rd <= 1'b0;
					feadback_start <= 1'b1;
					r_crc <= 8'hff ^ rid ^ rdata_0 ^ rdata_1 ^ rdata_2 ^ rdata_3;
					tx_state <= 4'd0;
				end
			endcase
		end
						
	fifo_2kx8 u_fifo_rx (
	  .clk(clk),      
	  .rst(~reset_n),      
	  .din(rx_fifo_din),      
	  .wr_en(rx_fifo_wr),  
	  .rd_en(rx_fifo_rd),  
	  .dout(rx_fifo_dout),    
	  .full(rx_fifo_full),    
	  .empty(rx_fifo_empty),
	  .data_count() 
	);	

	fifo_2kx8 u_fifo_tx (
	  .clk(clk),      
	  .rst(~reset_n),      
	  .din(tx_fifo_din),      
	  .wr_en(tx_fifo_wr),  
	  .rd_en(tx_fifo_rd),  
	  .dout(tx_fifo_dout),    
	  .full(tx_fifo_full),    
	  .empty(tx_fifo_empty),
	  .data_count(fifo_data_cnt)   
	);	
		
 uart_inf u_uart_inf(
	.clk(clk),
	.reset_n(reset_n),
	.txd_out(txd_out),
	.rxd_in(rxd_in),
	.cts_in(cts_in),
	.rts_out(rts_out),
	.tx_fifo_dout(rx_fifo_dout),
	.tx_fifo_rd(rx_fifo_rd),
	.tx_fifo_empty(rx_fifo_empty),
	.rx_fifo_din(tx_fifo_din),
	.rx_fifo_wr(tx_fifo_wr),
	.rx_fifo_full(tx_fifo_full)
);	

endmodule

					
	
module uart_inf(
	clk,
	reset_n,
	txd_out,
	rxd_in,
	cts_in,
	rts_out,
	tx_fifo_dout,
	tx_fifo_rd,
	tx_fifo_empty,
	rx_fifo_din,
	rx_fifo_wr,
	rx_fifo_full
);
	input clk;
	input reset_n;
	output txd_out;
	input rxd_in;
	input cts_in;
	output rts_out;
	input [7:0] tx_fifo_dout;
	output tx_fifo_rd;
	input tx_fifo_empty;
	output [7:0] rx_fifo_din;
	output rx_fifo_wr;
	input rx_fifo_full;

	
	wire baud_clk;
	wire baud_clk_x16;	
		
 clk_uart_gen u_clk_uart_gen(
	.clk(clk), 
	.reset_n(reset_n), 
	.baud_clk(baud_clk), 
	.baud_clk_x16(baud_clk_x16)
	);	

	reg tx_fifo_rd;
	reg [7:0] tx_data_in;
	reg tx_latch;
	wire tx_busy;
	wire tx_end;	
	reg [1:0] tx_state;
	
	always @ (posedge clk or negedge reset_n)	
		if (~reset_n)	begin
			tx_state <= 2'd0;
			tx_data_in <= 8'd0;
			tx_latch <= 1'b0;
			tx_fifo_rd <= 1'b0;
		end
		else begin
			case (tx_state)
				2'd0:	if ((~cts_in) & (~tx_fifo_empty))	begin
					tx_fifo_rd <= 1'b1;
					tx_state <= 2'd1;
				end
				2'd1:	begin
					tx_fifo_rd <= 1'b0;
					tx_state <= 2'd2;
				end
				2'd2:	if (~tx_busy)	begin
					tx_data_in <= tx_fifo_dout;
					tx_latch <= 1'b1;
					tx_state <= 2'd3;
				end
				2'd3:	begin
					tx_latch <= 1'b0;
					if (tx_end)
						tx_state <= 2'd0;
				end
				default:
					tx_state <= 2'd0;
			endcase
		end

 uart_tx u_uart_tx(
	.clk(clk),
	.reset_n(reset_n),  
	.clk_uart_tx(baud_clk), 
	.tx_data_in(tx_data_in), 
	.tx_data_latch(tx_latch), 
	.txd_out(txd_out), 
	.tx_busy(tx_busy), 
	.tx_end(tx_end)
	);

	wire [7:0] rx_data_out;
	wire rx_ready;
							
	 uart_rx u_uart_rx(
		.clk(clk), 
		.reset_n(reset_n), 
		.clk_uart_rx_x16(baud_clk_x16), 
		.rxd_in(rxd_in), 
		.rx_data_out(rx_data_out), 
		.out_ready(rx_ready)
		);					 
	
	assign rx_fifo_din = rx_data_out;
	assign rx_fifo_wr = rx_ready;
	assign rts_out = rx_fifo_full;	
			
endmodule	
	
module clk_uart_gen(
	clk, 
	reset_n, 
	baud_clk, 
	baud_clk_x16
	);
	
   input clk;
   input reset_n;
   output baud_clk; 
	 output baud_clk_x16;
	 		 
	parameter CLK_FREQUENCY = 100000000; // 40MHz
//	parameter BAUD_CLK = 115200;	//baud rate = 115200
	parameter BAUD_CLK = 921600;	//baud rate = 921600
//	parameter BAUD_CLK_ACC_WIDTH = 17; //for 115200 and 80M
//	parameter BAUD_CLK_ACC_WIDTH = 14; //for 921600 and 80M
//	parameter BAUD_CLK_ACC_WIDTH = 13; //for 921600 and 40M
	parameter BAUD_CLK_ACC_WIDTH = 14; //for 921600 and 100M
	parameter BAUD_CLK_INC =((BAUD_CLK<<(BAUD_CLK_ACC_WIDTH-4))+(CLK_FREQUENCY>>5))
						/(CLK_FREQUENCY>>4);
								
	reg [BAUD_CLK_ACC_WIDTH-4:0] baud_clkx16_acc;
	reg [BAUD_CLK_ACC_WIDTH:0] baud_clk_acc;
			
	always @ (posedge clk or negedge reset_n)
		if (!reset_n)
			baud_clkx16_acc <= 0;
		else
			baud_clkx16_acc <= baud_clkx16_acc[BAUD_CLK_ACC_WIDTH-5:0] + BAUD_CLK_INC;
			
	assign baud_clk_x16 = baud_clkx16_acc[BAUD_CLK_ACC_WIDTH-4];
	
	always @ (posedge clk or negedge reset_n)
		if (~reset_n)
			baud_clk_acc <= 'd0;
		else
			baud_clk_acc <= baud_clk_acc[BAUD_CLK_ACC_WIDTH-1:0] + BAUD_CLK_INC;
			
	assign baud_clk = baud_clk_acc[BAUD_CLK_ACC_WIDTH];
	
endmodule

module uart_tx(
	clk,
	reset_n,  
	clk_uart_tx, 
	tx_data_in, 
	tx_data_latch, 
	txd_out, 
	tx_busy, 
	tx_end
	);
  input clk;
  input clk_uart_tx;
  input [7:0] tx_data_in;
  input tx_data_latch;
	input reset_n;
  output txd_out;
  output tx_busy;
	output tx_end;
	 
	reg [3:0] state;
	reg mux_bit;
	reg [7:0] tx_data_in_reg;
	reg tx_end;
	reg tx_end_state;
	reg tx_start;	
	 
	always @(posedge clk or negedge reset_n)
		if (!reset_n)
			state<=4'b0000;			
		else	begin
			case(state)
				4'b0000: if(tx_start) state <= 4'b0011;
				4'b0011: if(clk_uart_tx) state <= 4'b0100; //wait clk_uart_tx to begin				
				4'b0100: if(clk_uart_tx) state <= 4'b1000; // start bit
				4'b1000: if(clk_uart_tx) state <= 4'b1001; // bit 0
				4'b1001: if(clk_uart_tx) state <= 4'b1010; // bit 1
				4'b1010: if(clk_uart_tx) state <= 4'b1011; // bit 2
				4'b1011: if(clk_uart_tx) state <= 4'b1100; // bit 3
				4'b1100: if(clk_uart_tx) state <= 4'b1101; // bit 4
				4'b1101: if(clk_uart_tx) state <= 4'b1110; // bit 5
				4'b1110: if(clk_uart_tx) state <= 4'b1111; // bit 6
				4'b1111: if(clk_uart_tx) state <= 4'b0001; // bit 7
				4'b0001: if(clk_uart_tx) state <= 4'b0010; // stop bit1
				4'b0010: if(clk_uart_tx) state <= 4'b0000; // stop bit2
				default: if(clk_uart_tx) state <= 4'b0000;
			endcase
		end
			
	always @(state or reset_n or tx_data_in_reg)
		if (!reset_n)	mux_bit <= 0;
		else	
			begin
				case(state[2:0])
					0: mux_bit <= tx_data_in_reg[0];
					1: mux_bit <= tx_data_in_reg[1];
					2: mux_bit <= tx_data_in_reg[2];
					3: mux_bit <= tx_data_in_reg[3];
					4: mux_bit <= tx_data_in_reg[4];
					5: mux_bit <= tx_data_in_reg[5];
					6: mux_bit <= tx_data_in_reg[6];
					7: mux_bit <= tx_data_in_reg[7];
				endcase
			end
		
	always @ (posedge clk or negedge reset_n)
		if (!reset_n)
			tx_data_in_reg<=0;
		else if (tx_data_latch)
			tx_data_in_reg<=tx_data_in;
			
	always @ (posedge clk or negedge reset_n)
		if (!reset_n)
			tx_start<=0;
		else 
			tx_start<=tx_data_latch;			
			
	always @(posedge clk or negedge reset_n) 
		if (!reset_n)
			begin
				tx_end_state<=0;
				tx_end<=0;
			end
		else 
			case (tx_end_state)
				1'b0:	if (state==4'b0010)
					begin
						tx_end<=1;
						tx_end_state<=1'b1;
					end
				1'b1:
					begin
						tx_end<=0;
						if (state==4'b0000)
							tx_end_state<=1'b0;
					end
			endcase

	assign txd_out = (state<4) | (state[3] & mux_bit); 
	assign tx_busy = state[0]|state[1]|state[2]|state[3];
	
endmodule

module uart_rx(
	clk, 
	reset_n, 
	clk_uart_rx_x16, 
	rxd_in, 
	rx_data_out, 
	out_ready
	);
	
  input clk;
  input reset_n;
  input clk_uart_rx_x16;
	input rxd_in;
  output [7:0] rx_data_out;
  output out_ready;
	 
	reg [2:0] rxd_state;
	reg rxd_bit;
	reg [3:0] state;
	reg [4:0] bit_spacing;
	reg [7:0] rx_data_out;
	reg out_ready;
	reg  out_ready_state;
	
	wire next_bit;
	reg out_en;
	reg [2:0] delay_cnt;
	
	parameter START_DELAY = 4;
	


	always @(posedge clk or negedge reset_n)
		if (!reset_n)
			rxd_bit<=1'b1;
		else if (clk_uart_rx_x16)
			rxd_bit<=rxd_in;


	always @(posedge clk or negedge reset_n)
		if (!reset_n)
			begin
				state<=4'b0000;
				out_en<=1'b0;
				delay_cnt<=3'd0;
			end
		else if (clk_uart_rx_x16)	begin
			case(state)
			  4'b0000: if(~rxd_bit) state <= 4'b0011; // start bit found
			  4'b0011: 
					begin
						if (delay_cnt<=START_DELAY)
								delay_cnt<=delay_cnt+1;
						else
							begin
								out_en<=1'b0;
								delay_cnt<=3'd0;
								state<=4'b1000;
							end
					end								
			  4'b1000: if(next_bit) state <= 4'b1001; // bit 0
			  4'b1001: if(next_bit) state <= 4'b1010; // bit 1
			  4'b1010: if(next_bit) state <= 4'b1011; // bit 2
			  4'b1011: if(next_bit) state <= 4'b1100; // bit 3
			  4'b1100: if(next_bit) state <= 4'b1101; // bit 4
			  4'b1101: if(next_bit) state <= 4'b1110; // bit 5
			  4'b1110: if(next_bit) state <= 4'b1111; // bit 6
			  4'b1111: if(next_bit) state <= 4'b0010; // bit 7
			  4'b0010: if(next_bit)	begin						// stop bit						
					state <= 4'b0000; 	
					if (rxd_bit)	out_en<=1'b1;
					else	out_en<=1'b0;
				end
			  default: state <= 4'b0000;
			endcase
		end

	always @(posedge clk)
		if(state==4'd0)
		  bit_spacing <= 5'd0;
		else if(clk_uart_rx_x16)
			bit_spacing <= bit_spacing[3:0] + 1;
			  
	assign next_bit = bit_spacing[4];
	
	always @(posedge clk or negedge reset_n) 
		if (!reset_n)
			rx_data_out<=8'd0;
		else if(clk_uart_rx_x16 && next_bit && state[3]) 
			rx_data_out <= {rxd_bit, rx_data_out[7:1]}; 
			
	always @(posedge clk or negedge reset_n) 
		if (!reset_n)
			begin
				out_ready_state<=1'b0;
				out_ready<=1'b0;
			end
		else begin
			case (out_ready_state)
				1'b0:	if (out_en)
					begin
						out_ready<=1'b1;
						out_ready_state<=1'b1;
					end
				1'b1:
					begin
						out_ready<=1'b0;
						if (!out_en)
							out_ready_state<=1'b0;
					end
			endcase
		end

endmodule
