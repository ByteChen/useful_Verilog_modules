`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: xidian U
// Engineer: ByteChen
// Create Date: 2017/10/21 10:53:00
// Module Name: Qci_table
//////////////////////////////////////////////////////////////////////////////////
module Qci_lookup_table(
                  input              clk,
		          input              rst,
		          
	              input       [63:0] rx_axis_tdata,
		          input       [7:0]  rx_axis_tkeep,
		          input              rx_axis_tlast,
		          input              rx_axis_tvalid,
		          output             rx_axis_tready,
		          
		          output   reg   [63:0] tx_axis_tdata,
		          output   reg   [7:0]  tx_axis_tkeep,
		          output   reg          tx_axis_tlast,
		          output   reg          tx_axis_tvalid,
		          input                 tx_axis_tready,
		          
		          input    [10:0]           frame_len_in,
		          output   reg [10:0]       frame_len_out,
		          
		          output   [11:0]			meter_id_out,
		          output   [11:0]           gate_id_out,
                  output   [10:0]           max_frame_len_out
                    //output   [31:0]           increment,
                    //output   [11:0]           bucket_capacity,
                    
                    //output   [2 :0]           tdest
		          
                        );

        wire sof;
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
           
    reg [11:0] ram_address;
    always @(posedge clk or posedge rst) begin
      if (rst) 
        ram_address          <=     12'b0;
      else if (sof) begin
        ram_address          <=     rx_axis_tdata[11:0]; 
        end
    end
    
    reg  [63:0] rx_axis_tdata_ff1;
    reg  [7:0]  rx_axis_tkeep_ff1;
    reg         rx_axis_tlast_ff1;
    reg         rx_axis_tvalid_ff1;
    
    //reg          cam_lookup_err;
    reg  [63:0] rx_axis_tdata_ff2;
    reg  [7:0]  rx_axis_tkeep_ff2;
    reg         rx_axis_tlast_ff2;
    reg         rx_axis_tvalid_ff2;
    
    reg  [63:0] rx_axis_tdata_ff3;
    reg  [7:0]  rx_axis_tkeep_ff3;
    reg         rx_axis_tlast_ff3;
    reg         rx_axis_tvalid_ff3;
    
    reg [10:0]           frame_len_ff1;
    reg [10:0]           frame_len_ff2;
    reg [10:0]           frame_len_ff3;
    
    always @(posedge clk or negedge rst) begin
      if (rst) begin
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
          
          frame_len_out  <= 'b0;
          frame_len_ff1  <= 'b0;
          frame_len_ff2  <= 'b0;
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
          
          tx_axis_tdata  <= rx_axis_tdata_ff2;
          tx_axis_tkeep  <= rx_axis_tkeep_ff2;
          tx_axis_tlast  <= rx_axis_tlast_ff2;
          tx_axis_tvalid <= rx_axis_tvalid_ff2;
          
          frame_len_ff1  <= frame_len_in;
          frame_len_ff2  <= frame_len_ff1;
          frame_len_out  <= frame_len_ff2;
      end
    end
    
    wire [59:0] DA_and_VID;
    Qci_table qcitable (    //考虑是否加复位信号
      .clka(clk),   
      .ena(1'b0),     
      .wea(1'b0),     
      .addra(7'b0), 
      .dina(95'b0),   
      .clkb(clk),    
      .enb(1'b1),   
      .addrb(ram_address[6:0]),  // 深度128时7位宽，4096时12位宽
      .doutb({DA_and_VID, max_frame_len_out,gate_id_out,meter_id_out})  
    );
    
    assign rx_axis_tready = tx_axis_tready;
    
endmodule                        