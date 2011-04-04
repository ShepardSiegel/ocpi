import Clocks       :: *;
import Vector       :: *;
import GetPut       :: *;
import Connectable  :: *;
import FIFO         :: *;
import DefaultValue :: *;
import TieOff       :: *;
import XilinxCells  :: *;
import XilinxPCIE   :: *;
import StmtFSM      :: *;
import DReg         :: *;

import LCDController    :: *;
import ButtonController :: *;
import LEDController    :: *;
import DIPSwitch        :: *;

import MsgFormat        :: *;
import PCIEtoBNoCBridge :: *;
import OnChipBuffer     :: *;

interface FPGA;
   interface DIP#(8)      dip;
   interface LED#(8)      leds;
   interface LCD          lcd;
   interface Button       left;
   interface Button       right;
   interface Button       top;
   interface Button       bottom;
   interface Button       center;
   interface LED#(1)      left_led;
   interface LED#(1)      right_led;
   interface LED#(1)      top_led;
   interface LED#(1)      bottom_led;
   interface LED#(1)      center_led;
   interface PCIE_EXP#(8) pcie;
endinterface

`ifdef SIMULATION_TEST

(* synthesize *)
module mkPCIETest(PCIExpressV6#(8));

   Clock epClock250 <- mkAbsoluteClock(2,4);
   Reset epReset250 <- mkAsyncResetFromCR(4,epClock250);

   Clock epClock125 <- mkAbsoluteClock(2,8);
   Reset epReset125 <- mkAsyncResetFromCR(2,epClock125);

   FIFO#(TLPData#(8)) tlps_out <- mkFIFO(clocked_by epClock250, reset_by epReset250);
   FIFO#(TLPData#(8)) tlps_in  <- mkFIFO(clocked_by epClock250, reset_by epReset250);

   function Bit#(8) as_char(Bit#(8) n);
      if (n >= 8'h20 && n <= 8'h7e)
         return n;
      else
         return 8'h2e;
   endfunction

   rule show_incoming_tlps;
      TLPData#(8) tlp = tlps_in.first();
      tlps_in.deq();
      $display("%0t: INCOMING TLP DATA (%b)", $time(), tlp.hit);
      $display("        sof = %b   eof = %b", tlp.sof, tlp.eof);
      $display("        %8x   %b    %c%c%c%c", tlp.data[63:32], tlp.be[7:4],
         as_char(tlp.data[63:56]), as_char(tlp.data[55:48]), as_char(tlp.data[47:40]), as_char(tlp.data[39:32]));
      $display("        %8x   %b    %c%c%c%c", tlp.data[31:0],  tlp.be[3:0],
         as_char(tlp.data[31:24]), as_char(tlp.data[23:16]), as_char(tlp.data[15:8]), as_char(tlp.data[7:0]));

   endrule

   function UInt#(30) node_addr(NodeID dst, UInt#(18) dw_addr);
      return unpack({4'd0, pack(dst), pack(dw_addr)});
   endfunction

   function Stmt rd(UInt#(2) bar, UInt#(30) addr, UInt#(10) dws, Bit#(4) fbe, Bit#(4) lbe, Bit#(8) tag);
      Bit#(32) dw0 = { 1'b0, 2'd0, 5'd0  // fmt = 0 (3DW rd) type = 0 (mem)
                     , 1'b0, 3'd0, 4'd0  // tclass = 0 (default)
                     , 6'd0              // no digest, not poisoned, etc.
                     , pack(dws)         // number of DWs to read
                     };
      Bit#(32) dw1 = { 16'h0123          // requester ID
                     , tag               // tag
                     , fbe, lbe          // byte enables
                     };
      TLPData#(8) tlp1 = TLPData { sof:  True
                                 , eof:  False
                                 , hit:  (7'h01 << bar)
                                 , be:   8'hff
                                 , data: { dw0, dw1 }
                                 };
      TLPData#(8) tlp2 = TLPData { sof:  False
                                 , eof:  True
                                 , hit:  (7'h01 << bar)
                                 , be:   8'hf0
                                 , data: { pack(addr), 2'd0, 32'haaaaaaaa }
                                 };
      return seq
                tlps_out.enq(tlp1);
                tlps_out.enq(tlp2);
             endseq;
   endfunction

   Reg#(UInt#(10)) remaining <- mkReg(0, clocked_by epClock250, reset_by epReset250);
   Reg#(UInt#(11)) idx       <- mkReg(0, clocked_by epClock250, reset_by epReset250);

   function Stmt wr(UInt#(2) bar, UInt#(30) addr, Vector#(n,Bit#(32)) val, Bit#(4) fbe, Bit#(4) lbe, Bit#(8) tag);
      UInt#(10) dws = fromInteger(valueOf(n));
      Bit#(32) dw0 = { 1'b0, 2'd2, 5'd0  // fmt = 2 (3DW wr) type = 0 (mem)
                     , 1'b0, 3'd0, 4'd0  // tclass = 0 (default)
                     , 6'd0              // no digest, not poisoned, etc.
                     , pack(dws)         // number of DWs to write
                     };
      Bit#(32) dw1 = { 16'h0123          // requester ID
                     , tag               // tag
                     , fbe, lbe          // byte enables
                     };
      TLPData#(8) tlp1 = TLPData { sof:  True
                                 , eof:  False
                                 , hit:  (7'h01 << bar)
                                 , be:   8'hff
                                 , data: { dw0, dw1 }
                                 };
      TLPData#(8) tlp2 = TLPData { sof:  False
                                 , eof:  (dws == 1)
                                 , hit:  (7'h01 << bar)
                                 , be:   8'hff
                                 , data: { pack(addr), 2'd0, byteSwap(val[0]) }
                                 };

      return seq
                tlps_out.enq(tlp1);
                tlps_out.enq(tlp2);
                if (dws != 1) seq
                   action
                      remaining <= dws - 1;
                      idx       <= 1;
                   endaction
                   while (remaining != 0) action
                      TLPData#(8) tlpN = TLPData { sof:  False
                                                 , eof:  (remaining <= 2)
                                                 , hit:  (7'h01 << bar)
                                                 , be:   (remaining == 1) ? 8'hf0 : 8'hff
                                                 , data: { byteSwap(val[idx]), (remaining == 1) ? 32'haaaaaaaa : byteSwap(val[idx+1]) }
                                                 };
                      tlps_out.enq(tlpN);
                      remaining <= (remaining == 1) ? 0 : (remaining - 2);
                      idx       <= idx + 2;
                   endaction
                endseq
             endseq;
   endfunction

   function Bit#(8) mk_char(UInt#(8) base, Integer i);
      return pack(base + fromInteger(i));
   endfunction

   Vector#(26,Bit#(8)) lower = genWith(mk_char(8'h41));
   Vector#(26,Bit#(8)) upper = genWith(mk_char(8'h61));
   Vector#(5,Vector#(52,Bit#(8))) tmp = replicate(append(lower,upper));
   Vector#(65,Bit#(32)) pattern = unpack(pack(concat(tmp)));

   Stmt test_stmts = seq
                        delay(100);
                        // RD 8B from BAR 0 DW 0 (tag == 1)
                        rd(0,0,2,'1,'1,1);
                        delay(20);
                        // WR 4B (0abcdef0) to NODE 1 DW 2 (tag == 2)
                        wr(1,node_addr(1,2),cons(32'h0abcdef0,nil),'1,'1,2);
                        delay(20);
                        // RD 4B from NODE 1 DW 2 (tag == 3)
                        rd(1,node_addr(1,2),1,'1,'1,3);
                        delay(20);
                        // WR 260B starting at NODE 1 DW 13 (tag == 4)
                        wr(1,node_addr(1,13),pattern,'1,'1,4);
                        delay(20);
                        // RD 104B starting from NODE 1 DW 26 (tag == 5)
                        rd(1,node_addr(1,26),26,'1,'1,5);
                        delay(1000);
                     endseq;

   mkAutoFSM(test_stmts, clocked_by epClock250, reset_by epReset250);

   Reg#(Bool) intr_pulse <- mkDReg(False, clocked_by epClock250, reset_by epReset250);

   PulseWire  im_in_epClock250_domain      <- mkPulseWire(clocked_by epClock250, reset_by epReset250);
   PulseWire  im_also_in_epClock250_domain <- mkPulseWire(clocked_by epClock250, reset_by epReset250);

   interface PCIE_EXP pcie;
      method Action rxp(Bit#(8) i);
      endmethod
      method Action rxn(Bit#(8) i);
      endmethod
      method Bit#(8) txp = '1;
      method Bit#(8) txn = '0;
   endinterface

   interface PCIE_TRN_COMMON_V6 trn;
      interface Clock clk     = epClock250;
      interface Clock clk2    = epClock125;
      interface Reset reset_n = epReset250;
      method    Bool  link_up = True;
   endinterface

   interface PCIE_TRN_XMIT_V6 trn_tx;
      method Action xmit(Bool discontinue, TLPData#(8) data);
         tlps_in.enq(data);
      endmethod
      method Bool dropped = False;
      method Bit#(6) buffers_available = 1;
      method Action cut_through_mode(Bool i);
      endmethod
      method Bool configuration_completion_ready = False;
      method Action configuration_completion_grant(Bool i);
      endmethod
      method Action error_forward(Bool i);
      endmethod
   endinterface

   interface PCIE_TRN_RECV_V6 trn_rx;
      method ActionValue#(TLPData#(8)) recv();
         tlps_out.deq();
         return tlps_out.first();
      endmethod
      method Bool error_forward      = False;
      method Bool source_discontinue = False;
      method Action non_posted_ready(Bool i);
      endmethod
   endinterface

   interface PCIE_CFG_V6 cfg;
      method Bit#(32) dout = '0;
      method Bit#(1)rd_wr_done_n = 0;
      method Action di(Bit#(32) i);
      endmethod
      method Action dwaddr(Bit#(10) i);
      endmethod
      method Action byte_en_n(Bit#(4) i);
      endmethod
      method Action wr_en_n(Bit#(1) i);
      endmethod
      method Action rd_en_n(Bit#(1) i);
      endmethod
      method Bit#(8)  bus_number = 5;
      method Bit#(5)  device_number = 3;
      method Bit#(3)  function_number = 1;
      method Bit#(16) status = '0;
      method Bit#(16) command = 16'h0004;
      method Bit#(16) dstatus = '0;
      method Bit#(16) dcommand = 16'h2000;
      method Bit#(16) dcommand2 = '0;
      method Bit#(16) lstatus = '0;
      method Bit#(16) lcommand = '0;
      method Bit#(1)  to_turnoff_n = 0;
      method Action turnoff_ok_n(Bit#(1) i);
      endmethod
      method Action pm_wake_n(Bit#(1) i);
      endmethod
      method Bit#(3) pcie_link_state_n = '0;
      method Action trn_pending_n(Bit#(1) i);
      endmethod
      method Action dsn(Bit#(64) i);
      endmethod
      method Bit#(1) pmcsr_pme_en = 0;
      method Bit#(1) pmcsr_pme_status = 0;
      method Bit#(2) pmcsr_powerstate = 0;
   endinterface

   interface PCIE_INT_V6 cfg_interrupt;
      method Action req_n(Bit#(1) i);
         if (i == 0) begin
            if (!intr_pulse)
               $display("%t: PCIE interrupt request asserted", $time());
            intr_pulse <= True;
         end
      endmethod
      method Bit#(1) rdy_n = intr_pulse ? 1'b0 : 1'b1;
      method Action assert_n(Bit#(1) i);
         im_in_epClock250_domain.send();
      endmethod
      method Action di(Bit#(8) i);
         im_also_in_epClock250_domain.send();
      endmethod
      method Bit#(8) dout = '0;
      method Bit#(3) mmenable = '0;
      method Bit#(1) msienable = 1;
      method Bit#(1) msixenable = 0;
      method Bit#(1) msixfm = 0;
   endinterface

   interface PCIE_ERR_V6 cfg_err;
      method Action ecrc_n(Bit#(1) i);
      endmethod
      method Action ur_n(Bit#(1) i);
      endmethod
      method Action cpl_timeout_n(Bit#(1) i);
      endmethod
      method Action cpl_unexpect_n(Bit#(1) i);
      endmethod
      method Action cpl_abort_n(Bit#(1) i);
      endmethod
      method Action posted_n(Bit#(1) i);
      endmethod
      method Action cor_n(Bit#(1) i);
      endmethod
      method Action tlp_cpl_header(Bit#(48) i);
      endmethod
      method Bit#(1) cpl_rdy_n = 0;
      method Action locked_n(Bit#(1) i);
      endmethod
   endinterface

   interface PCIE_PL_V6 pl;
      method Bit#(2) initial_link_width = '0;
      method Bit#(2) lane_reversal_mode = '0;
      method Bit#(1) link_gen2_capable = '0;
      method Bit#(1) link_partner_gen2_supported = '0;
      method Bit#(1) link_upcfg_capable = '0;
      method Bit#(1) sel_link_rate = '0;
      method Bit#(2) sel_link_width = '0;
      method Bit#(6) ltssm_state = '0;
      method Action directed_link_auton(Bit#(1) i);
      endmethod
      method Action directed_link_change(Bit#(2) i);
      endmethod
      method Action directed_link_speed(Bit#(1) i);
      endmethod
      method Action directed_link_width(Bit#(2) i);
      endmethod
      method Action upstream_prefer_deemph(Bit#(1) i);
      endmethod
      method Bit#(1) received_hot_rst = 0;
   endinterface

endmodule

`endif // SIMULATION_TEST

`ifndef SIMULATION_TEST
(* synthesize *) // cannot have a synthesis boundary in Bluesim (dynamic module arguments)
`endif
module mkBridge_16_32#( Bit#(64)  board_content_id
                      , PciId     my_id
                      , UInt#(13) max_read_req_bytes
                      , UInt#(13) max_payload_bytes
                      , UInt#(8)  read_completion_boundary
                      )
                      (PCIEtoBNoC#(16,32));
   let _bridge <- mkPCIEtoBNoC(board_content_id, my_id, max_read_req_bytes, max_payload_bytes, read_completion_boundary);
   return _bridge;
endmodule


(* synthesize *)
module mkOCB_16_128_16_32(OnChipBuffer#(UInt#(16),Bit#(128),16,32));
   Clock clk <- exposeCurrentClock();
   Reset rst <- exposeCurrentReset();
   let _ocb <- mkOnChipBuffer(clk, rst, clk, rst);
   return _ocb;
endmodule

(* synthesize, default_clock_osc="CLK", default_reset="RST", clock_prefix="", reset_prefix="" *)
module mkTop#(Clock pci_sys_clk_p, Clock pci_sys_clk_n, Reset pci_sys_rstn)
             (FPGA);

   // access clock and reset
   Clock fpga_clk  <- exposeCurrentClock();
   Reset fpga_rst  <- exposeCurrentReset();

`ifdef SIMULATION_TEST

   // no PLL needed for simulation
   Clock clk = fpga_clk;
   Reset rstn <- mkAsyncReset(4,fpga_rst,clk);

   // instantiate a dummy PCIe endpoint for testing
   PCIExpressV6#(8) ep <- mkPCIETest();

`else

   // invert reset to active low
   Reset fpga_rstn <- mkResetInverter(fpga_rst);

   // put the clock through a PLL and synchronize the reset
   ClockGeneratorParams clk_params = defaultValue();
   clk_params.feedback_mul = 12;
   clk_params.clk0_div = 12;
   clk_params.clkin_buffer = False;
   ClockGenerator clk_gen <- mkClockGenerator(clk_params, reset_by fpga_rstn);
   Clock clk = clk_gen.clkout0;
   Reset rstn <- mkAsyncReset(4,fpga_rstn,clk);

   // combine LVDS clocks from FPGA boundary
   Clock sys_clk_buf <- mkClockIBUFDS_GTXE1(True, pci_sys_clk_p, pci_sys_clk_n);

   // instantiate a PCIE endpoint
   PCIEParams pcie_params = defaultValue();
   PCIExpressV6#(8) ep <- mkPCIExpressEndpointV6(pcie_params, clocked_by sys_clk_buf, reset_by pci_sys_rstn);

`endif // SIMULATION_TEST

   // extract the clocks and resets from the endpoint
   Clock epClock250  = ep.trn.clk;
   Reset epReset250 <- mkAsyncReset(4, ep.trn.reset_n, epClock250);
   Clock epClock125  = ep.trn.clk2;
   Reset epReset125 <- mkAsyncReset(4, ep.trn.reset_n, epClock125);

   // tie off some portions of the endpoint interface
   mkTieOff(ep.cfg);
   mkTieOff(ep.cfg_err);
   mkTieOff(ep.pl);

   // note our PCI ID
   PciId my_id = PciId { bus:  ep.cfg.bus_number()
                       , dev:  ep.cfg.device_number()
                       , func: ep.cfg.function_number()
                       };

   // instantiate controllers for the interactive elements on the board

   DIPSwitch#(8) dip_switch <- mkDIPSwitch(fpga_clk, clocked_by clk, reset_by rstn);

   LEDController led0 <- mkLEDController(False, clocked_by epClock125, reset_by epReset125);
   LEDController led1 <- mkLEDController(False, clocked_by epClock125, reset_by epReset125);
   LEDController led2 <- mkLEDController(False, clocked_by epClock125, reset_by epReset125);
   LEDController led3 <- mkLEDController(False, clocked_by epClock125, reset_by epReset125);

   Vector#(8,LEDController) led_ctrls;
   led_ctrls[0] = led0;
   led_ctrls[1] = led1;
   led_ctrls[2] = led2;
   led_ctrls[3] = led3;
   led_ctrls[4] <- mkLEDController(False, clocked_by clk, reset_by rstn);
   led_ctrls[5] <- mkLEDController(False, clocked_by clk, reset_by rstn);
   led_ctrls[6] <- mkLEDController(False, clocked_by clk, reset_by rstn);
   led_ctrls[7] <- mkLEDController(False, clocked_by clk, reset_by rstn);

   LCDController lcd_ctrl <- mkLCDController(clocked_by clk, reset_by rstn);

   ButtonController left_button   <- mkButtonController(fpga_clk, clocked_by clk, reset_by rstn);
   ButtonController right_button  <- mkButtonController(fpga_clk, clocked_by clk, reset_by rstn);
   ButtonController top_button    <- mkButtonController(fpga_clk, clocked_by clk, reset_by rstn);
   ButtonController bottom_button <- mkButtonController(fpga_clk, clocked_by clk, reset_by rstn);
   ButtonController center_button <- mkButtonController(fpga_clk, clocked_by clk, reset_by rstn);

   LEDController left_led_ctrl   <- mkLEDController(False, clocked_by clk, reset_by rstn);
   LEDController right_led_ctrl  <- mkLEDController(False, clocked_by clk, reset_by rstn);
   LEDController top_led_ctrl    <- mkLEDController(False, clocked_by clk, reset_by rstn);
   LEDController bottom_led_ctrl <- mkLEDController(False, clocked_by clk, reset_by rstn);
   LEDController center_led_ctrl <- mkLEDController(False, clocked_by clk, reset_by rstn);

   //
   // main body of design
   //

   // initialization of LCD and LED controllers

   Reg#(Bool) needs_init  <- mkReg(True, clocked_by clk, reset_by rstn);
   Reg#(Bool) needs_init2 <- mkReg(True, clocked_by epClock125, reset_by epReset125);

   rule init_in_clk_dom if (needs_init);
      Vector#(2,Bit#(8))  logo_top = lcdLogoTop();
      Vector#(14,Bit#(8)) text1    = take(lcdLine(" Bluespec"));
      Vector#(2,Bit#(8))  logo_bot = lcdLogoBottom();
      Vector#(14,Bit#(8)) text2    = take(lcdLine(" NoC Test"));

      lcd_ctrl.setLine1(append(logo_top,text1));
      lcd_ctrl.setLine2(append(logo_bot,text2));

      for (Integer i = 4; i < 8; i = i + 1) begin
         led_ctrls[i].setPeriod(led_off, 1000, led_off, 1000);
      end

      left_led_ctrl.setPeriod(led_off, 1000, led_off, 1000);
      right_led_ctrl.setPeriod(led_off, 1000, led_off, 1000);
      top_led_ctrl.setPeriod(led_off, 1000, led_off, 1000);
      bottom_led_ctrl.setPeriod(led_off, 1000, led_off, 1000);
      center_led_ctrl.setPeriod(led_off, 1000, led_off, 1000);

      needs_init <= False;
   endrule

   rule init_in_ep125_dom if (needs_init2);
      led_ctrls[0].setPeriod(led_off, 500, led_on_max, 500);
      led_ctrls[1].setLag(no_lag);
      led_ctrls[1].setActivity(10);
      led_ctrls[2].setLag(no_lag);
      led_ctrls[2].setActivity(10);
      led_ctrls[3].setPeriod(led_off, 100, led_off, 100);
      needs_init2 <= False;
   endrule

   // extract some status info from the PCIE endpoint these values are
   // all in the epClock250 domain, so we have to cross them into the
   // epClock125 domain

   Bool link_is_up = ep.trn.link_up();
   UInt#(13) max_read_req_bytes_250       = 128 << ep.cfg.dcommand[14:12];
   UInt#(13) max_payload_bytes_250        = 128 << ep.cfg.dcommand[7:5];
   UInt#(8)  read_completion_boundary_250 = 64 << ep.cfg.lcommand[3];

   CrossingReg#(UInt#(13)) max_rd_req_cr  <- mkNullCrossingReg(epClock125, 128, clocked_by epClock250, reset_by epReset250);
   CrossingReg#(UInt#(13)) max_payload_cr <- mkNullCrossingReg(epClock125, 128, clocked_by epClock250, reset_by epReset250);
   CrossingReg#(UInt#(8))  rcb_cr         <- mkNullCrossingReg(epClock125, 128, clocked_by epClock250, reset_by epReset250);

   (* fire_when_enabled, no_implicit_conditions *)
   rule cross_config_values;
      max_rd_req_cr  <= max_read_req_bytes_250;
      max_payload_cr <= max_payload_bytes_250;
      rcb_cr         <= read_completion_boundary_250;
   endrule

   UInt#(13) max_read_req_bytes       = max_rd_req_cr.crossed();
   UInt#(13) max_payload_bytes        = max_payload_cr.crossed();
   UInt#(8)  read_completion_boundary = rcb_cr.crossed();

   // manage PCIe interrupts (MSI only)

   CrossingReg#(Bool) intr_on <- mkNullCrossingReg( epClock125
                                                  , False
                                                  , clocked_by epClock250
                                                  , reset_by epReset250
                                                  );
   SyncPulseIfc       do_intr <- mkSyncPulse(epClock125, epReset125, epClock250);

   Reg#(Bool) intr_active <- mkReg(False, clocked_by epClock250, reset_by epReset250);

   // this rule executes in the epClock250 domain
   (* fire_when_enabled, no_implicit_conditions *)
   rule intr_ifc_ctl;
      ep.cfg_interrupt.di('0);        // only one MSI vector
      ep.cfg_interrupt.assert_n('1);  // don't use legacy interrupts
      ep.cfg_interrupt.req_n(intr_active ? 0 : 1);
      intr_on <= (ep.cfg_interrupt.msienable()  == 1)
              && (ep.cfg_interrupt.mmenable()   == 3'b000)
              && (ep.cfg_interrupt.msixenable() == 0)
              && (ep.cfg.command[2]             == 1); // bus master enable required for MSI
   endrule: intr_ifc_ctl

   // this rule executes in the epClock250 domain
   (* fire_when_enabled, no_implicit_conditions *)
   rule update_intr_status;
      if (intr_active && (ep.cfg_interrupt.rdy_n() == 0))
         intr_active <= False;
      else if (do_intr.pulse())
         intr_active <= True;
   endrule

   // this value is in the epClock125 domain and indicates that the
   // interrupt interface is properly configured to send interrupts
   Bool intr_ok = intr_on.crossed();

   // instantiate the TLP-to-BNoC bridge and connect the PCIe endpoint
   // to it
   PCIEtoBNoC#(16,32) bridge <- mkBridge_16_32( 64'hc001_cafe_f00d_d00d
                                              , my_id
                                              , max_read_req_bytes
                                              , max_payload_bytes
                                              , read_completion_boundary
                                              , clocked_by epClock125, reset_by epReset125
                                              );
   mkConnectionWithClocks(ep.trn_rx, tpl_2(bridge.tlps), epClock250, epReset250, epClock125, epReset125);
   mkConnectionWithClocks(ep.trn_tx, tpl_1(bridge.tlps), epClock250, epReset250, epClock125, epReset125);

   // Instantiate an OnChipBuffer as a target for now
   OnChipBuffer#(UInt#(16),Bit#(128),16,32) ocb <- mkOCB_16_128_16_32(clocked_by epClock125, reset_by epReset125);

   // Connect the bridge directly to the buffer
   mkConnection(bridge.noc, ocb.noc);

   // flash LED 0 when link down, hold it on when link up

   Reg#(Bool) prev_link_up <- mkReg(False, clocked_by epClock125, reset_by epReset125);

   (* fire_when_enabled, no_implicit_conditions *)
   rule pcie_status_led if (link_is_up != prev_link_up);
      led_ctrls[0].setPeriod(link_is_up ? led_on_max : led_off, 500, led_on_max, 500);
      prev_link_up <= link_is_up;
   endrule

   // turn LED 1 on when interrupts are properly enabled

   Reg#(Bool) prev_intr_ok <- mkReg(False, clocked_by epClock125, reset_by epReset125);

   (* fire_when_enabled, no_implicit_conditions *)
   rule intr_config_ok if (intr_ok != prev_intr_ok);
      if (intr_ok)
         led_ctrls[1].setPeriod(led_on_max, 100, led_on_max, 100);
      else
         led_ctrls[1].setPeriod(led_off, 100, led_off, 100);
      prev_intr_ok <= intr_ok;
   endrule

   // strobe LED 2 on rx_activity
   (* fire_when_enabled, no_implicit_conditions *)
   rule rx_activity_strobe if (bridge.rx_activity());
      led_ctrls[2].bump();
   endrule

   // strobe LED 3 on tx_activity
   (* fire_when_enabled, no_implicit_conditions *)
   rule tx_activity_strobe if (bridge.tx_activity());
      led_ctrls[3].bump();
   endrule

   // FPGA pin interface

   interface DIP      dip        = dip_switch.ifc;
   interface LED      leds       = combineLEDs(led_ctrls);
   interface LCD      lcd        = lcd_ctrl.ifc;
   interface Button   left       = left_button.ifc;
   interface Button   right      = right_button.ifc;
   interface Button   top        = top_button.ifc;
   interface Button   bottom     = bottom_button.ifc;
   interface Button   center     = center_button.ifc;
   interface LED      left_led   = left_led_ctrl.ifc;
   interface LED      right_led  = right_led_ctrl.ifc;
   interface LED      top_led    = top_led_ctrl.ifc;
   interface LED      bottom_led = bottom_led_ctrl.ifc;
   interface LED      center_led = center_led_ctrl.ifc;
   interface PCIE_EXP pcie       = ep.pcie;

endmodule
