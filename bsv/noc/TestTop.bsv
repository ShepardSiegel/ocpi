import Clocks           :: *;
import XilinxPCIE       :: *;
import LCDController    :: *;
import ButtonController :: *;
import LEDController    :: *;
import DIPSwitch        :: *;

import Top :: *;

(* synthesize *)
module mkTestTop();

   Clock pci_clk_p <- mkAbsoluteClock(1,10);
   Clock pci_clk_n <- mkAbsoluteClock(6,10);
   Reset sys_reset <- mkAsyncResetFromCR(1,pci_clk_p);

   FPGA fpga <- mkTop(pci_clk_p, pci_clk_n, sys_reset);

   (* fire_when_enabled, no_implicit_conditions *)
   rule tie_off_fpga_inputs;
      fpga.dip.switch('0);
      fpga.left.button(0);
      fpga.right.button(0);
      fpga.top.button(0);
      fpga.bottom.button(0);
      fpga.center.button(0);
      fpga.pcie.rxp('1);
      fpga.pcie.rxn('0);
   endrule

   // ignore LCD and LEDs

endmodule
