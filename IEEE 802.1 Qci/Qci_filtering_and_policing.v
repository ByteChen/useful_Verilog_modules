`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//////////////////////////////////////////////////////////////////////////////////


module Qci_filtering_and_policing(
	input              	  clk,
	input              	  rst,
		                  
	input       [63:0] 	  rx_axis_tdata,
	input       [7:0]  	  rx_axis_tkeep,
	input              	  rx_axis_tlast,
	input              	  rx_axis_tvalid,
	output             	  rx_axis_tready,
	
	output   	   [63:0] tx_axis_tdata,
	output   	   [7:0]  tx_axis_tkeep,
	output   	          tx_axis_tlast,
	output   	          tx_axis_tvalid,
	input    	          tx_axis_tready,
		
	input    	 [10:0]   frame_len_in,
	output   	 [10:0]   frame_len_out,
		
	output   	 [11:0]   gate_id_out,
    output   	 [2:0]	  tx_axis_tdest
    );
	
	(* mark_debug="true" *) wire [63:0] table_to_bandwidth_tdata ;
    (* mark_debug="true" *) wire [7:0]  table_to_bandwidth_tkeep ;
    (* mark_debug="true" *) wire        table_to_bandwidth_tvalid;
    (* mark_debug="true" *) wire        table_to_bandwidth_tlast ;
    (* mark_debug="true" *) wire        table_to_bandwidth_tready;
    
    (* mark_debug="true" *) wire [63:0] bandwidth_to_ctrl_tdata ;
    (* mark_debug="true" *) wire [7:0]  bandwidth_to_ctrl_tkeep ;
    (* mark_debug="true" *) wire        bandwidth_to_ctrl_tvalid;
    (* mark_debug="true" *) wire        bandwidth_to_ctrl_tlast ;
    (* mark_debug="true" *) wire        bandwidth_to_ctrl_tready;
	
	(* mark_debug="true" *) wire [63:0] ctrl_to_lookup_tdata ;
    (* mark_debug="true" *) wire [7:0]  ctrl_to_lookup_tkeep ;
    (* mark_debug="true" *) wire        ctrl_to_lookup_tvalid;
    (* mark_debug="true" *) wire        ctrl_to_lookup_tlast ;
    (* mark_debug="true" *) wire        ctrl_to_lookup_tready;
	
	wire [10:0]	table_to_bandwidth_frame_len;
	wire [11:0]	table_to_bandwidth_meter_id;
	wire [10:0]	table_to_bandwidth_max_frame_len;
	wire [11:0]	table_to_bandwidth_gate_id;
	
	wire [10:0]	bandwidth_to_ctrl_frame_len;
	wire [11:0]	bandwidth_to_ctrl_meter_id;
	wire [10:0]	bandwidth_to_ctrl_max_frame_len;
	wire [11:0]	bandwidth_to_ctrl_gate_id;
	wire [31:0]	bandwidth_to_ctrl_reserved_bandwidth;
	
	wire [10:0]	ctrl_to_lookup_frame_len;
	wire [11:0]	ctrl_to_lookup_gate_id;
	
	Qci_lookup_table qci_table(
        .clk(clk),
        .rst(rst),
        .rx_axis_tdata (rx_axis_tdata   ),
        .rx_axis_tkeep (rx_axis_tkeep   ),
        .rx_axis_tvalid(rx_axis_tvalid  ),
        .rx_axis_tlast (rx_axis_tlast   ),
        .rx_axis_tready(rx_axis_tready  ),
        
        .tx_axis_tdata (table_to_bandwidth_tdata ),
        .tx_axis_tkeep (table_to_bandwidth_tkeep ),
        .tx_axis_tvalid(table_to_bandwidth_tvalid),
        .tx_axis_tlast (table_to_bandwidth_tlast ),
        .tx_axis_tready(table_to_bandwidth_tready),
        
        .frame_len_in		(frame_len_in),
		
        .meter_id_out		(table_to_bandwidth_meter_id),
        .frame_len_out		(table_to_bandwidth_frame_len),
        .max_frame_len_out	(table_to_bandwidth_max_frame_len),
        .gate_id_out		(table_to_bandwidth_gate_id)
);

	use_meter_id_to_find_reserve_bandwidth reserved_bandwidth(
		.clk(clk),
		.rst(rst),
		.rx_axis_tdata	(table_to_bandwidth_tdata	),
		.rx_axis_tkeep	(table_to_bandwidth_tkeep	),
		.rx_axis_tlast	(table_to_bandwidth_tlast	),
		.rx_axis_tvalid	(table_to_bandwidth_tvalid	),
		.rx_axis_tready	(table_to_bandwidth_tready	),
		                
		.tx_axis_tdata	(bandwidth_to_ctrl_tdata	),
		.tx_axis_tkeep	(bandwidth_to_ctrl_tkeep	),
		.tx_axis_tlast	(bandwidth_to_ctrl_tlast	),
		.tx_axis_tvalid	(bandwidth_to_ctrl_tvalid	),
		.tx_axis_tready	(bandwidth_to_ctrl_tready	),
		
		.frame_len_in		(table_to_bandwidth_frame_len),
		.meter_id_in		(table_to_bandwidth_meter_id),
		.gate_id_in			(table_to_bandwidth_gate_id),
		.max_frame_len_in	(table_to_bandwidth_max_frame_len),
		
		.frame_len_out		(bandwidth_to_ctrl_frame_len		),
		.meter_id_out		(bandwidth_to_ctrl_meter_id		),
		.gate_id_out		(bandwidth_to_ctrl_gate_id		),
		.max_frame_len_out	(bandwidth_to_ctrl_max_frame_len	),
		.reserved_bandwidth_out (bandwidth_to_ctrl_reserved_bandwidth )
);
    
    flow_ctrl flow_ctrl(
        .clk(clk),
        .rst(rst),
        
        .rx_axis_tdata (bandwidth_to_ctrl_tdata ),
        .rx_axis_tvalid(bandwidth_to_ctrl_tvalid),
        .rx_axis_tlast (bandwidth_to_ctrl_tlast ),
        .rx_axis_tkeep (bandwidth_to_ctrl_tkeep ),
        .rx_axis_tready(bandwidth_to_ctrl_tready),
        
        .meter_id_in			(bandwidth_to_ctrl_meter_id),
        .frame_len_in			(bandwidth_to_ctrl_frame_len),
        .max_frame_len_in		(bandwidth_to_ctrl_max_frame_len),
        .reserved_bandwidth_in	(bandwidth_to_ctrl_reserved_bandwidth),
        .gate_id_in				(bandwidth_to_ctrl_gate_id),
        
        .gate_id_out(ctrl_to_lookup_gate_id),
        .frame_len_out(ctrl_to_lookup_frame_len),
        
        .tx_axis_tdata (ctrl_to_lookup_tdata ),
        .tx_axis_tkeep (ctrl_to_lookup_tkeep ),
        .tx_axis_tlast (ctrl_to_lookup_tlast ),
        .tx_axis_tvalid(ctrl_to_lookup_tvalid),
        .tx_axis_tready(ctrl_to_lookup_tready)
    );
    
    SR_class_lookup_table sr_lookup(
		.clk	(clk),
        .rst	(rst),
        
        .rx_axis_tdata (ctrl_to_lookup_tdata ),
        .rx_axis_tvalid(ctrl_to_lookup_tvalid),
        .rx_axis_tlast (ctrl_to_lookup_tlast ),
        .rx_axis_tkeep (ctrl_to_lookup_tkeep ),
        .rx_axis_tready(ctrl_to_lookup_tready),
        
        .frame_len_in	(ctrl_to_lookup_frame_len),
        .gate_id_in		(ctrl_to_lookup_gate_id),
		
		.frame_len_out	(frame_len_out),
        .gate_id_out	(gate_id_out),
		.tdest_out		(tx_axis_tdest),
        
        .tx_axis_tdata (tx_axis_tdata ),
        .tx_axis_tkeep (tx_axis_tkeep ),
        .tx_axis_tlast (tx_axis_tlast ),
        .tx_axis_tvalid(tx_axis_tvalid),
        .tx_axis_tready(tx_axis_tready)
    );
	
endmodule
