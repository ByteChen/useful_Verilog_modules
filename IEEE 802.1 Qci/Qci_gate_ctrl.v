`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company : Xidian University
// Engineer: ByteChen@qq.com
//////////////////////////////////////////////////////////////////////////////////
module Qci_gate_ctrl(
    input						clk,
	input						rst_n,
	
	input                       enable_Qch,
	
	input		[63:0]			rx_axis_tdata,
	input						rx_axis_tvalid,
	input						rx_axis_tlast,
	input		[7:0]			rx_axis_tkeep,
	output						rx_axis_tready,
	
	input	 [10:0]				frame_len_in,
	input	 [11:0]				gate_id,
	
	//FULL signal from priority queue
    input                         isFull_queue0 ,
    input                         isFull_queue1 ,
    input                         isFull_queue2 ,
    input                         isFull_queue3 ,
    input                         isFull_queue4 ,
    input                         isFull_queue5 ,
    input                         isFull_queue6 ,
    input                         isFull_queue7 ,
	
	output   reg   [63:0] 		tx_axis_tdata,
	output   reg   [7:0]  		tx_axis_tkeep,
	output   reg          		tx_axis_tlast,
	output   reg          		tx_axis_tvalid,
	input                 		tx_axis_tready,
	
	output   reg   [10:0]       frame_len_out,
	output 	       [3:0 ]		tx_axis_tdest
);

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
    
    reg [2:0] tdest;
    reg ram_addr0;
    reg [15:0] interval0;
    wire [19:0] data0;
    
    reg ram_addr1;
    reg [15:0] interval1;
    wire [19:0] data1;
    
    /*
    always@(posedge clk) begin
            if(!rst_n)
                tdest <= 3'b1;
            else if(sof && gate_id[11:0] == 12'hfff)
                tdest <= 3'b0;
            //else if(sof && gate_id[0] == 1'b1)
            //    tdest <= 3'b0;
            //else if(sof && gate[gate_id[0]][0]==1'b1)
            //    tdest <= gate[gate_id[0]][3:1];
            else if(sof && gate_id[0] == 1'b0 && data0[0] == 1'b1)  //ok
                tdest <= data0[3:1];
            else if(sof && gate_id[0] == 1'b1 && data1[0] == 1'b1)  //ok
                tdest <= data1[3:1];
        end
    */
    
    //gate_id=全1时，为非Qci流，此时根据帧内的优先级分发
    /*
    reg [2:0] tdest_reg;
    reg is_qci_stream = 1'b0;
    always@(posedge clk) begin
        if(!rst_n) begin
            tdest <= 3'd1;
            is_qci_stream   <= 1'b0;
            tdest_reg   <= 3'd1;
        end
        else if(sof && gate_id[11:0] != 12'hfff && gate_id[0] == 1'b0 && data0[0] == 1'b1) begin  //ok
            tdest           <= data0[3:1];
            is_qci_stream   <= 1'b1;
            end
        else if(sof && gate_id[11:0] != 12'hfff && gate_id[0] == 1'b1 && data1[0] == 1'b1) begin  //ok
            tdest           <= data1[3:1];
            is_qci_stream   <= 1'b1;
            end
        else if(sof_reg && is_qci_stream == 1'b1) begin
            tdest_reg       <= tdest;
            is_qci_stream   <= 1'b0;
        end
        else if(sof_reg && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd0)
            tdest_reg <= 3'd0;
        else if(sof_reg && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd1)
            tdest_reg <= 3'd0;
        else if(sof_reg && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd4)
            tdest_reg <= 3'd4;   
        else if(sof_reg && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd5)
            tdest_reg <= 3'd5;     
    end
    */
    
    //增加Qch_enable
        reg [2:0] tdest_reg;
        reg is_qci_stream = 1'b0;
        always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                tdest <= 3'd1;
                is_qci_stream   <= 1'b0;
                tdest_reg   <= 3'd1;
            end
            else if(sof && gate_id[11:0] != 12'hfff && gate_id[0] == 1'b0 && data0[0] == 1'b1) begin  //gate_id末尾为0，则为A类
                tdest           <= data0[3:1];
                is_qci_stream   <= 1'b1;
                end
            else if(sof && gate_id[11:0] != 12'hfff && gate_id[0] == 1'b1 && data1[0] == 1'b1) begin  //gate_id末尾为1，则为b类
                tdest           <= data1[3:1];
                is_qci_stream   <= 1'b1;
                end
            else if(sof_reg && is_qci_stream == 1'b1) begin
                tdest_reg       <= tdest;
                is_qci_stream   <= 1'b0;
            end
			
			//优先级7和6不论是否Qch都进入5/4
            else if(sof_reg && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd7)   
                tdest_reg <= 3'd5;
            else if(sof_reg && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd6)
                tdest_reg <= 3'd4;
            
			//Qch不enable时，pri和class之间的映射
            else if(sof_reg && enable_Qch==1'b0 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd5)	
                tdest_reg <= 3'd3;
			else if(sof_reg && enable_Qch==1'b0 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd4)
                tdest_reg <= 3'd2;
			else if(sof_reg && enable_Qch==1'b0 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd0)
                tdest_reg <= 3'd1;
			else if(sof_reg && enable_Qch==1'b0 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd1)
                tdest_reg <= 3'd0;
				
			//Qch enabled时，pri和class之间映射关系
			else if(sof_reg && enable_Qch==1'b1 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd5)	
                tdest_reg <= 3'd1;
			else if(sof_reg && enable_Qch==1'b1 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd4)
                tdest_reg <= 3'd1;
			else if(sof_reg && enable_Qch==1'b1 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd0)
                tdest_reg <= 3'd0;
			else if(sof_reg && enable_Qch==1'b1 && gate_id[11:0] == 12'hfff && rx_axis_tdata[55:53] == 3'd1)
                tdest_reg <= 3'd0;
        end
		
		reg [3:0] tdest_reg_reg;
		always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                tdest_reg_reg	<= 	4'd0;
            end
			else if(sof_reg_reg)
				tdest_reg_reg	<=	tdest_reg;	//tdest_reg要不要也换成4位？？
		end
			
	
	
    reg if_target_queue_full;   //完成丢帧功能；表示目标输出队列是否满
    always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
                if_target_queue_full	<= 	1'd0;
            end
        else if(sof_reg_reg) begin
            case(tdest_reg)
                3'd0    :   if_target_queue_full    <=  isFull_queue0;
                3'd1    :   if_target_queue_full    <=  isFull_queue1;  //use as trush bin
                3'd2    :   if_target_queue_full    <=  isFull_queue2;
                3'd3    :   if_target_queue_full    <=  isFull_queue3;
                3'd4    :   if_target_queue_full    <=  isFull_queue4;
                3'd5    :   if_target_queue_full    <=  isFull_queue5;
                3'd6    :   if_target_queue_full    <=  isFull_queue6;
                3'd7    :   if_target_queue_full    <=  isFull_queue7;
            endcase
        end    
    end
    
    assign tx_axis_tdest = if_target_queue_full ? 4'd8 : tdest_reg_reg;	//暂时不判断目标队列满不满
	//assign tx_axis_tdest = tdest_reg;
	
	reg  [63:0] rx_axis_tdata_ff1;
    reg  [7:0]  rx_axis_tkeep_ff1;
    reg         rx_axis_tlast_ff1;
    reg        rx_axis_tvalid_ff1;

    reg  [63:0] rx_axis_tdata_ff2;
    reg  [7:0]  rx_axis_tkeep_ff2;
    reg         rx_axis_tlast_ff2;
    reg         rx_axis_tvalid_ff2;    

                
    always @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
              tx_axis_tdata  <= 64'b0 ;
              tx_axis_tkeep  <= 8'b0 ;
              tx_axis_tlast  <= 1'b0 ;
              tx_axis_tvalid <= 1'b0 ;
              
             rx_axis_tdata_ff1 <= 'b0;
             rx_axis_tkeep_ff1 <= 'b0;
             rx_axis_tlast_ff1 <= 'b0;
            rx_axis_tvalid_ff1 <= 'b0;
            
          rx_axis_tdata_ff2 <= 'b0;
          rx_axis_tkeep_ff2 <= 'b0;
          rx_axis_tlast_ff2 <= 'b0;
         rx_axis_tvalid_ff2 <= 'b0;
                      
          end
          else if (tx_axis_tready == 1'b1) begin
           rx_axis_tdata_ff1 <= rx_axis_tdata;                   
            rx_axis_tkeep_ff1 <= rx_axis_tkeep;                   
            rx_axis_tlast_ff1 <= rx_axis_tlast;                   
           rx_axis_tvalid_ff1 <= rx_axis_tvalid;
           
           rx_axis_tdata_ff2  <= rx_axis_tdata_ff1;
           rx_axis_tkeep_ff2  <= rx_axis_tkeep_ff1;
           rx_axis_tlast_ff2  <= rx_axis_tlast_ff1;
           rx_axis_tvalid_ff2 <= rx_axis_tvalid_ff1;
          
            tx_axis_tdata  <=  rx_axis_tdata_ff2;
            tx_axis_tkeep  <=  rx_axis_tkeep_ff2;
            tx_axis_tlast  <=  rx_axis_tlast_ff2;
            tx_axis_tvalid <= rx_axis_tvalid_ff2;
             /*      
              tx_axis_tdata <=  rx_axis_tdata_ff1;
              tx_axis_tkeep <=  rx_axis_tkeep_ff1;
              tx_axis_tlast <=  rx_axis_tlast_ff1;
             tx_axis_tvalid <= rx_axis_tvalid_ff1;*/
          end
        end
    
     reg [10:0]         frame_len_out_ff1;
	 reg [10:0]         frame_len_out_ff2;
     always @(posedge clk or negedge rst_n) begin
       if (!rst_n) begin
        frame_len_out            <= 'b0;
        frame_len_out_ff1        <= 'b0;
		frame_len_out_ff2        <= 'b0;
		
       end
       else if (tx_axis_tready == 1'b1) begin
        frame_len_out_ff1       <=  frame_len_in;
        frame_len_out_ff2       <=  frame_len_out_ff1;
		frame_len_out           <=  frame_len_out_ff2;
       end
     end
	
    
    always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                ram_addr0   <=  1'b0;
                interval0   <=  0;
            end
            else if(interval0 == 0)
                interval0   <= data0[19:4];
            else if(interval0 == 2) begin
                ram_addr0   <= ~ram_addr0;  //0 1 交替
                interval0   <= interval0 - 1;
            end
            else if(interval0 > 0)
                interval0   <= interval0 - 1;    
        end
        
    always@(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                ram_addr1   <=  1'b0;
                interval1   <=  0;
            end
            else if(interval1 == 0)
                interval1   <= data1[19:4];
            else if(interval1 == 2) begin
                ram_addr1   <= ~ram_addr1;  //0 1 交替
                interval1   <= interval1 - 1;
            end
            else if(interval1 > 0)
                interval1   <= interval1 - 1;    
        end
    
        
    assign rx_axis_tready = tx_axis_tready;

    gate_ctrl_list_73 gate_ctrl_list_73 (
      .clka(clk),      // input wire clka
      .ena(1'b0),      // input wire ena
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(1'b0),    // input wire [0 : 0] addra
      .dina(20'b0),    // input wire [19 : 0] dina
      .clkb(clk),     // input wire clkb
      .enb(1'b1),      // input wire enb
      .addrb(ram_addr0),  // input wire [0 : 0] addrb
      .doutb(data0)   // output wire [19 : 0] doutb
    );
    
    gate_ctrl_list_62 gate_ctrl_list_62 (
      .clka(clk),      // input wire clka
      .ena(1'b0),      // input wire ena
      .wea(1'b0),      // input wire [0 : 0] wea
      .addra(1'b0),    // input wire [0 : 0] addra
      .dina(20'b0),    // input wire [19 : 0] dina
      .clkb(clk),     // input wire clkb
      .enb(1'b1),      // input wire enb
      .addrb(ram_addr1),  // input wire [0 : 0] addrb
      .doutb(data1)   // output wire [19 : 0] doutb
    );
endmodule
