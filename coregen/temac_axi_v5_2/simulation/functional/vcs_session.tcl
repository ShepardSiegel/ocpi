gui_open_window Wave
gui_list_select -id Hier.1 { glbl testbench }
gui_sg_create TEMAC_Group
gui_list_add_group -id Wave.1 {TEMAC_Group}
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Configuration_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { MDIO_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Rx_GMII_MII_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Tx_GMII_MII_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Tx_FIFO_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Rx_FIFO_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Flow_Control }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Rx_Statistics_Vector }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Rx_MAC_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Tx_Statistics_Vector }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { Tx_MAC_Interface }
gui_list_add_divider -id Wave.1 -after TEMAC_Group { System_Signals }

gui_list_add -id Wave.1 -after System_Signals { {testbench.reset}  {testbench.gtx_clk}}
gui_list_add -id Wave.1 -after Tx_MAC_Interface { testbench.dut.trimac_fifo_block.tx_axis_mac_tuser }
gui_list_add -id Wave.1 -after Tx_MAC_Interface { testbench.dut.trimac_fifo_block.tx_axis_mac_tlast }
gui_list_add -id Wave.1 -after Tx_MAC_Interface { testbench.dut.trimac_fifo_block.tx_axis_mac_tready }
gui_list_add -id Wave.1 -after Tx_MAC_Interface { testbench.dut.trimac_fifo_block.tx_axis_mac_tdata }
gui_list_add -id Wave.1 -after Tx_MAC_Interface { testbench.dut.trimac_fifo_block.tx_axis_mac_tvalid }
gui_list_add -id Wave.1 -after Tx_MAC_Interface { testbench.dut.trimac_fifo_block.tx_mac_resetn }
gui_list_add -id Wave.1 -after Tx_Statistics_Vector { testbench.dut.tx_statistics_valid }
gui_list_add -id Wave.1 -after Tx_Statistics_Vector { testbench.dut.tx_statistics_vector }
gui_list_add -id Wave.1 -after Rx_MAC_Interface { testbench.dut.trimac_fifo_block.rx_axis_mac_tuser }
gui_list_add -id Wave.1 -after Rx_MAC_Interface { testbench.dut.trimac_fifo_block.rx_axis_mac_tlast }
gui_list_add -id Wave.1 -after Rx_MAC_Interface { testbench.dut.trimac_fifo_block.rx_axis_mac_tdata }
gui_list_add -id Wave.1 -after Rx_MAC_Interface { testbench.dut.trimac_fifo_block.rx_axis_mac_tvalid }
gui_list_add -id Wave.1 -after Rx_MAC_Interface { testbench.dut.trimac_fifo_block.rx_mac_resetn }
gui_list_add -id Wave.1 -after Rx_MAC_Interface { testbench.dut.trimac_fifo_block.rx_mac_aclk }
gui_list_add -id Wave.1 -after Rx_Statistics_Vector { testbench.dut.rx_statistics_valid }
gui_list_add -id Wave.1 -after Rx_Statistics_Vector { testbench.dut.rx_statistics_vector }
gui_list_add -id Wave.1 -after Flow_Control { testbench.dut.pause_req }
gui_list_add -id Wave.1 -after Flow_Control { testbench.dut.pause_val }
gui_list_add -id Wave.1 -after Rx_FIFO_Interface { testbench.dut.trimac_fifo_block.rx_axis_fifo_tvalid }
gui_list_add -id Wave.1 -after Rx_FIFO_Interface { testbench.dut.trimac_fifo_block.rx_axis_fifo_tready }
gui_list_add -id Wave.1 -after Rx_FIFO_Interface { testbench.dut.trimac_fifo_block.rx_axis_fifo_tlast }
gui_list_add -id Wave.1 -after Rx_FIFO_Interface { testbench.dut.trimac_fifo_block.rx_axis_fifo_tdata }
gui_list_add -id Wave.1 -after Rx_FIFO_Interface { testbench.dut.trimac_fifo_block.rx_fifo_resetn }
gui_list_add -id Wave.1 -after Rx_FIFO_Interface { testbench.dut.trimac_fifo_block.rx_fifo_clock }
gui_list_add -id Wave.1 -after Tx_FIFO_Interface { testbench.dut.trimac_fifo_block.tx_axis_fifo_tvalid }
gui_list_add -id Wave.1 -after Tx_FIFO_Interface { testbench.dut.trimac_fifo_block.tx_axis_fifo_tready }
gui_list_add -id Wave.1 -after Tx_FIFO_Interface { testbench.dut.trimac_fifo_block.tx_axis_fifo_tlast }
gui_list_add -id Wave.1 -after Tx_FIFO_Interface { testbench.dut.trimac_fifo_block.tx_axis_fifo_tdata }
gui_list_add -id Wave.1 -after Tx_FIFO_Interface { testbench.dut.trimac_fifo_block.tx_fifo_resetn }
gui_list_add -id Wave.1 -after Tx_FIFO_Interface { testbench.dut.trimac_fifo_block.tx_fifo_clock }
gui_list_add -id Wave.1 -after Tx_GMII_MII_Interface { testbench.gmii_txd }
gui_list_add -id Wave.1 -after Tx_GMII_MII_Interface { testbench.gmii_tx_er }
gui_list_add -id Wave.1 -after Tx_GMII_MII_Interface { testbench.gmii_tx_en }
gui_list_add -id Wave.1 -after Tx_GMII_MII_Interface { testbench.gmii_tx_clk }
gui_list_add -id Wave.1 -after Rx_GMII_MII_Interface { testbench.gmii_rxd }
gui_list_add -id Wave.1 -after Rx_GMII_MII_Interface { testbench.gmii_rx_er }
gui_list_add -id Wave.1 -after Rx_GMII_MII_Interface { testbench.gmii_rx_dv }
gui_list_add -id Wave.1 -after Rx_GMII_MII_Interface { testbench.gmii_rx_clk }
gui_list_add -id Wave.1 -after MDIO_Interface { testbench.mdio }
gui_list_add -id Wave.1 -after MDIO_Interface { testbench.mdc }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_rready  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_rvalid  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_rresp   }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_rdata   }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_arready }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_arvalid }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_araddr  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_bready  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_bvalid  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_bresp   }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_wready  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_wvalid  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_wdata   }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_awready }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_awvalid }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_awaddr  }
gui_list_add -id Wave.1 -after Configuration_Interface { testbench.dut.s_axi_aclk }

gui_zoom -window Wave.1 -full
