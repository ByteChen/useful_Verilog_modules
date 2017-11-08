* 功能：完成 IEEE 802.1Qci 协议，实现对SR class流量的控制和过滤。
* top module：Qci_filtering_and_policing.v。
* Qci_lookup_table.v ：利用帧的目的mac地址，进行查表，表项中包括：DA、VID、MAX_FRAME_LENGTH、GATE_ID、METER_ID。
* use_meter_id_to_find_reserve_bandwidth.v：主要是利用上面输出的meter_id去查另一个表，得到这个流对应的预留带宽，输出给下一个模块。
* flow_ctrl.v : 完成帧长过滤和流量控制。
* 模块 Qci_gate_ctrl.v 应该被使用在交换之后，根据gate id 或者VLAN帧的优先级，将帧分发到不同队列。