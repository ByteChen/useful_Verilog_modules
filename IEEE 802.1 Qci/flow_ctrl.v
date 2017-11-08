`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Xidian University
// Engineer: ByteChen@qq.com
// Description: This module finishes Frame length filtering and Token-bucket flow control.
//              Frames that longer than the max_frame_len_in will be discarded;
//              Also, when there is no tokens in the bucket, the frame will be droped too.
//////////////////////////////////////////////////////////////////////////////////
module flow_ctrl(
	input						clk,
	input						rst,
	
	input		[63:0]			rx_axis_tdata,
	input						rx_axis_tvalid,
	input						rx_axis_tlast,
	input		[7:0]			rx_axis_tkeep,
	output						rx_axis_tready,
	
	input	 [11:0]				meter_id_in,
	input	 [10:0]				frame_len_in,
	input	 [10:0]				max_frame_len_in,
	input	 [31:0]				reserved_bandwidth_in,
	input	 [11:0]				gate_id_in,
	
	output	 reg [11:0]			gate_id_out,
	output   reg [10:0]         frame_len_out,

	output   reg   [63:0] 		tx_axis_tdata,
	output   reg   [7:0]  		tx_axis_tkeep,
	output   reg          		tx_axis_tlast,
	output   reg          		tx_axis_tvalid,
	input                 		tx_axis_tready
);
  //128位
	parameter [15:0] MAX_TOKEN = 16'h1DBA; 		   //max_vlam_length_1522 * 5 = 7610,换成16进制为 1DBA
	parameter [31:0] MAX_CURRENT_TOKEN = 32'h1DBA0000;
	reg [31:0] current_token [127:0] = {MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN, MAX_CURRENT_TOKEN};      //当前桶容量，整数部分16位，小数部分16位
	
	reg [31:0] token_increment [127:0];    //桶的增量，整数部分16位，小数部分16位
	//reg  first_arrival [127:0] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};  //考虑复位时如何行动？
        
	wire sof;
	wire eof;
	wire rx_axis_tvalid_detected;
	reg  rx_axis_tlast_reg = 0;
    reg  rx_axis_tvalid_prev = 0;
       
	assign sof                       = ((rx_axis_tlast_reg && rx_axis_tvalid) || rx_axis_tvalid_detected);
    assign rx_axis_tvalid_detected   = (!rx_axis_tvalid_prev && rx_axis_tvalid && !rx_axis_tlast);
    
    always @(posedge clk)
    begin
       if (rx_axis_tlast)
          rx_axis_tlast_reg <= 1;
       else
          rx_axis_tlast_reg <= 0;
    end
    
    always @(posedge clk)
       begin
          rx_axis_tvalid_prev <= rx_axis_tvalid;
       end
       
    assign eof = rx_axis_tvalid & rx_axis_tlast;    //只要帧不拖着长last应该没问题
    reg eof_reg;
    always @(posedge clk)
           begin
              eof_reg <= eof;
           end
    
    reg eof_reg_reg;
    always @(posedge clk)
          begin
             eof_reg_reg <= eof_reg;
          end
                             
    reg sof_reg;
    always @(posedge clk)
             sof_reg <= sof;
          
    reg sof_reg_reg;
    always @(posedge clk)
           sof_reg_reg <= sof_reg;

	reg transmit_permit = 1'b0;
	always@(posedge clk or posedge rst)
    		if	(rst)
				transmit_permit	<= 1'b0;
			//else if(sof_reg && frame_len_in[10:0] <= max_frame_len_in[10:0] && current_token[meter_id_in[6:0]][31:16] >= frame_len_in + 24) //consider phy layer trade-off
			else if(sof && frame_len_in[10:0] <= max_frame_len_in[10:0] && current_token[meter_id_in[6:0]][31:16] >= frame_len_in + 24)
				transmit_permit	<= 1'b1;
			else if(eof_reg)
				transmit_permit	<= 1'b0;

    
    always@(posedge clk)
            if(sof)
                token_increment[meter_id_in[6:0]]    <= reserved_bandwidth_in;
														
	reg  [63:0] rx_axis_tdata_ff1;
    reg  [7:0]  rx_axis_tkeep_ff1;
    reg         rx_axis_tlast_ff1;
    reg        rx_axis_tvalid_ff1;
/*
    reg  [63:0] rx_axis_tdata_ff2;
    reg  [7:0]  rx_axis_tkeep_ff2;
    reg         rx_axis_tlast_ff2;
    reg         rx_axis_tvalid_ff2;    
*/
                
	always @(posedge clk or posedge rst) begin
          if (rst) begin
              tx_axis_tdata  <= 64'b0 ;
              tx_axis_tkeep  <= 8'b0 ;
              tx_axis_tlast  <= 1'b0 ;
              tx_axis_tvalid <= 1'b0 ;
              
             rx_axis_tdata_ff1 <= 'b0;
             rx_axis_tkeep_ff1 <= 'b0;
             rx_axis_tlast_ff1 <= 'b0;
            rx_axis_tvalid_ff1 <= 'b0;
         /*   
          rx_axis_tdata_ff2 <= 'b0;
          rx_axis_tkeep_ff2 <= 'b0;
          rx_axis_tlast_ff2 <= 'b0;
          rx_axis_tvalid_ff2 <= 'b0;*/
                      
          end
          else if (tx_axis_tready == 1'b1) begin
            rx_axis_tdata_ff1 <= rx_axis_tdata;                   
            rx_axis_tkeep_ff1 <= rx_axis_tkeep;                   
            rx_axis_tlast_ff1 <= rx_axis_tlast;                   
           rx_axis_tvalid_ff1 <= rx_axis_tvalid;
           /*
           rx_axis_tdata_ff2  <= rx_axis_tdata_ff1;
           rx_axis_tkeep_ff2  <= rx_axis_tkeep_ff1;
           rx_axis_tlast_ff2  <= rx_axis_tlast_ff1;
           rx_axis_tvalid_ff2 <= rx_axis_tvalid_ff1;
          
              tx_axis_tdata <=  rx_axis_tdata_ff2;
              tx_axis_tkeep <=  rx_axis_tkeep_ff2;
              tx_axis_tlast <=  rx_axis_tlast_ff2;
             tx_axis_tvalid <= rx_axis_tvalid_ff2 & transmit_permit;*/
			
              tx_axis_tdata <=  rx_axis_tdata_ff1;
              tx_axis_tkeep <=  rx_axis_tkeep_ff1;
              tx_axis_tlast <=  rx_axis_tlast_ff1;
             tx_axis_tvalid <= rx_axis_tvalid_ff1 & transmit_permit;
          end
        end
    
     reg [11:0]         gate_id_out_ff1;
     reg [10:0]         frame_len_out_ff1;
     
     //reg [11:0]         gate_id_out_ff2;
     //reg [10:0]         frame_len_out_ff2;
     
     always @(posedge clk or posedge rst) begin
       if (rst) begin
       gate_id_out              <= 'b0;
       frame_len_out            <= 'b0;
       
        gate_id_out_ff1         <= 'b0;
        frame_len_out_ff1       <= 'b0;
        
        //gate_id_out_ff2         <= 'b0;
        //frame_len_out_ff2       <= 'b0;
         
       end
       else if (tx_axis_tready == 1'b1) begin
        gate_id_out_ff1         <= gate_id_in;
		gate_id_out         	<= gate_id_out_ff1; 
		
        frame_len_out_ff1       <= frame_len_in;
        frame_len_out       <= frame_len_out_ff1;
        
       end
     end
        
    assign rx_axis_tready = tx_axis_tready;
    /* 			
	always@(posedge clk or posedge rst)
    		if	(rst) begin
				current_token[0]	<= {MAX_TOKEN, 16'b0};    
				first_arrival[0]    <=  1'b1;
			  end
		    else if(sof && meter_id_in == 0 && first_arrival[0] == 1'b1)
		      begin
		        current_token[0]  <=  {MAX_TOKEN, 16'b0};
		        first_arrival[0]  <=  1'b0;
		      end
			else if(sof_reg_reg && transmit_permit && meter_id_in == 0)
				current_token[0][31:16]	<= current_token[0][31:16] - frame_len_in - 24;
			else if(current_token[0][31:16] < MAX_TOKEN)
				current_token[0]	<= current_token[0]	+ token_increment[0];
			else if(current_token[0][31:16] >= MAX_TOKEN)
			    current_token[0]	<= {MAX_TOKEN, 16'b0};

	always@(posedge clk or posedge rst)
    		if	(rst) begin
				current_token[1]	<=   'd0;    
				first_arrival[1]    <=  1'b1;
			  end
		    else if(sof && meter_id_in == 1  && first_arrival[1] == 1'b1)
		      begin
		        current_token[1]  <=  {MAX_TOKEN, 16'b0};
		        first_arrival[1]  <=  1'b0;
		      end
			else if(sof_reg_reg && transmit_permit && meter_id_in == 1)
				current_token[1][31:16]	<= current_token[1][31:16] - frame_len_in - 24;
			else if(current_token[1][31:16] < MAX_TOKEN)
				current_token[1]	<= current_token[1]	+ token_increment[1];
			else if(current_token[1][31:16] >= MAX_TOKEN)
                current_token[1]    <= {MAX_TOKEN, 16'b0};
	*/
	
	always@(posedge clk or posedge rst)
    		if	(rst) begin
				current_token[0]	<=  {MAX_TOKEN, 16'b0}; 
			  end
			else if(sof_reg && transmit_permit && meter_id_in == 0)
				current_token[0][31:16]	<= current_token[0][31:16] - frame_len_in - 24;
			else if(current_token[0][31:16] < MAX_TOKEN)
				current_token[0]	<= current_token[0]	+ token_increment[0];
				
	always@(posedge clk or posedge rst)
    		if	(rst) begin
				current_token[1]	<=  {MAX_TOKEN, 16'b0}; 
			  end
			else if(sof_reg && transmit_permit && meter_id_in == 1)
				current_token[1][31:16]	<= current_token[1][31:16] - frame_len_in - 24;
			else if(current_token[1][31:16] < MAX_TOKEN)
				current_token[1]	<= current_token[1]	+ token_increment[1];
	
	always@(posedge clk or posedge rst)
    		if	(rst) begin
				current_token[2]	<=  {MAX_TOKEN, 16'b0}; 
			  end
		    /*else if(sof && meter_id_in == 1  && first_arrival[1] == 1'b1)
		      begin
		        current_token[1]  <=  {MAX_TOKEN, 16'b0};
		        first_arrival[1]  <=  1'b0;
		      end*/
			else if(sof_reg && transmit_permit && meter_id_in == 2)
				current_token[2][31:16]	<= current_token[2][31:16] - frame_len_in - 24;
			else if(current_token[2][31:16] < MAX_TOKEN)
				current_token[2]	<= current_token[2]	+ token_increment[2];
			/*else if(current_token[2][31:16] >= MAX_TOKEN)
                current_token[2]    <= {MAX_TOKEN, 16'b0};*/
endmodule
