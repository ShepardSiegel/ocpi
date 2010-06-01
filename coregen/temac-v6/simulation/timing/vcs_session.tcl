gui_open_window Wave
gui_list_select -id Hier.1 { testbench }
gui_list_select -id Data.1 { testbench.reset }
gui_sg_create TEMAC_Group
gui_list_add_group -id Wave.1 {TEMAC_Group}
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Test_semaphores }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Management_Signals }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { MDIO_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Tx_GMII_MII_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Rx_GMII_MII_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Flow_Control }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Rx_Client_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Tx_Client_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { System_Signals }
gui_list_add -id Wave.1 -after System_Signals {{testbench.reset} {testbench.gtx_clk} {testbench.host_clk}}
gui_list_add -id Wave.1 -after Tx_Client_Interface {{testbench.dut.tx_clk}}
gui_list_add -id Wave.1 -after Tx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/tx_data_i}}
gui_list_add -id Wave.1 -after Tx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/tx_data_valid_i}}
gui_list_add -id Wave.1 -after Tx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/tx_ack_i}}
gui_list_add -id Wave.1 -after Tx_Client_Interface {{testbench.tx_ifg_delay}}
gui_list_add -id Wave.1 -after Rx_Client_Interface {{testbench.dut.rx_clk_i}}
gui_list_add -id Wave.1 -after Rx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/rx_data_i}}
gui_list_add -id Wave.1 -after Rx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/rx_data_valid_i}}
gui_list_add -id Wave.1 -after Rx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/rx_good_frame_i}}
gui_list_add -id Wave.1 -after Rx_Client_Interface {{testbench.dut.\v6_emac_v1_3_locallink_inst/rx_bad_frame_i}}
gui_list_add -id Wave.1 -after Flow_Control {{testbench.pause_val}}
gui_list_add -id Wave.1 -after Flow_Control {{testbench.pause_req}}
gui_list_add -id Wave.1 -after Tx_GMII_MII_Interface {{testbench.gmii_tx_clk} {testbench.gmii_txd} {testbench.gmii_tx_en} {testbench.gmii_tx_er}}
gui_list_add -id Wave.1 -after Rx_GMII_MII_Interface {{testbench.gmii_rx_clk} {testbench.gmii_rxd} {testbench.gmii_rx_dv} {testbench.gmii_rx_er}}
gui_list_add -id Wave.1 -after MDIO_Interface {{testbench.mdc}}
gui_list_add -id Wave.1 -after MDIO_Interface {{testbench.mdio_in} {testbench.mdio_out} {testbench.mdio_tri}}
gui_list_add -id Wave.1 -after Management_Signals {{testbench.host_clk} {testbench.host_opcode} {testbench.host_addr} {testbench.host_wr_data} {testbench.host_rd_data} {testbench.host_miim_sel} {testbench.host_req} {testbench.host_miim_rdy}}
gui_list_add -id Wave.1 -after Test_semaphores {{testbench.configuration_busy} {testbench.monitor_finished_1g} {testbench.monitor_finished_100m} {testbench.monitor_finished_10m}}
gui_zoom -window Wave.1 -full
