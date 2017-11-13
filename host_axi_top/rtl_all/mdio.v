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

module mdio (
	input clk,
	input reset_n,
	input start,
	output reg busy,
	input [1:0] op,
	input [4:0] phy_addr,
	input [4:0] dev_type,
	input [15:0] data_in,
	(* mark_debug = "true" *) output reg [15:0] data_out,
	(* mark_debug = "true" *) output reg out_valid,	
	output mclk_out,
	output mclk_w,
	input i_mdio,
	output reg o_mdio,
	output reg oen_mdio
);

	parameter ST = 2'b00;
	parameter TA = 2'b10;
	parameter PRE_BITS = 32;
	parameter MCLK_DIV_WIDTH =8;
	parameter MCLK_DIV_VALUE = 50;
	
	reg [MCLK_DIV_WIDTH-1:0] clk_cnt;
	reg clk_state;
	reg mclk;
	always @ (posedge clk)
		if (~reset_n)	begin
			clk_cnt <= 'd0;
			clk_state <= 1'b0;
			mclk <= 1'b0;
		end
		else	begin
			case (clk_state)
				1'b0:	if (clk_cnt == MCLK_DIV_VALUE/2)	begin
					clk_cnt <= 'd0;
					mclk <= 1'b1;
					clk_state <= 1'b1;
				end
				else
					clk_cnt <= clk_cnt + 1'b1;
				1'b1:	if (clk_cnt == MCLK_DIV_VALUE/2)	begin
					clk_cnt <= 'd0;
					mclk <= 1'b0;
					clk_state <= 1'b0;
				end
				else
					clk_cnt <= clk_cnt + 1'b1;
			endcase
		end
	
	reg mclk_t;
	wire mclk_rising;
	wire mclk_falling; 
	always@(posedge clk)begin
		if(~reset_n)	mclk_t <= 1'b0;
		else		mclk_t <= mclk;
	end
	assign mclk_rising = ~mclk_t & mclk;	
	assign mclk_falling = ~mclk & mclk_t;	
	assign mclk_w = mclk;
	
	(* mark_debug = "true" *) reg [2:0] state;
	reg [31:0] temp_array; 
	(* mark_debug = "true" *) reg [5:0] cnt1;
	reg [1:0] op_reg;
	reg mclk_out_en;
	assign mclk_out = mclk | mclk_out_en;
	
	always @ (posedge clk)
		if (~reset_n)	begin
			state <= 'd0;
			temp_array <= 32'h00000000;
			busy <= 1'b0;
			o_mdio <= 1'b1;
			oen_mdio <= 1'b1;
			cnt1 <= 6'd0;
			data_out <= 16'd0;
			out_valid <= 1'b0;
			mclk_out_en <= 1'b1;
		end
		else	begin
			case (state)
				3'd0:	begin	
					if (start)	begin
						temp_array[15:0] <= data_in;
						temp_array[17:16] <= TA;
						temp_array[22:18] <= dev_type;
						temp_array[27:23] <= phy_addr;
						temp_array[29:28] = op;
						temp_array[31:30] = ST;
						busy <= 1'b1;
						op_reg <= op;
						state <= 3'd1;
						mclk_out_en <= 1'b0;
					end
				end
				3'd1:	if (mclk_falling)	begin
					o_mdio <= 1'b1;
					oen_mdio <= 1'b0;
					if (cnt1 == PRE_BITS-1)	begin
						cnt1 <= 6'd0;
						if (op_reg[1])
							state <= 3'd3;
						else
							state <= 3'd2;
					end
					else	
						cnt1 <= cnt1 + 1'b1;
				end
				3'd2:	if (mclk_falling)	begin
					if (cnt1[5])	begin
						cnt1 <= 6'd0;
						o_mdio <= 1'b1;
						oen_mdio <= 1'b1;
						state <= 3'd6;
					end
					else	begin
						o_mdio <= temp_array[31];
						temp_array <= {temp_array[30:0],1'b0};
						cnt1 <= cnt1[4:0] + 1'b1;
					end
				end
				3'd3:	if (mclk_falling)	begin
					if (cnt1==6'd14)	begin
						cnt1 <= 6'd0;
						o_mdio <= 1'b1;
						oen_mdio <= 1'b1;
						state <= 3'd4;
					end
					else	begin
						o_mdio <= temp_array[31];
						temp_array <= {temp_array[30:0],1'b0};
						cnt1 <= cnt1 + 1'b1;
					end
				end
				3'd4:	if (mclk_falling) begin
				    if (cnt1 == 1)  begin
					   state <= 3'd5;
					   cnt1 <= 'd0;
					end
					else
					   cnt1 <= cnt1 + 1'b1;
		        end
				3'd5:	if (mclk_rising)	begin
				    data_out <= {data_out[14:0],i_mdio};
					if (cnt1 == 15)	begin
	                    cnt1 <= 'd0;
						out_valid <= 1'b1;
						mclk_out_en <= 1'b1;
						state <= 3'd7;
					end
					else	begin
						cnt1 <= cnt1 + 1'b1;
					end
				end
				3'd6:   if (mclk_rising)	begin
					mclk_out_en <= 1'b1;
                    state <= 3'd7;
                end				    				
				3'd7:	begin
					out_valid <= 1'b0;
					busy <= 1'b0;
					state <= 3'd0;
				end
				default: begin
                    out_valid <= 1'b0;
                    busy <= 1'b0;
                    state <= 3'd0;
                end
			endcase
		end
		
endmodule
					
					
					
					
						
						
					
						
						
					
					
					
					
			
	
	