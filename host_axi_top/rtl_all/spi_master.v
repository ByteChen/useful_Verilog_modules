//  --==============================================================--
//  This confidential and proprietary software may be used only as
//  authorised by a licensing agreement from INNOVA-DA Limited
//    (C) COPYRIGHT 2017 INNOVA-DA Limited
//        ALL RIGHTS RESERVED
//  The entire notice above must be reproduced on all authorised
//  copies and copies may only be made to the extent permitted
//  by a licensing agreement from INNOVA-DA Limited.
//  
//  ------------------------------------------------------------------
//  Version and Release Control Information:
//  
//  File Name          : mdio.v
//  File Revision      : 1.0
//  
//  ------------------------------------------------------------------
//  Purpose            : Provides the Interface to MDIO pins.
//                       Clause 45 compatible
//  --==============================================================--

module spi_master (
	input clk,
	input reset_n,
	input start,
	output reg busy,
	input rw,
	input [1:0] port_no,
	input [4:0] dev_addr,
	input [15:0] reg_addr,
	input [31:0] data_in,
	output reg [31:0] data_out,
	output reg out_valid,	
	output sck_out,
	output sck_w,
	output reg ssn,
	input miso,
	output reg mosi
);

	parameter SCK_DIV_WIDTH =3;
	parameter SCK_DIV_VALUE = 8;
	
	reg [SCK_DIV_WIDTH-1:0] clk_cnt;
	reg clk_state;
	reg sck;
	always @ (posedge clk)
		if (~reset_n)	begin
			clk_cnt <= 'd0;
			clk_state <= 1'b0;
			sck <= 1'b0;
		end
		else	begin
			case (clk_state)
				1'b0:	if (clk_cnt == SCK_DIV_VALUE/2)	begin
					clk_cnt <= 'd0;
					sck <= 1'b1;
					clk_state <= 1'b1;
				end
				else
					clk_cnt <= clk_cnt + 1'b1;
				1'b1:	if (clk_cnt == SCK_DIV_VALUE/2)	begin
					clk_cnt <= 'd0;
					sck <= 1'b0;
					clk_state <= 1'b0;
				end
				else
					clk_cnt <= clk_cnt + 1'b1;
			endcase
		end
	
	reg sck_t;
	wire sck_rising;
	wire sck_falling; 
	always@(posedge clk)begin
		if(~reset_n)	sck_t <= 1'b0;
		else		sck_t <= sck;
	end
	assign sck_rising = ~sck_t & sck;	
	assign sck_falling = ~sck & sck_t;	
	assign sck_w = sck;
	
	reg [1:0] w_state;
	reg [55:0] temp_array; 
	reg [5:0] cnt1;
	reg  rw_reg;
	reg sck_out_en;
	reg sample_en;
	
	assign sck_out = sck & sck_out_en;
	
	always @ (posedge clk)
		if (~reset_n)	begin
			w_state <= 'd0;
			temp_array <= 56'd0;
			busy <= 1'b0;
			ssn <= 1'b1;
			mosi <= 1'b0;
			cnt1 <= 6'd0;
			rw_reg <= 1'b0;
			data_out <= 32'd0;
			out_valid <= 1'b0;
			sck_out_en <= 1'b0;
			sample_en <= 1'b0;
		end
		else	begin
			case (w_state)
				2'd0:	begin	
					if (start)	begin
						temp_array[31:0] <= data_in;
						temp_array[47:32] <= reg_addr;
						temp_array[52:48] <= dev_addr;
						temp_array[54:53] <= port_no;
						temp_array[55] = rw;
						busy <= 1'b1;
						rw_reg <= rw;
						w_state <= 2'd1;
						sck_out_en <= 1'b1;
					end
				end
				2'd1:	if (sck_falling)	begin
					ssn <= 1'b0;
					mosi <= temp_array[55];
					if (cnt1 == 55)	begin
						cnt1 <= 6'd0;
						w_state <= 2'd2;
					end
					else	begin
						temp_array <= {temp_array[54:0],1'b0};
						cnt1 <= cnt1 + 1'b1;
						if (cnt1 >= 24)	
							sample_en <= 1'b1;
					end
				end
				2'd2:	if (sck_falling)	begin
					ssn <= 1'b1;
					mosi <= 1'b0;
					sample_en <= 1'b0;
					w_state <= 2'd3;
				end
				2'd3:	if (sck_falling)	begin
					busy <= 1'b0;
					sck_out_en <= 1'b0;
					w_state <= 2'd0;
				end
			endcase
		end
		
	reg [1:0] r_state;
	always @ (posedge clk)
		if (~reset_n)	begin
			r_state <= 2'd0;
			out_valid <= 1'b0;
			data_out <= 32'd0;
		end
		else	begin
			case (r_state)
				2'd0:	if (sample_en)	begin
					r_state <= 2'd1; 
				end
				2'd1:	if (sck_rising)	begin
					if (~sample_en)
						r_state <= 2'd2;
					else
						data_out <= {data_out[30:0],miso};
				end
				2'd2:	begin
					out_valid <= 1'b1;
					r_state <= 2'd3;
				end
				2'd3:	begin
					out_valid <= 1'b0;
					r_state <= 2'd0;
				end
			endcase
		end
		
endmodule
					
					
					
					
						
						
					
						
						
					
					
					
					
			
	
	