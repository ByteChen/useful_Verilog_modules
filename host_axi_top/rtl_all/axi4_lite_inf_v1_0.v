
`timescale 1 ns / 1 ps

	module axi4_lite_inf_v1_0 #
	(
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 11,

		parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M00_AXI_DATA_WIDTH	= 32
	)
	(
		// Users to add ports here
		output mclk_0,
		output mclk_1,
		output mclk_2,
		output mclk_3,
		inout mdio_0,
		inout mdio_1,
		inout mdio_2,
		inout mdio_3,
		output mspi_sck_out_0,
		output mspi_sck_out_1,
		output mspi_sck_out_2,
		output mspi_sck_out_3,
		output mspi_ssn_0,
		output mspi_ssn_1,
		output mspi_ssn_2,
		output mspi_ssn_3,
		input  mspi_miso_0,
		input  mspi_miso_1,
		input  mspi_miso_2,
		input  mspi_miso_3,
		output mspi_mosi_0,			
		output mspi_mosi_1,			
		output mspi_mosi_2,			
		output mspi_mosi_3,			
				
	  output txd_out,
		input  rxd_in,
		input  cts_in,
		output rts_out,
		// User ports ends
		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Added ports
		// Ports of Axi Master Bus Interface M00_AXI
		input wire  m00_axi_aclk,
		input wire  m00_axi_aresetn,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [2 : 0] m00_axi_awprot,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [1 : 0] m00_axi_bresp,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [2 : 0] m00_axi_arprot,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready
	);
	
		wire [31:0] addr;
		wire [31:0] data_in;
		wire [31:0] data_out;
		wire wr;
		wire rd;
		wire busy;
		wire err;
		
	 debug_host u_debug_host(
		.clk(m00_axi_aclk),
		.reset_n(m00_axi_aresetn),
	  .axi_addr(addr),
	  .axi_busy(busy),
	  .axi_data_in(data_in),
	  .axi_data_out(data_out),
	  .axi_rd(rd),
	  .axi_wr(wr),
	  .txd_out(txd_out),
		.rxd_in(rxd_in),
		.cts_in(cts_in),
		.rts_out(rts_out)
	);		

// Instantiation of Axi Bus Interface S00_AXI
	axi4_lite_inf_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axi4_lite_inf_v1_0_S00_AXI_inst (
		.mclk_0(mclk_0),
		.mclk_1(mclk_1),
		.mclk_2(mclk_2),
		.mclk_3(mclk_3),
		.mdio_0(mdio_0),
		.mdio_1(mdio_1),
		.mdio_2(mdio_2),
		.mdio_3(mdio_3),
		.mspi_sck_out_0(mspi_sck_out_0),
		.mspi_sck_out_1(mspi_sck_out_1),
		.mspi_sck_out_2(mspi_sck_out_2),
		.mspi_sck_out_3(mspi_sck_out_3),
		.mspi_ssn_0(mspi_ssn_0),
		.mspi_ssn_1(mspi_ssn_1),
		.mspi_ssn_2(mspi_ssn_2),
		.mspi_ssn_3(mspi_ssn_3),
		.mspi_miso_0(mspi_miso_0),
		.mspi_miso_1(mspi_miso_1),
		.mspi_miso_2(mspi_miso_2),
		.mspi_miso_3(mspi_miso_3),
		.mspi_mosi_0(mspi_mosi_0),			
		.mspi_mosi_1(mspi_mosi_1),			
		.mspi_mosi_2(mspi_mosi_2),			
		.mspi_mosi_3(mspi_mosi_3),				
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

// Instantiation of Axi Bus Interface M00_AXI
	axi4_lite_inf_v1_0_M00_AXI # ( 
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
	) axi4_lite_inf_v1_0_M00_AXI_inst (
		.addr(addr),
		.data_in(data_in),
		.data_out(data_out),
		.wr(wr),
		.rd(rd),
		.busy(busy),
		.err(err),
		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);

	endmodule
