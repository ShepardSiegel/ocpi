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
	input  wire        gmii_col,
	input  wire        gmii_crs,
	input  wire        gmii_intr,
  output wire        mdio_mdc,
  inout  wire        mdio_mdd,
	output wire        gmii_led,

  output wire        i2c_scl,       // I2C EEPROMs 
  inout  wire        i2c_sda,

  output wire        flash_clk,      // SPI Flash
  output wire        flash_csn,
  output wire        flash_mosi,
  input  wire        flash_miso,

  input  wire        adc_clkout,     // RX ADC
  input  wire [13:0] adc_da,
  input  wire [13:0] adc_db,
  output wire        adc_sclk,
  output wire        adc_sen,
  output wire        adc_smosi,
  input  wire        adc_smiso,

  input  wire        dac_lock,       // TX DAC
  output wire [15:0] dac_da,
  output wire [15:0] dac_db,
  output wire        dac_sclk,
  output wire        dac_sen,
  output wire        dac_smosi,
  input  wire        dac_smiso

);

// Assorted MICTOR debug assignments...
assign debug[15:0]  = 16'h0000;      // These 16b not on AR-Auburn Agilent MSO
assign debug[16]    = adc_sclk;
assign debug[17]    = adc_sen;
assign debug[18]    = adc_smosi;
assign debug[19]    = adc_smiso;
assign debug[20]    = adc_clkout;
assign debug[31:21] = adc_da[10:0];  // 11b of 14


// Glue and ECO logic implemented at this level...
wire adc_sclkdrv, adc_sclkgate;
assign adc_sclk = adc_sclkdrv||!adc_sclkgate||adc_sen; // keep adc_sclk high when gated off


// Instance and connect mkFTop...
 mkFTop_n210 ftop(
  .sys0_clkp         (sys0_clkp),    // 100 MHz from ADI9510 ch1
  .sys0_clkn         (sys0_clkn),
  .fpga_rstn         (fpga_rstn),    // pushbutton, active-low
  .led               (led),          // Front-panel LEDs

//.debug             (debug),        // MICTOR debug connector
//.sys0Clk           (debug[20]),
//.sys0Rst           (debug[21]),
//.sys125Clk         (debug[22]),
//.sys125Rst         (debug[23]),

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
	.gmii_col_i        (gmii_col),
	.gmii_crs_i        (gmii_crs),
	.gmii_intr_i       (gmii_intr),
  .mdio_mdc          (mdio_mdc),
  .mdio_mdd          (mdio_mdd),
	.gmii_led          (gmii_led),

  .i2c_scl           (i2c_scl),      // I2C EEPROMs 
  .i2c_sda           (i2c_sda),

  .flash_clk         (flash_clk),    // SPI Flash
  .flash_csn         (flash_csn),
  .flash_mosi        (flash_mosi),
  .flash_miso_i      (flash_miso),

  .adc_clkout        (adc_clkout),
  .adc_da_i          (adc_da),
  .adc_db_i          (adc_db),
  .adc_smosi         (adc_smosi),
  .adc_sclk          (adc_sclkdrv),
  .adc_sclkgate      (adc_sclkgate),
  .adc_sen           (adc_sen),
  .adc_smiso_i       (adc_smiso)

 // .dac_lock_i        (dac_lock),
 // .dac_da            (dac_da),
 // .dac_db            (dac_db),
 // .dac_smosi         (dac_smosi),
 // .dac_sclk          (dac_sclk),
 // .dac_sen           (dac_sen),
 // .dac_smiso_i       (dac_smiso)

);

endmodule
