module DCM_BUFG (input I, input RST_N, output O);

   wire CLKFB_IN;
   wire GND_BIT;
   wire [6:0] GND_BUS_7;
   wire [15:0] GND_BUS_16;
   wire RST_P;
   
   assign GND_BIT = 0;
   assign GND_BUS_7 = 7'b0000000;
   assign GND_BUS_16 = 16'b0000000000000000;
   assign RST_P = !RST_N;

   assign O = CLKFB_IN;

   BUFG CLK0_BUFG_INST (.I(CLK0_BUF), 
                        .O(CLKFB_IN));

   DCM_ADV DCM_ADV_INST (.CLKFB(CLKFB_IN), 
                         .CLKIN(I), 
                         .DADDR(GND_BUS_7[6:0]), 
                         .DCLK(GND_BIT), 
                         .DEN(GND_BIT), 
                         .DI(GND_BUS_16[15:0]), 
                         .DWE(GND_BIT), 
                         .PSCLK(GND_BIT), 
                         .PSEN(GND_BIT), 
                         .PSINCDEC(GND_BIT), 
                         .RST(RST_P), 
                         .CLKDV(), 
                         .CLKFX(), 
                         .CLKFX180(), 
                         .CLK0(CLK0_BUF), 
                         .CLK2X(), 
                         .CLK2X180(), 
                         .CLK90(), 
                         .CLK180(), 
                         .CLK270(), 
                         .DO(), 
                         .DRDY(), 
                         .LOCKED(LOCKED_OUT), 
                         .PSDONE());
   defparam DCM_ADV_INST.CLK_FEEDBACK = "1X";
   defparam DCM_ADV_INST.CLKDV_DIVIDE = 2.0;
   defparam DCM_ADV_INST.CLKFX_DIVIDE = 1;
   defparam DCM_ADV_INST.CLKFX_MULTIPLY = 4;
   defparam DCM_ADV_INST.CLKIN_DIVIDE_BY_2 = "FALSE";
   defparam DCM_ADV_INST.CLKIN_PERIOD = 8.000;
   defparam DCM_ADV_INST.CLKOUT_PHASE_SHIFT = "NONE";
   defparam DCM_ADV_INST.DCM_AUTOCALIBRATION = "TRUE";
   defparam DCM_ADV_INST.DCM_PERFORMANCE_MODE = "MAX_SPEED";
   defparam DCM_ADV_INST.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
   defparam DCM_ADV_INST.DFS_FREQUENCY_MODE = "LOW";
   defparam DCM_ADV_INST.DLL_FREQUENCY_MODE = "LOW";
   defparam DCM_ADV_INST.DUTY_CYCLE_CORRECTION = "TRUE";
   defparam DCM_ADV_INST.FACTORY_JF = 16'hF0F0;
   defparam DCM_ADV_INST.PHASE_SHIFT = 0;
   defparam DCM_ADV_INST.STARTUP_WAIT = "FALSE";
   defparam DCM_ADV_INST.SIM_DEVICE = "VIRTEX5";
endmodule
