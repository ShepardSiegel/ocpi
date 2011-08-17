// fpgaTop_alst4.v - the top-level Verilog for the Altera 4SGX230N board
// Copyright (c) 2011 Atomic Rules LLC - ALL RIGHTS RESERVED
//

module fpgaTop (
  input  wire         sys0_clk,       // 200MHz free-running
  input  wire         sys0_rstn.      // External active-low reset 
  input  wire         pcie_clk,       // PCIe Clock
  input  wire         pcie_rstn,      // PCIe Reset
  input  wire [ 3:0]  pcie_rx,        // PCIe lanes...
  output wire [ 3:0]  pcie_tx,
  input  wire [ 7:0]  usr_sw,         // dip-switches
  output wire [15:0]  led,            // leds
  input  wire [18:0]  hsmc_in,        // HSMC_Inputs  D0 :17
  output wire [18:0]  hsmc_out,       // HSMC_Outputs D18:37
  output wire [19:0]  led_cathode,    // LED cathodes
  output wire [19:0]  led_anode,      // LED anodes,
  output wire [25:1]  fsm_addr,       // Shared FLASH and SRAM address
  inout  wire [31:0]  fsm_data,       // Shared FLASH[15:0]and SRAM[31:0] data
  output wire         sram_clk,       // SRAM clock
  output wire         sram_oen,       // SRAM output enable
  output wire         sram_cen,       // SRAM chip enable
  output wire [3:0]   sram_bwn,       // SRAM Byte Write enable
  output wire         sram_gwn,       // SRAM Global Write enable
  output wire         sram_adscn,     // SRAM Address Status Controller
  output wire         sram_adspn,     // SRAM Address Status Processor
  output wire         sram_advn,      // SRAM Address Valid
  output wire         sram_zz,        // SRAM Sleep
  output wire         flash_clk,      // FLASH clock
  output wire         flash_rstn,     // FLASH reset
  output wire         flash_cen,      // FLASH chip enable
  output wire         flash_oen,      // FLASH output enable
  output wire         flash_advn,     // FLASH Address Valid
  input  wire         flash_rdyn      // FLASH Ready
);

// Instance and connect mkFTop...
 mkFTop_alst4 ftop (
  .sys0_clk          (sys0_clk),
  .sys0_rstn         (sys0_rstn),
  .pcie_clk          (pcie_clk),
  .pcie_rstn         (pcie_rstn),
  .pcie_rx_i         (pcie_rx),
  .pcie_tx           (pcie_tx),
  .usr_sw_i          (usr_sw),
  .led               (led),
  .p125clk           (),
  .CLK_GATE_p125clk  (),
  .p125rst           (),
  .hsmc_in           (hsmc_in),
  .hsmc_out          (hsmc_out),
  .led_cathode       (led_cathode),
  .led_anode         (led_anode),
  .fsm_addr          (fsm_addr),
  .fsm_data          (fsm_data),
  .sram_clk          (sram_clk),
  .sram_oen          (sram_oen),
  .sram_cen          (sram_cen),
  .sram_bwn          (sram_bwn),
  .sram_gwn          (sram_gwn),
  .sram_adscn        (sram_adscn),
  .sram_adspn        (sram_adspn),
  .sram_advn         (sram_advn),
  .sram_zz           (sram_zz),
  .flash_clk         (flash_clk),
  .flash_rstn        (flash_rstn),
  .flash_cen         (flash_cen),
  .flash_oen         (flash_oen),
  .flash_advn        (flash_advn),
  .flash_rdyn        (flash_rdyn)
);

endmodule
