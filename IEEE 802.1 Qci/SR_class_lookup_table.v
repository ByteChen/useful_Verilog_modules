`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: xidian U
//////////////////////////////////////////////////////////////////////////////////
module SR_class_lookup_table(
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
		          
				  input    [11:0]           gate_id_in,
		          output   reg [11:0]       gate_id_out,
                  output   [2:0]		    tdest_out
		          
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
           
    reg [11:0] ram_address=0;
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
    
    reg [11:0]           gate_id_ff1;
    reg [11:0]           gate_id_ff2;
    
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
          
          gate_id_ff1    <= 'b0;
          gate_id_ff2    <= 'b0;
          gate_id_out    <= 'b0;
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
          
          gate_id_ff1    <= gate_id_in;
          gate_id_ff2    <= gate_id_ff1;
          gate_id_out    <= gate_id_ff2;
      end
    end
    
    wire [59:0] DA_and_VID; //存储在SR_lookup_table中的目的mac地址和vid，暂时无用
	wire [7:0] tdest;
    SR_lookup_table SR_lut (    
      .clka(clk),   
      .ena(1'b0),     
      .wea(1'b0),     
      .addra(7'b0), 
      .dina(68'b0),   
      .clkb(clk),    
      .enb(1'b1),   
      .addrb(ram_address[6:0]),  
      .doutb({DA_and_VID ,tdest})  
    );
    
	//SR_lookup_table中存储的tdest预留为8位，方便将来做多播时用作比特码表。
	assign tdest_out = tdest[2:0];
    assign rx_axis_tready = tx_axis_tready;
    
endmodule                        
