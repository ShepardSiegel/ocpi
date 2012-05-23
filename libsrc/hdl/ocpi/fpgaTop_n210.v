// fpgaTop_n210.v - Top Level Verilog for N210 Platform
// 2012-04-23 Creation

module fpgaTop(
  input  wire        sys0_clkp,      // sys0 Clock +
  input  wire        sys0_clkn,      // sys0 Clock -
  input  wire        fpga_rstn,      // async FPGA_RESET active low, S2

  output wire [5:1]  led,            // LEDs n210 {tx,rx,ref,mimo,ok}
  output wire [31:0] debug,          // Debug MICTOR Connector

	input  wire        gmii_sysclk,    // TruPHY ET1011... (125 MHz PHY to MAC)
  output wire        gmii_rstn,
	output wire        gmii_gtx_clk,
	output wire [7:0]  gmii_txd,
	output wire        gmii_tx_en,
	output wire        gmii_tx_er,
	input  wire        gmii_rx_clk,
	input  wire [7:0]  gmii_rxd,
	input  wire        gmii_rx_dv,
	input  wire        gmii_rx_er,
  output wire        mdio_mdc,
  inout  wire        mdio_mdd,
	output wire        gmii_led

);

assign debug[31:24] = 8'hFF;
assign debug[19]   = mdio_mdc;
assign debug[18]   = mdio_mdd;
assign debug[17]   = gmii_sysclk;
assign debug[16]   = gmii_rstn;
assign debug[15:0] = 16'h0000;


// Instance and connect mkFTop...
 mkFTop_n210 ftop(
  .sys0_clkp         (sys0_clkp),    // 100 MHz from ADI9510 ch1
  .sys0_clkn         (sys0_clkn),
  .fpga_rstn         (fpga_rstn),    // pushbutton, active-low

  .led               (led),          // Front-panel LEDs
 // .debug             (debug),        // MICTOR debug connector
  .sys0Clk           (debug[20]),
  .sys0Rst           (debug[21]),
  .sys125Clk         (debug[22]),
  .sys125Rst         (debug[23]),
 

	.gmii_sysclk       (gmii_sysclk),  // 125 MHz PHY to MAC is sys1_clk
	.gmii_rstn         (gmii_rstn),
	.gmii_tx_tx_clk    (gmii_gtx_clk),
	.gmii_tx_txd       (gmii_txd),
	.gmii_tx_tx_en     (gmii_tx_en),
	.gmii_tx_tx_er     (gmii_tx_er),
	.gmii_rx_clk       (gmii_rx_clk),
	.gmii_rx_rxd_i     (gmii_rxd),
	.gmii_rx_rx_dv_i   (gmii_rx_dv),
	.gmii_rx_rx_er_i   (gmii_rx_er),
  .mdio_mdc          (mdio_mdc),
  .mdio_mdd          (mdio_mdd),
	.gmii_led          (gmii_led)

);

endmodule
