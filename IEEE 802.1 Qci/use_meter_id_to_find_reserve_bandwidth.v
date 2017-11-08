`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: xidian U
//////////////////////////////////////////////////////////////////////////////////

module use_meter_id_to_find_reserve_bandwidth(
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
		          
		          input    [11:0]			meter_id_in,
                  input    [11:0]           gate_id_in,
                  input    [10:0]           max_frame_len_in,
                                    
		          output   reg [11:0]			meter_id_out,
		          output   reg [11:0]           gate_id_out,
                  output   reg [10:0]           max_frame_len_out,
                  
                  output   [31:0]               reserved_bandwidth_out
		          
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
           
    reg [11:0] ram_address;
    always @(posedge clk or posedge rst) begin
      if (rst) 
        ram_address          <=     12'b0;
      else if (sof) begin
        ram_address          <=     meter_id_in; 
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
    
    reg [10:0]           frame_len_ff1;
    reg [10:0]           frame_len_ff2;
	
	reg [11:0]           meter_id_ff1;
    reg [11:0]           meter_id_ff2;
	
	reg [11:0]           gate_id_ff1;
    reg [11:0]           gate_id_ff2;
    
	reg [10:0]           max_frame_len_ff1;
    reg [10:0]           max_frame_len_ff2;
	
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
		  
          meter_id_ff1  <= 'b0;
          meter_id_ff2  <= 'b0;
		  
          gate_id_ff1  <= 'b0;
          gate_id_ff2  <= 'b0;
		  
          max_frame_len_ff1  <= 'b0;
          max_frame_len_ff2  <= 'b0;
		  
		  meter_id_out       <= 'b0;
		  gate_id_out        <= 'b0;
		  max_frame_len_out  <= 'b0;
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
		  
		  meter_id_ff1  <= meter_id_in;
          meter_id_ff2  <= meter_id_ff1;
          meter_id_out  <= meter_id_ff2;
		  
		  gate_id_ff1  <= gate_id_in;
          gate_id_ff2  <= gate_id_ff1;
          gate_id_out  <= gate_id_ff2;
		  
		  max_frame_len_ff1  <= max_frame_len_in;
          max_frame_len_ff2  <= max_frame_len_ff1;
          max_frame_len_out  <= max_frame_len_ff2;
      end
    end
    
    Qci_reserved_bandwidth_table bandwidth_lookup (    //考虑是否加复位信号
      .clka(clk),   
      .ena(1'b0),     
      .wea(1'b0),     
      .addra(7'b0), 
      .dina(32'b0),   
      .clkb(clk),    
      .enb(1'b1),   
      .addrb(ram_address[6:0]),  // 深度128时7位宽，4096时12位宽
      .doutb(reserved_bandwidth_out)  
    );
    
    assign rx_axis_tready = tx_axis_tready;
    
endmodule                        
