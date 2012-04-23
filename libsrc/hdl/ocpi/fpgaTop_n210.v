// fpgaTop_n210.v - Top Level Verilog for N210 Platform
// 2012-04-23 Creation

module fpgaTop(
  input  wire        sys0_clkp,      // sys0 Clock +
  input  wire        sys0_clkn,      // sys0 Clock -
  input  wire        fpga_rstn,      // async FPGA_RESET active low, S2

  output wire [5:1]  led,            // LEDs n210 {tx,rx,ref,mimo,ok}
  output wire [31:0] debug           // Debug MICTOR Connector

  //output wire        gmii_rstn,      // Alaska GMII...
	//output wire        gmii_gtx_clk,
	//output wire [7:0]  gmii_txd,
	//output wire        gmii_tx_en,
	//output wire        gmii_tx_er,
	//input  wire        gmii_rx_clk,
	//input  wire [7:0]  gmii_rxd,
	//input  wire        gmii_rx_dv,
	//input  wire        gmii_rx_er,
  //output wire        mdio_mdc,       // Alaska MDIO...
  //inout  wire        mdio_mdd,

);

// Instance and connect mkFTop...
 mkFTop_n210 ftop(
  .sys0_clkp         (sys0_clkp),
  .sys0_clkn         (sys0_clkn),
  .fpga_rstn         (fpga_rstn),

  .led               (led),
  .debug             (debug)

	//.gmii_rstn         (gmii_rstn),
	//.gmii_tx_txd       (gmii_txd),
	//.gmii_tx_tx_en     (gmii_tx_en),
	//.gmii_tx_tx_er     (gmii_tx_er),
	//.gmii_rx_rxd_i     (gmii_rxd),
	//.gmii_rx_rx_dv_i   (gmii_rx_dv),
	//.gmii_rx_rx_er_i   (gmii_rx_er),
	//.gmii_tx_tx_clk    (gmii_gtx_clk),
	//.gmii_rx_clk       (gmii_rx_clk),
  //.mdio_mdc          (mdio_mdc),
  //.mdio_mdd          (mdio_mdd),

);

endmodule
