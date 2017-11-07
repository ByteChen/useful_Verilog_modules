## 使用说明
* 这个FIFO本来是从10G-subsystem-IP核里提供的，是一个packet mode（存储-转发类型）的FIFO，也就是文件axi_10g_ethernet_0_axi_fifo.v。
* 在上述FIFO的基础上，稍微改了一下文件axi_10g_ethernet_0_axi_fifo.v，能够输出帧长信息，得到下面的rx_fifo_with_frame_length.v。
* rx_fifo_with_frame_length.v 是top文件，其中会用到axi_10g_ethernet_0_axi_fifo.v、axi_10g_ethernet_0_sync_block.v、 axi_10g_ethernet_0_sync_reset.v。