//Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2016.4 (lin64) Build 1733598 Wed Dec 14 22:35:42 MST 2016
//Date        : Wed Sep  6 21:19:46 2017
//Host        : localhost.localdomain running 64-bit CentOS release 6.8 (Final)
//Command     : generate_target axi_top.bd
//Design      : axi_top
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module host_axi_top
(
	mclk_0,
	mclk_1,
	mclk_2,
	mclk_3,
	mdio_0,
	mdio_1,
	mdio_2,
	mdio_3,
	mspi_sck_out_0,
	mspi_sck_out_1,
	mspi_sck_out_2,
	mspi_sck_out_3,
	mspi_ssn_0,
	mspi_ssn_1,
	mspi_ssn_2,
	mspi_ssn_3,
	mspi_miso_0,
	mspi_miso_1,
	mspi_miso_2,
	mspi_miso_3,
	mspi_mosi_0,			
	mspi_mosi_1,			
	mspi_mosi_2,			
	mspi_mosi_3,			  
  txd_out,
  rxd_in,
  cts_in,
  rts_out,	
  clkin_100m_p,
  clkin_100m_n,
  reset_n,
  fan_ctl_o
);

	output mclk_0;
	output mclk_1;
	output mclk_2;
	output mclk_3;
	inout mdio_0;
	inout mdio_1;
	inout mdio_2;
	inout mdio_3;
	output mspi_sck_out_0;
	output mspi_sck_out_1;
	output mspi_sck_out_2;
	output mspi_sck_out_3;
	output mspi_ssn_0;
	output mspi_ssn_1;
	output mspi_ssn_2;
	output mspi_ssn_3;
	input  mspi_miso_0;
	input  mspi_miso_1;
	input  mspi_miso_2;
	input  mspi_miso_3;
	output mspi_mosi_0;			
	output mspi_mosi_1;			
	output mspi_mosi_2;			
	output mspi_mosi_3;			    
  output txd_out;
	input rxd_in;
	input cts_in;
	output rts_out;
	input clkin_100m_p;
	input clkin_100m_n;
	input reset_n;
    output fan_ctl_o;
	
	wire clk;
	
	IBUFDS u_clkin_100m (.I(clkin_100m_p), .IB(clkin_100m_n), .O(clk));
	
     fan_ctrl u_fan_ctrl(
       .clk(clk),
       .reset_n(reset_n),
       .fan_ctl_o(fan_ctl_o)
      );
	

  wire s00_axi_aclk;
  wire s00_axi_aresetn;

  wire m00_axi_aclk;
  wire m00_axi_aresetn;
  
  assign s00_axi_aclk = clk;
  assign m00_axi_aclk = clk;
  assign s00_axi_aresetn = reset_n;
  assign m00_axi_aresetn = reset_n;

  wire [31:0]axi4_lite_inf_v1_0_0_m00_axi_ARADDR;
  wire [2:0]axi4_lite_inf_v1_0_0_m00_axi_ARPROT;
  wire axi4_lite_inf_v1_0_0_m00_axi_ARREADY;
  wire axi4_lite_inf_v1_0_0_m00_axi_ARVALID;
  wire [31:0]axi4_lite_inf_v1_0_0_m00_axi_AWADDR;
  wire [2:0]axi4_lite_inf_v1_0_0_m00_axi_AWPROT;
  wire axi4_lite_inf_v1_0_0_m00_axi_AWREADY;
  wire axi4_lite_inf_v1_0_0_m00_axi_AWVALID;
  wire axi4_lite_inf_v1_0_0_m00_axi_BREADY;
  wire [1:0]axi4_lite_inf_v1_0_0_m00_axi_BRESP;
  wire axi4_lite_inf_v1_0_0_m00_axi_BVALID;
  wire [31:0]axi4_lite_inf_v1_0_0_m00_axi_RDATA;
  wire axi4_lite_inf_v1_0_0_m00_axi_RREADY;
  wire [1:0]axi4_lite_inf_v1_0_0_m00_axi_RRESP;
  wire axi4_lite_inf_v1_0_0_m00_axi_RVALID;
  wire [31:0]axi4_lite_inf_v1_0_0_m00_axi_WDATA;
  wire axi4_lite_inf_v1_0_0_m00_axi_WREADY;
  wire [3:0]axi4_lite_inf_v1_0_0_m00_axi_WSTRB;
  wire axi4_lite_inf_v1_0_0_m00_axi_WVALID;

  axi4_lite_inf_v1_0 u_axi4_lite_inf_v1_0
       (
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
			  .txd_out(txd_out),
				.rxd_in(rxd_in),
				.cts_in(cts_in),
				.rts_out(rts_out),       
        .m00_axi_aclk(m00_axi_aclk),
        .m00_axi_araddr(axi4_lite_inf_v1_0_0_m00_axi_ARADDR),
        .m00_axi_aresetn(m00_axi_aresetn),
        .m00_axi_arprot(axi4_lite_inf_v1_0_0_m00_axi_ARPROT),
        .m00_axi_arready(axi4_lite_inf_v1_0_0_m00_axi_ARREADY),
        .m00_axi_arvalid(axi4_lite_inf_v1_0_0_m00_axi_ARVALID),
        .m00_axi_awaddr(axi4_lite_inf_v1_0_0_m00_axi_AWADDR),
        .m00_axi_awprot(axi4_lite_inf_v1_0_0_m00_axi_AWPROT),
        .m00_axi_awready(axi4_lite_inf_v1_0_0_m00_axi_AWREADY),
        .m00_axi_awvalid(axi4_lite_inf_v1_0_0_m00_axi_AWVALID),
        .m00_axi_bready(axi4_lite_inf_v1_0_0_m00_axi_BREADY),
        .m00_axi_bresp(axi4_lite_inf_v1_0_0_m00_axi_BRESP),
        .m00_axi_bvalid(axi4_lite_inf_v1_0_0_m00_axi_BVALID),
        .m00_axi_rdata(axi4_lite_inf_v1_0_0_m00_axi_RDATA),
        .m00_axi_rready(axi4_lite_inf_v1_0_0_m00_axi_RREADY),
        .m00_axi_rresp(axi4_lite_inf_v1_0_0_m00_axi_RRESP),
        .m00_axi_rvalid(axi4_lite_inf_v1_0_0_m00_axi_RVALID),
        .m00_axi_wdata(axi4_lite_inf_v1_0_0_m00_axi_WDATA),
        .m00_axi_wready(axi4_lite_inf_v1_0_0_m00_axi_WREADY),
        .m00_axi_wstrb(axi4_lite_inf_v1_0_0_m00_axi_WSTRB),
        .m00_axi_wvalid(axi4_lite_inf_v1_0_0_m00_axi_WVALID),
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_araddr(axi4_lite_inf_v1_0_0_m00_axi_ARADDR[10:0]),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_arprot(axi4_lite_inf_v1_0_0_m00_axi_ARPROT),
        .s00_axi_arready(axi4_lite_inf_v1_0_0_m00_axi_ARREADY),
        .s00_axi_arvalid(axi4_lite_inf_v1_0_0_m00_axi_ARVALID),
        .s00_axi_awaddr(axi4_lite_inf_v1_0_0_m00_axi_AWADDR[10:0]),
        .s00_axi_awprot(axi4_lite_inf_v1_0_0_m00_axi_AWPROT),
        .s00_axi_awready(axi4_lite_inf_v1_0_0_m00_axi_AWREADY),
        .s00_axi_awvalid(axi4_lite_inf_v1_0_0_m00_axi_AWVALID),
        .s00_axi_bready(axi4_lite_inf_v1_0_0_m00_axi_BREADY),
        .s00_axi_bresp(axi4_lite_inf_v1_0_0_m00_axi_BRESP),
        .s00_axi_bvalid(axi4_lite_inf_v1_0_0_m00_axi_BVALID),
        .s00_axi_rdata(axi4_lite_inf_v1_0_0_m00_axi_RDATA),
        .s00_axi_rready(axi4_lite_inf_v1_0_0_m00_axi_RREADY),
        .s00_axi_rresp(axi4_lite_inf_v1_0_0_m00_axi_RRESP),
        .s00_axi_rvalid(axi4_lite_inf_v1_0_0_m00_axi_RVALID),
        .s00_axi_wdata(axi4_lite_inf_v1_0_0_m00_axi_WDATA),
        .s00_axi_wready(axi4_lite_inf_v1_0_0_m00_axi_WREADY),
        .s00_axi_wstrb(axi4_lite_inf_v1_0_0_m00_axi_WSTRB),
        .s00_axi_wvalid(axi4_lite_inf_v1_0_0_m00_axi_WVALID)
        );
endmodule
