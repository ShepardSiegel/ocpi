`timescale 1 ps / 1 ps 
//-----------------------------------------------------------------------------
// Title         : PCI Express PIPE PHY single direction connector
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_pipe_xtx2yrx.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This function provides a single direction connection from the "X" side
// transmitter to the "Y" side receiver.  
//-----------------------------------------------------------------------------
// Copyright (c) 2005 Altera Corporation. All rights reserved.  Altera products are
// protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
// other intellectual property laws.  
//
// This reference design file, and your use thereof, is subject to and governed by
// the terms and conditions of the applicable Altera Reference Design License Agreement.
// By using this reference design file, you indicate your acceptance of such terms and
// conditions between you and Altera Corporation.  In the event that you do not agree with
// such terms and conditions, you may not use the reference design file. Please promptly
// destroy any copies you have made.
//
// This reference design file being provided on an "as-is" basis and as an accommodation 
// and therefore all warranties, representations or guarantees of any kind 
// (whether express, implied or statutory) including, without limitation, warranties of 
// merchantability, non-infringement, or fitness for a particular purpose, are 
// specifically disclaimed.  By making this reference design file available, Altera
// expressly does not recommend, suggest or require that this reference design file be
// used in combination with any other product not provided by Altera.
//-----------------------------------------------------------------------------
module altpcietb_pipe_xtx2yrx (X_lane_conn, Y_lane_conn, pclk, resetn, pipe_mode, X_txdata, X_txdatak, X_txdetectrx, X_txelecidle, X_txcompl, X_rxpolarity, X_powerdown, X_rxdata, X_rxdatak, X_rxvalid, X_phystatus, X_rxelecidle, X_rxstatus, X2Y_data, X2Y_datak, X2Y_elecidle, Y2X_data, Y2X_datak, Y2X_elecidle,X_rate);

parameter XPIPE_WIDTH  = 16;
parameter YPIPE_WIDTH  = 16;
parameter LANE_NUM  = 0;
parameter X_MAC_NAME  = "EP";
`include "altpcietb_bfm_log.v"

input 	  X_lane_conn; 
input 	  Y_lane_conn; 
input 	  pclk; 
input 	  resetn; 
input 	  pipe_mode; 
input [XPIPE_WIDTH - 1:0] X_txdata; 
input [(XPIPE_WIDTH / 8) - 1:0] X_txdatak; 
input 				X_txdetectrx; 
input 				X_txelecidle; 
input 				X_txcompl;
input 				X_rate; 
input 				X_rxpolarity; 
input [1:0] 			X_powerdown; 
output [XPIPE_WIDTH - 1:0] 	X_rxdata; 
reg [XPIPE_WIDTH - 1:0] 	X_rxdata;
output [(XPIPE_WIDTH / 8) - 1:0] X_rxdatak; 
reg [(XPIPE_WIDTH / 8) - 1:0] 	 X_rxdatak;
output 				 X_rxvalid; 
reg 				 X_rxvalid;
output 				 X_phystatus; 
reg 				 X_phystatus;
output 				 X_rxelecidle; 
reg 				 X_rxelecidle;
output [2:0] 			 X_rxstatus; 
reg [2:0] 			 X_rxstatus;
output [YPIPE_WIDTH - 1:0] 	 X2Y_data; 
reg [YPIPE_WIDTH - 1:0] 	 X2Y_data;
output [(YPIPE_WIDTH / 8) - 1:0] X2Y_datak; 
reg [(YPIPE_WIDTH / 8) - 1:0] 	 X2Y_datak;
output 				 X2Y_elecidle; 
reg 				 X2Y_elecidle;
input [YPIPE_WIDTH - 1:0] 	 Y2X_data; 
input [(YPIPE_WIDTH / 8) - 1:0]  Y2X_datak; 
input 				 Y2X_elecidle; 

parameter [3:0] 		 P0 = 0; 
parameter [3:0] 		 P0_ENT = 1; 
parameter [3:0] 		 P0s = 2; 
parameter [3:0] 		 P0s_ENT = 3; 
parameter [3:0] 		 P1 = 4; 
parameter [3:0] 		 P1_DET = 5; 
parameter [3:0] 		 P1_ENT = 10; 
parameter [3:0] 		 P2 = 11; 
parameter [3:0] 		 P2_ENT = 12; 
parameter [3:0] 		 NOT_IN_USE = 13; 
reg [3:0] 			 phy_state; 
reg 				 resetn_q1; 
reg 				 resetn_q2; 
reg 				 count; 
reg 				 sync; 

reg [YPIPE_WIDTH - 1:0] 	 X_txdata_y; 
reg [(YPIPE_WIDTH / 8) - 1:0] 	 X_txdatak_y; 
reg [YPIPE_WIDTH - 1:0] 	 X_rxdata_y;
reg [YPIPE_WIDTH - 1:0] 	 X_rxdata_y_tmp; 
reg [(YPIPE_WIDTH / 8) - 1:0] 	 X_rxdatak_y; 
reg [7:0] 			 X_txdata_tmp; 
reg 				 X_txdatak_tmp; 
reg [3:0] 			 detect_cnt;

reg 				 dummy ;
reg 				 X_rate_r;

initial
  begin
  phy_state <= P1;
  resetn_q1 <= 1'b0;
  resetn_q2 <= 1'b1;
  count <= 1'b0;
  sync <= 1'b0;
  end



//        -----------------------------------------------------------------------
//        -- The assumption of the logic below is that pclk will run 2x the speed
//        -- of the incoming data. The count signal needs to be 0 on the 1st
//        -- cycle and 1 on the 2nd cycle
//
//        -- Hdata16         BB  BB  DD  DD
//        -- Ldata16         AA  AA  CC  CC
//        -- count            0   1   0   1
//        -- data8                AA  BB  CC etc..
//
//        -----------------------------------------------------------------------

generate if (XPIPE_WIDTH < YPIPE_WIDTH) //  X(8) => Y (16)
  always @(pclk)
    begin : conversion_8to16
    if (pclk == 1'b1)
      begin
      X_rxdata_y_tmp <= X_rxdata_y;

      if (sync == 1'b1)
        begin
        count <= ~count ; 
        end
      else if (sync == 1'b0 & (X_rxdata_y_tmp == X_rxdata_y) & 
	       ((X_rxdatak_y[0] == 1'b1) || (X_rxdatak_y[1] == 1'b1)))
        begin
        count <= 1'b0 ; 
        sync <= 1'b1 ; 
        end 
      if (count == 1'b0)
        begin
        X_txdata_tmp <= X_txdata ; 
        X_txdatak_tmp <= X_txdatak[0] ; 
        X_rxdata <= X_rxdata_y[7:0] ; 
        X_rxdatak <= X_rxdatak_y[0:0] ; 
        end
      else
        begin
        X_txdata_y <= {X_txdata, X_txdata_tmp} ; 
        X_txdatak_y <= {X_txdatak[0:0], X_txdatak_tmp} ; 
        X_rxdata <= X_rxdata_y[15:8] ; 
        X_rxdatak <= X_rxdatak_y[1:1] ; 
        end 
      end 
    end
endgenerate

generate if (XPIPE_WIDTH == YPIPE_WIDTH) //  direct mapping

  always @(pclk)
    begin: direct_map
    X_txdata_y  <= X_txdata;
    X_txdatak_y <= X_txdatak;
    X_rxdata    <= X_rxdata_y;
    X_rxdatak   <= X_rxdatak_y;
    end
endgenerate

always @(pclk)
  begin : reset_pipeline
  if (pclk == 1'b1)
    begin
    resetn_q2 <= resetn_q1 ; 
    resetn_q1 <= resetn ; 
    end 
  end 



   always @(pclk)
   begin : main_ctrl
      if (pclk == 1'b1)
      begin
         if ((resetn == 1'b0) | (resetn_q1 == 1'b0) | (resetn_q2 == 1'b0) | (X_lane_conn == 1'b0))
         begin
            if ((resetn == 1'b0) & (resetn_q1 == 1'b0) & (resetn_q2 == 1'b0) & (X_lane_conn == 1'b1))
            begin
               if (X_txdetectrx == 1'b1)
               begin
                  dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"TxDetectRx/Loopback not deasserted while reset asserted, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
               end 
               if (X_txdetectrx == 1'b1)
               begin
                  dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"TxDetectRx/Loopback not deasserted while reset asserted, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
               end 
               if (X_txelecidle == 1'b0)
               begin
                  dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"TxElecIdle not asserted while reset asserted, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
               end 
               if (X_txcompl == 1'b1)
               begin
                  dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"TxCompliance not deasserted while reset asserted, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
               end 
               if (X_rxpolarity == 1'b1)
               begin
                  dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"RxPolarity not deasserted while reset asserted, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
               end 
               if ((X_powerdown == 2'b00) | (X_powerdown == 2'b01) | (X_powerdown == 2'b11))
               begin
                  dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Powerdown not P1 while reset asserted, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
               end 
            end 
            if (pipe_mode == 1'b1)
            begin
               phy_state <= P1_ENT ; 
            end
            else
            begin
               phy_state <= NOT_IN_USE ; 
            end
            if (X_lane_conn == 1'b1)
              X_phystatus <= 1'b1 ;
            else
              X_phystatus <= X_txdetectrx ;
            X_rxvalid <= 1'b0 ; 
            X_rxelecidle <= 1'b1 ; 
            X_rxstatus <= 3'b100 ;
         X_rate_r <= 1'b0;
            X2Y_elecidle <= 1'b1 ; 
         end
         else
           begin
           X_rate_r <= X_rate;
            case (phy_state)
               P0, P0_ENT :
                        begin
                           X2Y_elecidle <= X_txelecidle ; 
                           if (phy_state == P0_ENT)
                           begin
                              X_phystatus <= 1'b1 ; 
                           end
                           else
                           begin
                           if (X_rate != X_rate_r)
			     X_phystatus <= 1'b1;
			  else
			    X_phystatus <= 1'b0;
			   end

                           case (X_powerdown)
                              2'b00 :
                                       begin
                                          phy_state <= P0 ; 
                                       end
                              2'b01 :
                                       begin
                                          phy_state <= P0s_ENT ; 
                                       end
                              2'b10 :
                                       begin
                                          phy_state <= P1_ENT ; 
                                       end
                              2'b11 :
                                       begin
                                          phy_state <= P2_ENT ; 
                                       end
                              default :
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Illegal value of powerdown in P0 state, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                                       end
                           endcase 
                           X_rxelecidle <= Y2X_elecidle ; 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxstatus <= 3'b100 ; 
                              X_rxvalid <= 1'b0 ; 
                           end
                           else
                           begin
                              X_rxstatus <= 3'b000 ; 
                              X_rxvalid <= 1'b1 ; 
                           end 
                        end
               P0s, P0s_ENT :
                        begin
                           X2Y_elecidle <= 1'b1 ; 
                           if (X_txelecidle != 1'b1)
                           begin
                              dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Txelecidle not asserted in P0s state, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                           end 
                           if (phy_state == P0s_ENT)
                           begin
                              X_phystatus <= 1'b1 ; 
                           end
                           else
                           begin
                              X_phystatus <= 1'b0 ; 
                           end 
                           case (X_powerdown)
                              2'b00 :
                                       begin
                                          phy_state <= P0 ; 
                                       end
                              2'b01 :
                                       begin
                                          phy_state <= P0s ; 
                                       end
                              default :
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Illegal value of powerdown in P0 state, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                                       end
                           endcase 
                           X_rxelecidle <= Y2X_elecidle ; 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxstatus <= 3'b100 ; 
                              X_rxvalid <= 1'b0 ; 
                           end
                           else
                           begin
                              X_rxstatus <= 3'b000 ; 
                              X_rxvalid <= 1'b1 ; 
                           end 
                        end
               P1, P1_ENT :
                        begin
                           X2Y_elecidle <= 1'b1 ; 
                           if (X_txelecidle != 1'b1)
                           begin
                              dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Txelecidle not asserted in P1 state, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                           end 
                           if (phy_state == P1_ENT)
                           begin
                              X_phystatus <= 1'b1 ; 
                           end
                           else
                           begin
                              X_phystatus <= 1'b0 ; 
                           end 
                           case (X_powerdown)
                              2'b00 :
                                       begin
                                          phy_state <= P0_ENT ; 
                                       end
                              2'b10 :
                                       begin
                                          if (X_txdetectrx == 1'b1)
                                          begin
                                             phy_state <= P1_DET ;
					  detect_cnt <= 4'h4;
                                          end
                                          else
                                          begin
                                             phy_state <= P1 ; 
                                          end 
                                       end
                              default :
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Illegal value of powerdown in P1 state, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                                       end
                           endcase 
                           X_rxelecidle <= Y2X_elecidle ; 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxstatus <= 3'b100 ; 
                              X_rxvalid <= 1'b0 ; 
                           end
                           else
                           begin
                              X_rxstatus <= 3'b000 ; 
                              X_rxvalid <= 1'b1 ; 
                           end 
                        end
            P1_DET :
                        begin
                           if (X_powerdown != 2'b10)
                           begin
                              dummy = ebfm_display(EBFM_MSG_WARNING, {"WARNING: Tried to move out of P1 state in middle of Rx Detect, ignoring, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                           end

			if (detect_cnt > 4'h0)
			  detect_cnt <= detect_cnt - 1;

                           if (detect_cnt == 4'h1)
                           begin
                              X_phystatus <= 1'b1 ; 
                              if (Y_lane_conn == 1'b1)
                              begin
                                 X_rxstatus <= 3'b011 ; 
                              end
                              else
                              begin
                                 if (Y2X_elecidle == 1'b1)
                                 begin
                                    X_rxstatus <= 3'b100 ; 
                                 end
                                 else
                                 begin
                                    X_rxstatus <= 3'b000 ; 
                                 end 
                              end 
                           end
                           else
                           begin
                              X_phystatus <= 1'b0 ; 
                              X_rxstatus <= 3'b000 ; 
                           end
			if (X_txdetectrx == 1'b0)
			  phy_state <= P1;
                           X_rxelecidle <= Y2X_elecidle ; 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxvalid <= 1'b0 ; 
                           end
                           else
                           begin
                              X_rxvalid <= 1'b1 ; 
                           end 
                        end
               P2, P2_ENT :
                        begin
                           if (phy_state == P2_ENT)
                           begin
                              X_phystatus <= 1'b1 ; 
                           end
                           else
                           begin
                              X_phystatus <= 1'b0 ; 
                           end 
                           X_rxvalid <= 1'b0 ; 
                           X_rxstatus <= 3'b100 ; 
                           X_rxelecidle <= Y2X_elecidle ; 
                           X2Y_elecidle <= X_txelecidle ; 
                           case (X_powerdown)
                              2'b11 :
                                       begin
                                          phy_state <= P2 ; 
                                       end
                              2'b10 :
                                       begin
                                          phy_state <= P1_ENT ; 
                                       end
                              default :
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, {"Illegal value of powerdown in P2 state, Lane: ", dimage1(LANE_NUM), ", MAC: ", X_MAC_NAME}); 
                                       end
                           endcase 
                        end
               NOT_IN_USE :
                        begin
                           X_phystatus <= 1'b0 ; 
                           X_rxvalid <= 1'b0 ; 
                           X_rxstatus <= 3'b100 ; 
                           X_rxelecidle <= Y2X_elecidle ; 
                           X2Y_elecidle <= X_txelecidle ; 
                           phy_state <= NOT_IN_USE ; 
                        end
            endcase 
         end 
      end 
   end 

   always @(pclk)
   begin : main_data
   if ((resetn == 1'b0) | (resetn_q1 == 1'b0) | (resetn_q2 == 1'b0) | (X_lane_conn == 1'b0))
     begin
            X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
            X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
            X2Y_data <= {YPIPE_WIDTH{1'bz}} ; 
            X2Y_datak <= {YPIPE_WIDTH{1'bz}} ;

         end
         else
         begin
            case (phy_state)
               P0, P0_ENT :
                        begin
                           if (X_txelecidle == 1'b0)
                           begin
                              if (X_txdetectrx == 1'b1)
                              begin
                                 X2Y_data <= Y2X_data ; 
                                 X2Y_datak <= Y2X_datak ; 
                              end
                              else
                              begin
                                 X2Y_data <= X_txdata_y ; 
                                 X2Y_datak <= X_txdatak_y ; 
                              end 
                           end
                           else
                           begin
                              X2Y_data <= {YPIPE_WIDTH{1'bz}} ; 
                              X2Y_datak <= {YPIPE_WIDTH{1'bz}} ; 
                           end 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
                              X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
                           end
                           else
                           begin
                              X_rxdatak_y <= Y2X_datak ; 
                              X_rxdata_y <= Y2X_data ; 
                           end 
                        end
               P0s, P0s_ENT :
                        begin
                           X2Y_data <= {YPIPE_WIDTH{1'bz}} ; 
                           X2Y_datak <= {YPIPE_WIDTH{1'bz}} ; 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
                              X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
                           end
                           else
                           begin
                              X_rxdatak_y <= Y2X_datak ; 
                              X_rxdata_y <= Y2X_data ; 
                           end 
                        end
               P1, P1_ENT :
                        begin
                           X2Y_data <= {YPIPE_WIDTH{1'bz}} ; 
                           X2Y_datak <= {YPIPE_WIDTH{1'bz}} ; 
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
                              X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
                           end
                           else
                           begin
                              X_rxdatak_y <= Y2X_datak ; 
                              X_rxdata_y <= Y2X_data ; 
                           end 
                        end
            P1_DET :
                        begin
                           if (Y2X_elecidle == 1'b1)
                           begin
                              X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
                              X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
                           end
                           else
                           begin
                              X_rxdatak_y <= Y2X_datak ; 
                              X_rxdata_y <= Y2X_data ; 
                           end 
                        end
               P2, P2_ENT :
                        begin
                           X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
                           X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
                           X2Y_datak <= {YPIPE_WIDTH{1'bz}} ; 
                           X2Y_data <= {YPIPE_WIDTH{1'bz}} ; 
                        end
               NOT_IN_USE :
                        begin
                           X_rxdata_y <= {YPIPE_WIDTH{1'bz}} ; 
                           X_rxdatak_y <= {YPIPE_WIDTH{1'bz}} ; 
                           X2Y_datak <= {YPIPE_WIDTH{1'bz}} ; 
                           X2Y_data <= {YPIPE_WIDTH{1'bz}} ; 
                        end
            endcase 
         end 
   end 
endmodule
