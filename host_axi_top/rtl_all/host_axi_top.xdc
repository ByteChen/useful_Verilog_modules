create_clock -period 10.000 -name clkin_100m_p [get_ports clkin_100m_p]

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets u_clk_100m/inst/clk_in1_clk_100m]

set_property IOSTANDARD DIFF_SSTL15 [get_ports clkin_100m_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clkin_100m_p]
set_property PACKAGE_PIN K21 [get_ports clkin_100m_p]
set_property PACKAGE_PIN J21 [get_ports clkin_100m_n]

#set_property IOSTANDARD LVCMOS18 [get_ports led[*]]
set_property IOSTANDARD LVCMOS18 [get_ports reset_n]

#set_property PACKAGE_PIN BB15 [ get_ports "led[0]" ]
#set_property PACKAGE_PIN BB16 [ get_ports "led[1]" ]
#set_property PACKAGE_PIN BC16 [ get_ports "led[2]" ]
#set_property PACKAGE_PIN AU22 [ get_ports "led[3]" ]

set_property PACKAGE_PIN BD16 [get_ports reset_n]

set_property IOSTANDARD LVCMOS15 [get_ports fan_ctl_o]
set_property PACKAGE_PIN R30 [get_ports fan_ctl_o]

set_property IOSTANDARD LVCMOS15 [get_ports rxd_in]
set_property IOSTANDARD LVCMOS15 [get_ports txd_out]
set_property IOSTANDARD LVCMOS15 [get_ports cts_in]
set_property IOSTANDARD LVCMOS15 [get_ports rts_out]
#set_property IOSTANDARD LVCMOS15 [get_ports uart2_rxd]
#set_property IOSTANDARD LVCMOS15 [get_ports uart2_txd]
#set_property IOSTANDARD LVCMOS15 [get_ports uart2_cts]
#set_property IOSTANDARD LVCMOS15 [get_ports uart2_rts]

set_property PACKAGE_PIN T15 [get_ports rxd_in]
set_property PACKAGE_PIN D25 [get_ports txd_out]
set_property PACKAGE_PIN E25 [get_ports cts_in]
set_property PACKAGE_PIN H27 [get_ports rts_out]
#set_property PACKAGE_PIN K28 [get_ports uart2_rxd]
#set_property PACKAGE_PIN J28 [get_ports uart2_txd]
#set_property PACKAGE_PIN N26 [get_ports uart2_cts]
#set_property PACKAGE_PIN T31 [get_ports uart2_rts]

set_property IOSTANDARD LVCMOS18 [get_ports mclk_0]
set_property IOSTANDARD LVCMOS18 [get_ports mclk_1]
set_property IOSTANDARD LVCMOS18 [get_ports mclk_2]
set_property IOSTANDARD LVCMOS18 [get_ports mclk_3]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_0]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_1]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_2]
set_property IOSTANDARD LVCMOS18 [get_ports mdio_3]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_sck_out_0]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_sck_out_1]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_sck_out_2]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_sck_out_3]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_ssn_0]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_ssn_1]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_ssn_2]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_ssn_3]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_miso_0]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_miso_1]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_miso_2]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_miso_3]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_mosi_0]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_mosi_1]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_mosi_2]
set_property IOSTANDARD LVCMOS18 [get_ports mspi_mosi_3]

set_property PACKAGE_PIN J34 [get_ports mclk_0]
set_property PACKAGE_PIN J35 [get_ports mclk_1]
set_property PACKAGE_PIN K36 [get_ports mclk_2]
set_property PACKAGE_PIN J36 [get_ports mclk_3]
set_property PACKAGE_PIN K32 [get_ports mdio_0]
set_property PACKAGE_PIN K33 [get_ports mdio_1]
set_property PACKAGE_PIN L37 [get_ports mdio_2]
set_property PACKAGE_PIN K37 [get_ports mdio_3]
set_property PACKAGE_PIN K35 [get_ports mspi_sck_out_0]
set_property PACKAGE_PIN N37 [get_ports mspi_sck_out_1]
set_property PACKAGE_PIN R37 [get_ports mspi_sck_out_2]
set_property PACKAGE_PIN V34 [get_ports mspi_sck_out_3]
set_property PACKAGE_PIN L33 [get_ports mspi_ssn_0]
set_property PACKAGE_PIN N33 [get_ports mspi_ssn_1]
set_property PACKAGE_PIN R31 [get_ports mspi_ssn_2]
set_property PACKAGE_PIN U34 [get_ports mspi_ssn_3]
set_property PACKAGE_PIN J33 [get_ports mspi_miso_0]
set_property PACKAGE_PIN M35 [get_ports mspi_miso_1]
set_property PACKAGE_PIN T33 [get_ports mspi_miso_2]
set_property PACKAGE_PIN U32 [get_ports mspi_miso_3]
set_property PACKAGE_PIN L35 [get_ports mspi_mosi_0]
set_property PACKAGE_PIN N36 [get_ports mspi_mosi_1]
set_property PACKAGE_PIN R36 [get_ports mspi_mosi_2]
set_property PACKAGE_PIN V33 [get_ports mspi_mosi_3]

set_property PULLTYPE PULLUP [get_ports mdio_0]
set_property PULLTYPE PULLUP [get_ports mdio_1]
set_property PULLTYPE PULLUP [get_ports mdio_2]
set_property PULLTYPE PULLUP [get_ports mdio_3]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 40 [current_design]
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE TYPE2 [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 65536 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/state[0]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/state[1]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[0]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[1]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[2]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[3]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[4]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[5]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[6]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[7]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[8]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[9]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[10]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[11]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[12]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[13]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[14]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/data_out[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 6 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/cnt1[0]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/cnt1[1]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/cnt1[2]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/cnt1[3]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/cnt1[4]} {u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/cnt1[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/i_mdio]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/mclk]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/mspi_miso]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/mspi_mosi]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/mspi_sck_out]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/mspi_ssn]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/o_mdio]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/oen_mdio]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list u_axi4_lite_inf_v1_0/axi4_lite_inf_v1_0_S00_AXI_inst/u_mdio/out_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_BUFG]