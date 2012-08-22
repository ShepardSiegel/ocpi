`timescale 1 ps / 1 ps
//-----------------------------------------------------------------------------
// Title         : PCI Express BFM Root Port VC Interface
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_bfm_vc_intf.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This entity interfaces between the root port transaction list processor
// and the root port module single VC interface. It handles the following basic
// functions:
// * Formating Tx Descriptors 
// * Retrieving Tx Data as needed from the shared memory
// * Decoding Rx Descriptors 
// * Storing Rx Data as needed to the shared memory
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
module altpcietb_bfm_vc_intf (clk_in, rstn, rx_req, rx_ack, rx_abort, rx_retry, rx_mask, rx_desc, rx_ws, rx_data, rx_be, rx_dv, rx_dfr, tx_cred, tx_req, tx_desc, tx_ack, tx_dfr, tx_data, tx_dv, tx_err, tx_ws, cfg_io_bas, cfg_np_bas, cfg_pr_bas);

   parameter VC_NUM  = 0;
   parameter DISABLE_RX_BE_CHECK  = 1;
   `include "altpcietb_bfm_constants.v"
   `include "altpcietb_bfm_log.v"
   `include "altpcietb_bfm_shmem.v"
   `include "altpcietb_bfm_req_intf.v"

   input clk_in; 
   input rstn; 
   input rx_req; 
   output rx_ack; 
   reg rx_ack;
   output rx_abort; 
   reg rx_abort;
   output rx_retry; 
   reg rx_retry;
   output rx_mask; 
   reg rx_mask;
   input[135:0] rx_desc; 
   output rx_ws; 
   reg rx_ws;
   input[63:0] rx_data; 
   input[7:0] rx_be; 
   input rx_dv; 
   input rx_dfr; 
   input[21:0] tx_cred; 
   output tx_req; 
   reg tx_req;
   output[127:0] tx_desc; 
   reg[127:0] tx_desc;
   input tx_ack; 
   output tx_dfr; 
   reg tx_dfr;
   output[63:0] tx_data; 
   reg[63:0] tx_data;
   output tx_dv; 
   reg tx_dv;
   output tx_err; 
   reg tx_err;
   input tx_ws; 
   input[19:0] cfg_io_bas; 
   input[11:0] cfg_np_bas; 
   input[43:0] cfg_pr_bas; 

   parameter[2:0] RXST_IDLE = 0; 
   parameter[2:0] RXST_DESC_ACK = 1; 
   parameter[2:0] RXST_DATA_WRITE = 2; 
   parameter[2:0] RXST_DATA_NONP_WRITE = 3; 
   parameter[2:0] RXST_DATA_COMPL = 4; 
   parameter[2:0] RXST_NONP_REQ = 5; 
   parameter[1:0] TXST_IDLE = 0; 
   parameter[1:0] TXST_DESC = 1; 
   parameter[1:0] TXST_DATA = 2; 
   reg[2:0] rx_state; 
   reg[1:0] tx_state; 
   // Communication signals between main Tx State Machine and main Rx State Machine
   // to indicate when completions are expected
   integer exp_compl_tag; 
   integer exp_compl_bcount; 
   // Communication signals between Rx State Machine and Tx State Machine
   // for requesting completions
   reg rx_tx_req; 
   reg[127:0] rx_tx_desc; 
   integer rx_tx_shmem_addr; 
   integer rx_tx_bcount; 
   reg[7:0] rx_tx_byte_enb; 
   reg tx_rx_ack; 

   // Communication Signals for PErf Monitoring
   reg tx_dv_last;
   reg tx_req_int;
   reg rx_ws_int;
   reg rx_ack_int;

   function [0:0] is_request;
      input[135:0] rx_desc; 

      reg dummy ;
      
      begin
         case (rx_desc[124:120])
            5'b00000 :
                     begin
                        is_request = 1'b1; // Memory Read or Write
                     end
            5'b00010 :
                     begin
                        is_request = 1'b1; // I/O Read or Write
                     end
            5'b01010 :
                     begin
                        is_request = 1'b0; // Completion
                     end
            default :
                     begin
                        // "00001" Memory Read Locked
                        // "00100" Config Type 0 Read or Write
                        // "00101" Config Type 1 Read or Write
                        // "10rrr" Message (w/Data)
                        // "01011" Completion Locked
                        dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                     {"Root Port VC", dimage1(VC_NUM), 
                                      " Recevied unsupported TLP, Fmt/Type: ", himage2(rx_desc[127:120])}); 
                        is_request = 1'b0; 
                     end
         endcase 
      end
   endfunction

   function [0:0] is_non_posted;
      input[127:0] desc; 

      begin
         case (desc[124:120])
            5'b00000 :
                     begin
                        // Memory Read or Write
                        if ((desc[126]) == 1'b0)
                        begin
                           // No Data, Must be non-posted read
                           is_non_posted = 1'b1; 
                        end
                        else
                        begin
                           is_non_posted = 1'b0; 
                        end 
                     end
            5'b00100 :
                     begin
                        is_non_posted = 1'b1; // Config Type 0 Read or Write
                     end
            5'b00101 :
                     begin
                        is_non_posted = 1'b1; // Config Type 1 Read or Write
                     end
            5'b00010 :
                     begin
                        is_non_posted = 1'b1; // I/O Read or Write
                     end
            5'b01010 :
                     begin
                        is_non_posted = 1'b0; // Completion
                     end
            default :
                     begin
                        // "00001" Memory Read Locked
                        // "10rrr" Message (w/Data)
                        // "01011" Completion Locked
                        is_non_posted = 1'b0; 
                     end
         endcase 
      end
   endfunction

   function [0:0] has_data;
      input[127:0] desc; 

      begin
         if ((desc[126]) == 1'b1)
         begin
            has_data = 1'b1; 
         end
         else
         begin
            has_data = 1'b0; 
         end 
      end
   endfunction

   function integer calc_byte_count;
      input[127:0] desc; 

      integer bcount; 

      begin
         // Number of DWords * 4 gives bytes
         bcount = desc[105:96] * 4; 
         if (bcount > 4)
         begin
            if ((desc[71]) == 1'b0)
            begin
               bcount = bcount - 1; 
               if ((desc[70]) == 1'b0)
               begin
                  bcount = bcount - 1; 
                  // If more than 1 DW
                  if ((desc[69]) == 1'b0)
                  begin
                     bcount = bcount - 1; 
                     // Adjust if the last Dword is not full
                     if ((desc[68]) == 1'b0)
                     begin
                        // Handle the case of no bytes in last DW
                        bcount = bcount - 1; 
                     end 
                  end 
               end 
            end 
            if ((desc[64]) == 1'b0)
            begin
               bcount = bcount - 1; 
               if ((desc[65]) == 1'b0)
               begin
                  bcount = bcount - 1; 
                  if ((desc[66]) == 1'b0)
                  begin
                     bcount = bcount - 1; 
                     // Now adjust if the first Dword is not full
                     if ((desc[67]) == 1'b0)
                     begin
                        // Handle the case of no bytes in first DW
                        bcount = bcount - 1; 
                     end 
                  end 
               end 
            end 
         end
         else
         begin
            // Only one DW, need to adjust based on
            // First Byte Enables could be any subset
            if ((desc[64]) == 1'b0)
            begin
               bcount = bcount - 1; 
            end 
            if ((desc[65]) == 1'b0)
            begin
               bcount = bcount - 1; 
            end 
            if ((desc[66]) == 1'b0)
            begin
               bcount = bcount - 1; 
            end 
            if ((desc[67]) == 1'b0)
            begin
               bcount = bcount - 1; 
            end 
         end 
         calc_byte_count = bcount; 
      end
   endfunction

   function [7:0] calc_first_byte_enb;
      input[127:0] desc; 

      reg[7:0] byte_enb; 

      begin
         // calc_first_byte_enb
         if ((((desc[125]) == 1'b1) & ((desc[2]) == 1'b1)) | (((desc[125]) == 1'b0) & ((desc[34]) == 1'b1)))
         begin
            byte_enb = {desc[67:64], 4'b0000}; 
         end
         else
         begin
            byte_enb = {4'b1111, desc[67:64]}; 
         end 
         calc_first_byte_enb = byte_enb; 
      end
   endfunction

   function integer calc_lcl_addr;
      input[135:0] rx_desc; 

      reg[63:0] req_addr; 

      begin
         // We just use the lower bits of the address to for the memory address 
         if ((rx_desc[125]) == 1'b1)
         begin
            // 4 DW Header
            req_addr[63:2] = rx_desc[63:2]; 
         end
         else
         begin
            // 3 DW Header
            req_addr[31:2] = rx_desc[63:34]; 
         end 
         if ((rx_desc[64]) == 1'b1)
         begin
            req_addr[1:0] = 2'b00; 
         end
         else
         begin
            if ((rx_desc[65]) == 1'b1)
            begin
               req_addr[1:0] = 2'b01; 
            end
            else
            begin
               // Calculate Byte Address from Byte Enables
               if ((rx_desc[66]) == 1'b1)
               begin
                  req_addr[1:0] = 2'b10; 
               end
               else
               begin
                  // Last Byte should be enabled (or we are not accessing anything so
                  // it is a don't care)
                  req_addr[1:0] = 2'b11; 
               end 
            end 
         end 
         calc_lcl_addr = req_addr[SHMEM_ADDR_WIDTH - 1:0]; 
      end
   endfunction

   task rx_write_req_setup;
      input[135:0] rx_desc; 
      output addr; 
      integer addr;
      output[7:0] byte_enb; 
      output bcount; 
      integer bcount;

      begin
         addr = calc_lcl_addr(rx_desc); 
         byte_enb = calc_first_byte_enb(rx_desc[127:0]); 
         bcount = calc_byte_count(rx_desc[127:0]); 
      end
   endtask

   task rx_compl_setup;
      input[135:0] rx_desc; 
      output base_addr; 
      integer base_addr;
      output[7:0] byte_enb; 
      output bcount; 
      integer bcount;
      output tag; 
      integer tag;
      output[2:0] status; 

      integer tagi; 
      integer bcounti; 

      begin
         // lcl_compl_addr
         tagi = rx_desc[47:40]; 
         if ((rx_desc[126]) == 1'b1)
         begin
            base_addr = vc_intf_get_lcl_addr(tagi); 
         end
         else
         begin
            base_addr = 2 ** SHMEM_ADDR_WIDTH; 
         end 
         tag = tagi; 
         // Calculate the byte-count from Length field
         bcounti = rx_desc[105:96] * 4; 
         // Calculate the byte-enables from the Lower Address field
         // Also modify the byte count 
         case (rx_desc[34:32])
            3'b111 :
                     begin
                        byte_enb = 8'b10000000; 
                        bcounti = bcounti - 3; 
                     end
            3'b110 :
                     begin
                        byte_enb = 8'b11000000; 
                        bcounti = bcounti - 2; 
                     end
            3'b101 :
                     begin
                        byte_enb = 8'b11100000; 
                        bcounti = bcounti - 1; 
                     end
            3'b100 :
                     begin
                        byte_enb = 8'b11110000; 
                        bcounti = bcounti - 0; 
                     end
            3'b011 :
                     begin
                        byte_enb = 8'b11111000; 
                        bcounti = bcounti - 3; 
                     end
            3'b010 :
                     begin
                        byte_enb = 8'b11111100; 
                        bcounti = bcounti - 2; 
                     end
            3'b001 :
                     begin
                        byte_enb = 8'b11111110; 
                        bcounti = bcounti - 1; 
                     end
            default :
                     begin
                        byte_enb = {8{1'b1}}; 
                        bcounti = bcounti - 0; 
                     end
         endcase 
         // Now if the remaining byte-count from the header is less than that
         // calculated above, that means there are some last data phase
         // byte enables that are not on, update bcounti to reflect that
         if (rx_desc[75:64] < bcounti)
         begin
            bcounti = rx_desc[75:64]; 
         end 
         bcount = bcounti; 
         status = rx_desc[79:77]; 
      end
   endtask


   // Setup the Completion Info for the received request
   task rx_nonp_req_setup_compl;
      input[135:0] rx_desc; 
      output[127:0] rx_tx_desc; 
      output rx_tx_shmem_addr; 
      integer rx_tx_shmem_addr;
      output[7:0] rx_tx_byte_enb; 
      output rx_tx_bcount; 
      integer rx_tx_bcount;

      integer temp_bcount; 
      integer temp_shmem_addr; 

      begin
         temp_shmem_addr = calc_lcl_addr(rx_desc[135:0]); 
         rx_tx_shmem_addr = temp_shmem_addr; 
         rx_tx_byte_enb = calc_first_byte_enb(rx_desc[127:0]); 
         temp_bcount = calc_byte_count(rx_desc[127:0]); 
         rx_tx_bcount = temp_bcount; 
         rx_tx_desc = {128{1'b0}}; 
         rx_tx_desc[126] = ~rx_desc[126]; // Completion Data is opposite of Request
         rx_tx_desc[125] = 1'b0; // FMT bit 0 always 0
         rx_tx_desc[124:120] = 5'b01010; // Completion
         // TC,TD,EP,Attr,Length (and reserved bits) same as request:
         rx_tx_desc[119:96] = rx_desc[119:96]; 
         rx_tx_desc[95:80] = RP_REQ_ID; // Completer ID
         rx_tx_desc[79:77] = 3'b000; // Completion Status
         rx_tx_desc[76] = 1'b0; // Byte Count Modified
         rx_tx_desc[75:64] = temp_bcount; 
         rx_tx_desc[63:48] = rx_desc[95:80]; // Requester ID
         rx_tx_desc[47:40] = rx_desc[79:72]; // Tag
         // Lower Address: 
         rx_tx_desc[38:32] = temp_shmem_addr; 
      end
   endtask

   function [0:0] tx_fc_check;
      input[127:0] desc; 
      input[21:0] cred; 

      integer data_cred; 

      begin
         // tx_fc_check
         case (desc[126:120])
            7'b1000100, 7'b0000100 :
                     begin
                        // Config Write Type 0
                        // Config Read Type 0
                        // Type 0 Config issued to RP get handled internally,
                        // so we can issue even if no Credits
                        tx_fc_check = 1'b1; 
                     end
            7'b0000000, 7'b0100000, 7'b0000010, 7'b0000101 :
                     begin
                        // Memory Read (3DW, 4DW)
                        // IO Read
                        // Config Read Type 1
                        // Non-Posted Request without Data 
                        if ((cred[10]) == 1'b1)
                        begin
                           tx_fc_check = 1'b1; 
                        end
                        else
                        begin
                           tx_fc_check = 1'b0; 
                        end 
                     end
            7'b1000010, 7'b1000101 :
                     begin
                        // IO Write
                        // Config Write Type 1
                        // Non-Posted Request with Data 
                        if (((cred[10]) == 1'b1) & ((cred[11]) == 1'b1))
                        begin
                           tx_fc_check = 1'b1; 
                        end
                        else
                        begin
                           tx_fc_check = 1'b0; 
                        end 
                     end
            7'b1000000, 7'b1100000 :
                     begin
                        if ((cred[0]) == 1'b1)
                        begin
                           data_cred = desc[105:98]; 
                           // Memory Read (3DW, 4DW)
                           // Posted Request with Data
                           if (desc[97:96] != 2'b00)
                           begin
                              data_cred = data_cred + 1; 
                           end 
                           if (data_cred <= cred[9:1])
                           begin
                              tx_fc_check = 1'b1; 
                           end
                           else
                           begin
                              tx_fc_check = 1'b0; 
                           end 
                        end
                        else
                        begin
                           tx_fc_check = 1'b0; 
                        end 
                     end
            default :
                     begin
                        tx_fc_check = 1'b0; 
                     end
         endcase 
      end
   endfunction

   task tx_setup_data;
      input lcl_addr; 
      integer lcl_addr;
      input bcount; 
      integer bcount;
      input[7:0] byte_enb; 
      output[32767:0] data_pkt; 
      output dphases; 
      integer dphases;
      input imm_valid; 
      input[31:0] imm_data; 

      reg [63:0] data_pkt_xhdl ;
      
      integer dphasesi; 
      integer bcount_v; 
      integer lcl_addr_v; 
      integer nb; 
      integer fb; 

      integer i ;
      
      begin
         dphasesi = 0 ;
         // tx_setup_data
         if (imm_valid == 1'b1)
           begin
              lcl_addr_v = 0 ;
           end
         else
           begin
              lcl_addr_v = lcl_addr;
           end 
         bcount_v = bcount; 
         // Setup the first data phase, find the first byte
         begin : xhdl_0
            integer i;
            for(i = 0; i <= 7; i = i + 1)
            begin : byte_loop
               if ((byte_enb[i]) == 1'b1)
               begin
                  fb = i; 
                  disable xhdl_0 ; 
               end 
            end
         end 
         // first data phase figure out number of bytes
         nb = 8 - fb; 
         if (nb > bcount_v)
         begin
            nb = bcount_v; 
         end 
         // first data phase get bytes
         data_pkt_xhdl = {64{1'b0}};
         for (i = 0 ; i < nb ; i = i + 1)
           begin
              if (imm_valid == 1'b1)
                begin
                   data_pkt_xhdl[((fb+i) * 8)+:8] = imm_data[(i*8)+:8]; 
                end
              else
                begin
                   data_pkt_xhdl[((fb+i) * 8)+:8] = shmem_read((lcl_addr_v+i), 1); 
                end
           end 
         data_pkt[(dphasesi*64)+:64] = data_pkt_xhdl;
         bcount_v = bcount_v - nb; 
         lcl_addr_v = lcl_addr_v + nb; 
         dphasesi = dphasesi + 1; 
         // Setup the remaining data phases
         while (bcount_v > 0)
         begin
            data_pkt_xhdl = {64{1'b0}}; 
            if (bcount_v < 8)
            begin
               nb = bcount_v; 
            end
            else
            begin
               nb = 8; 
            end
            for (i = 0 ; i < nb ; i = i + 1 )
              begin
                 if (imm_valid == 1'b1)
                   begin
                      // Offset into remaining immediate data
                      data_pkt_xhdl[(i*8)+:8] = imm_data[(lcl_addr_v + (i*8))+:8]; 
                   end
                 else
                   begin
                      data_pkt_xhdl[(i*8)+:8] = shmem_read(lcl_addr_v + i, 1); 
                   end
              end
            data_pkt[(dphasesi*64)+:64] = data_pkt_xhdl;
            bcount_v = bcount_v - nb; 
            lcl_addr_v = lcl_addr_v + nb; 
            dphasesi = dphasesi + 1; 
         end 
         dphases = dphasesi; 
      end
   endtask

   task tx_setup_req;
      input[127:0] req_desc; 
      input lcl_addr; 
      integer lcl_addr;
      input imm_valid; 
      input[31:0] imm_data; 
      output[32767:0] data_pkt; 
      output dphases; 
      integer dphases;

      integer bcount_v; 
      reg[7:0] byte_enb_v; 

      begin
         // tx_setup_req
         if (has_data(req_desc))
         begin
            bcount_v = calc_byte_count(req_desc); 
            byte_enb_v = calc_first_byte_enb(req_desc); 
            tx_setup_data(lcl_addr, bcount_v, byte_enb_v, data_pkt, dphases, imm_valid, imm_data); 
         end
         else
         begin
            dphases = 0; 
         end 
      end
   endtask

   // behavioral
   always @(clk_in)
   begin : main_rx_state
      integer compl_received_v[0:EBFM_NUM_TAG - 1]; 
      integer compl_expected_v[0:EBFM_NUM_TAG - 1]; 
      reg[2:0] rx_state_v; 
      reg rx_ack_v; 
      reg rx_ws_v; 
      reg rx_abort_v; 
      reg rx_retry_v; 
      integer shmem_addr_v; 
      integer rx_compl_tag_v; 
      reg[SHMEM_ADDR_WIDTH - 1:0] rx_compl_baddr_v; 
      reg[2:0] rx_compl_sts_v; 
      reg[7:0] byte_enb_v; 
      integer bcount_v; 
      reg rx_tx_req_v; 
      reg[127:0] rx_tx_desc_v; 
      integer rx_tx_shmem_addr_v; 
      integer rx_tx_bcount_v; 
      reg[7:0] rx_tx_byte_enb_v;
      reg      dummy ;
      integer      i ;
      if (clk_in == 1'b1)
      begin
         if (rstn != 1'b1)
         begin
            rx_state_v = RXST_IDLE; 
            rx_ack_v = 1'b0; 
            rx_ws_v = 1'b0; 
            rx_abort_v = 1'b0; 
            rx_retry_v = 1'b0; 
            rx_compl_tag_v = -1; 
            rx_compl_sts_v = {3{1'b1}}; 
            rx_tx_req_v = 1'b0; 
            rx_tx_desc_v = {128{1'b0}}; 
            rx_tx_shmem_addr_v = 0; 
            rx_tx_bcount_v = 0; 
            rx_tx_bcount_v = 0;
            for (i = 0 ; i < EBFM_NUM_TAG ; i = i + 1)
              begin
                 compl_expected_v[i] = -1; 
                 compl_received_v[i] = -1;
              end
         end
         else
         begin
            // See if the Transmit side is transmitting a Non-Posted Request
            // that we need to expect a completion for and if so record it
            if (exp_compl_tag > -1)
            begin
               compl_expected_v[exp_compl_tag] = exp_compl_bcount; 
               compl_received_v[exp_compl_tag] = 0; 
            end 
            rx_state_v = rx_state; 
            rx_ack_v = 1'b0; 
            rx_ws_v = 1'b0; 
            rx_abort_v = 1'b0; 
            rx_retry_v = 1'b0; 
            rx_tx_req_v = 1'b0; 
            case (rx_state)
               RXST_IDLE :
                        begin
                           // Note rx_mask will be controlled by tx_process
                           // process main_rx_state
                           if (rx_req == 1'b1)
                           begin
                              rx_ack_v = 1'b1; 
                              rx_state_v = RXST_DESC_ACK; 
                           end
                           else
                           begin
                              rx_ack_v = 1'b0; 
                              rx_state_v = RXST_IDLE; 
                           end 
                        end
               RXST_DESC_ACK, RXST_DATA_COMPL, RXST_DATA_WRITE, RXST_DATA_NONP_WRITE :
                        begin
                           if (rx_state == RXST_DESC_ACK)
                           begin
                              if (is_request(rx_desc))
                              begin
                                 // All of these states are handled together since they can all
                                 // involve data transfer and we need to share that code.
                                 //
                                 // If this is the cycle where the descriptor is being ack'ed we
                                 // need to complete the descriptor decode first so that we can
                                 // be prepared for the Data Transfer that might happen in the same
                                 // cycle. 
                                 if (is_non_posted(rx_desc[127:0]))
                                 begin
                                    // Non-Posted Request
                                    rx_nonp_req_setup_compl(rx_desc, rx_tx_desc_v, rx_tx_shmem_addr_v, rx_tx_byte_enb_v, rx_tx_bcount_v); 
                                    // Request
                                    if (has_data(rx_desc[127:0]))
                                    begin
                                       // Non-Posted Write Request
                                       rx_write_req_setup(rx_desc, shmem_addr_v, byte_enb_v, bcount_v); 
                                       rx_state_v = RXST_DATA_NONP_WRITE; 
                                    end
                                    else
                                    begin
                                       // Non-Posted Read Request
                                       rx_state_v = RXST_NONP_REQ; 
                                    end 
                                 end
                                 else
                                 begin
                                    // Posted Request
                                    rx_tx_desc_v = {128{1'b0}}; 
                                    rx_tx_shmem_addr_v = 0; 
                                    rx_tx_byte_enb_v = {8{1'b0}}; 
                                    rx_tx_bcount_v = 0; 
                                    // Begin Lengthy decode and checking of the Rx Descriptor
                                    // First Determine if it is a completion or a request
                                    if (has_data(rx_desc[127:0]))
                                    begin
                                       // Posted Write Request
                                       rx_write_req_setup(rx_desc, shmem_addr_v, byte_enb_v, bcount_v); 
                                       rx_state_v = RXST_DATA_WRITE; 
                                    end
                                    else
                                    begin
                                       // Posted Message without Data
                                       // Not currently supported.
                                       rx_state_v = RXST_IDLE; 
                                    end 
                                 end 
                              end
                              else // is_request == 0
                              begin
                                 // Completion
                                 rx_compl_setup(rx_desc, shmem_addr_v, byte_enb_v, bcount_v, 
                                                rx_compl_tag_v, rx_compl_sts_v); 
                                 if (compl_expected_v[rx_compl_tag_v] < 0)
                                 begin
                                    dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                                 {"Root Port VC", dimage1(VC_NUM), 
                                                  " Recevied unexpected completion TLP, Fmt/Type: ", 
                                                  himage2(rx_desc[127:120]), 
                                                  " Tag: ", himage2(rx_desc[47:40])}); 
                                 end 
                                 if (has_data(rx_desc[127:0]))
                                 begin
                                    rx_state_v = RXST_DATA_COMPL; 
                                    // Increment for already received data phases
                                    shmem_addr_v = shmem_addr_v + compl_received_v[rx_compl_tag_v]; 
                                 end
                                 else
                                 begin
                                    rx_state_v = RXST_IDLE; 
                                    if ((compl_received_v[rx_compl_tag_v] < compl_expected_v[rx_compl_tag_v]) & 
                                        (rx_compl_sts_v == 3'b000))
                                    begin
                                       dummy = ebfm_display(EBFM_MSG_ERROR_CONTINUE, 
                                                    {"Root Port VC", dimage1(VC_NUM), 
                                                     " Did not receive all expected completion data. Expected: ", 
                                                     dimage4(compl_expected_v[rx_compl_tag_v]), 
                                                     " Received: ", dimage4(compl_received_v[rx_compl_tag_v])}); 
                                    end 
                                    // Report that it is complete to the Driver
                                    vc_intf_rpt_compl(rx_compl_tag_v, rx_compl_sts_v); 
                                    // Clear out that we expect anymore
                                    compl_received_v[rx_compl_tag_v] = -1; 
                                    compl_expected_v[rx_compl_tag_v] = -1; 
                                    rx_compl_tag_v = -1; 
                                 end 
                              end 
                           end 
                           if (rx_dv == 1'b1)
                           begin
                              begin : xhdl_3
                                 integer i;
                                 for(i = 0; i <= 7; i = i + 1)
                                 begin
                                    if (((byte_enb_v[i]) == 1'b1) & (bcount_v > 0))
                                    begin
                                       shmem_write(shmem_addr_v, rx_data[(i * 8)+:8], 1); 
                                       shmem_addr_v = shmem_addr_v + 1; 
                                       bcount_v = bcount_v - 1; 
                                       // Byte Enables only valid on first data phase, bcount_v covers
                                       // the last data phase
                                       if ((bcount_v == 0) & (i < 7))
                                       begin
                                          begin : xhdl_4
                                             integer j;
                                             for(j = i + 1; j <= 7; j = j + 1)
                                             begin
                                                byte_enb_v[j] = 1'b0; 
                                             end
                                          end // j
                                       end 
                                       // Now Handle the case if we are receiving data in this cycle
                                       if (rx_state_v == RXST_DATA_COMPL)
                                       begin
                                          compl_received_v[rx_compl_tag_v] = compl_received_v[rx_compl_tag_v] + 1; 
                                       end 
                                       if (((rx_be[i]) != 1'b1) & (DISABLE_RX_BE_CHECK == 0))
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                                       {"Root Port VC", dimage1(VC_NUM), 
                                                        " rx_be field: ", himage2(rx_be), 
                                                        " Mismatch. Expected: ", himage2(byte_enb_v)}); 
                                       end 
                                    end
                                    else
                                    begin
                                       if (((rx_be[i]) != 1'b0) & (DISABLE_RX_BE_CHECK == 0))
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                                       {"Root Port VC", dimage1(VC_NUM), 
                                                        " rx_be field: ", himage2(rx_be), 
                                                        " Mismatch. Expected: ", himage2(byte_enb_v)}); 
                                       end 
                                    end 
                                 end
                              end // i
                              // Enable all bytes in subsequent data phases
                              byte_enb_v = {8{1'b1}}; 
                              if (rx_dfr == 1'b0)
                              begin
                                 if (bcount_v > 0)
                                 begin
                                    dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                                 {"Root Port VC", dimage1(VC_NUM), 
                                                  " Rx Byte Count did not go to zero in last data phase. Remaining Bytes: ", 
                                                  dimage4(bcount_v)}); 
                                 end 
                                 if (rx_state_v == RXST_DATA_COMPL)
                                 begin
                                    rx_state_v = RXST_IDLE; 
                                    // If we have received all of the data (or more) 
                                    if (compl_received_v[rx_compl_tag_v] >= compl_expected_v[rx_compl_tag_v])
                                    begin
                                       // Error if more than expected
                                       if (compl_received_v[rx_compl_tag_v] > compl_expected_v[rx_compl_tag_v])
                                       begin
                                          dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                                       {"Root Port VC", dimage1(VC_NUM), 
                                                        " Received more completion data than expected. Expected: ", 
                                                        dimage4(compl_expected_v[rx_compl_tag_v]), 
                                                        " Received: ", dimage4(compl_received_v[rx_compl_tag_v])}); 
                                       end 
                                       // Report that it is complete to the Driver
                                       vc_intf_rpt_compl(rx_compl_tag_v, rx_compl_sts_v); 
                                       // Clear out that we expect anymore
                                       compl_received_v[rx_compl_tag_v] = -1; 
                                       compl_expected_v[rx_compl_tag_v] = -1; 
                                       rx_compl_tag_v = -1; 
                                    end
                                    else
                                    begin
                                       // Have not received all of the data yet, but if the
                                       // completion status is not Successful Completion then we
                                       // need to treat as done
                                       if (rx_compl_sts_v != 3'b000)
                                       begin
                                          // Report that it is complete to the Driver
                                          vc_intf_rpt_compl(rx_compl_tag_v, rx_compl_sts_v); 
                                          // Clear out that we expect anymore
                                          compl_received_v[rx_compl_tag_v] = -1; 
                                          compl_expected_v[rx_compl_tag_v] = -1; 
                                          rx_compl_tag_v = -1; 
                                       end 
                                    end
                                    // Otherwise keep going and wait for more data in another completion 
                                 end
                                 else
                                 begin
                                    if (rx_state_v == RXST_DATA_NONP_WRITE)
                                    begin
                                       rx_state_v = RXST_NONP_REQ; 
                                    end
                                    else
                                    begin
                                       rx_state_v = RXST_IDLE; 
                                    end 
                                 end 
                              end
                              else
                              begin
                                 if (bcount_v == 0)
                                 begin
                                    dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                                                 {"Root Port VC", dimage1(VC_NUM), 
                                                  " Rx Byte Count went to zero before last data phase."}); 
                                 end 
                              end 
                           end 
                        end
               RXST_NONP_REQ :
                        begin
                           if (tx_rx_ack == 1'b1)
                           begin
                              rx_state_v = RXST_IDLE; 
                              rx_tx_req_v = 1'b0; 
                           end
                           else
                           begin
                              rx_tx_req_v = 1'b1; 
                              rx_state_v = RXST_NONP_REQ; 
                           end 
                           rx_ws_v = 1'b1; 
                        end
               default :
                        begin
                        end
            endcase 
         end 
         rx_state         <= rx_state_v ; 
         rx_ack           <= rx_ack_v ; 
         rx_ack_int       <= rx_ack_v ; 
         rx_ws            <= rx_ws_v ; 
         rx_ws_int        <= rx_ws_v ; 
         rx_abort         <= rx_abort_v ; 
         rx_retry         <= rx_retry_v ; 
         rx_tx_req        <= rx_tx_req_v ; 
         rx_tx_desc       <= rx_tx_desc_v ; 
         rx_tx_shmem_addr <= rx_tx_shmem_addr_v ; 
         rx_tx_bcount     <= rx_tx_bcount_v ; 
         rx_tx_byte_enb   <= rx_tx_byte_enb_v ; 
      end 
   end 

   always @(clk_in)
     begin : main_tx_state
      reg[32767:0] data_pkt_v; 
      integer dphases_v; 
      integer dptr_v; 
      reg[1:0] tx_state_v; 
      reg rx_mask_v; 
      reg tx_req_v; 
      reg[127:0] tx_desc_v; 
      reg tx_dfr_v; 
      reg[63:0] tx_data_v; 
      reg tx_dv_v; 
      reg tx_dv_last_v; 
      reg tx_err_v; 
      reg tx_rx_ack_v; 
      integer lcladdr_v; 
      reg req_ack_cleared_v; 
      reg[127:0] req_desc_v; 
      reg req_valid_v; 
      reg[31:0] imm_data_v; 
      reg imm_valid_v; 
      integer exp_compl_tag_v; 
      integer exp_compl_bcount_v; 

      if (clk_in == 1'b1)
      begin
         // rising clock edge
         exp_compl_tag_v = -1; 
         exp_compl_bcount_v = 0; 
         if (rstn == 1'b0)
         begin
            // synchronous reset (active low)
            tx_state_v = TXST_IDLE; 
            rx_mask_v = 1'b1; 
            tx_req_v = 1'b0; 
            tx_desc_v = {128{1'b0}}; 
            tx_dfr_v = 1'b0; 
            tx_data_v = {64{1'b0}}; 
            tx_dv_v = 1'b0; 
            tx_dv_last_v = 1'b0; 
            tx_err_v = 1'b0; 
            tx_rx_ack_v = 1'b0;
            req_ack_cleared_v = 1'b1;
         end
         else
         begin
            // Clear any previous acknowledgement if needed
            if (req_ack_cleared_v == 1'b0)
            begin
               req_ack_cleared_v = vc_intf_clr_ack(VC_NUM); 
            end 
            tx_state_v = tx_state; 
            rx_mask_v = 1'b1; // This is on in most states
            tx_req_v = 1'b0; 
            tx_dfr_v = 1'b0; 
            tx_dv_last_v = tx_dv_v; 
            tx_dv_v = 1'b0; 
            tx_rx_ack_v = 1'b0; 
            case (tx_state_v)
               TXST_IDLE :
                        begin
                           if (tx_ws == 1'b0)
                           begin
                              if (rx_tx_req == 1'b1)
                              begin
                                 rx_mask_v = 1'b0; 
                                 tx_state_v = TXST_DESC; 
                                 tx_desc_v = rx_tx_desc; 
                                 tx_req_v = 1'b1; 
                                 tx_rx_ack_v = 1'b1; 
                                 // Assumes we are getting infinite credits!!!!!
                                 if (rx_tx_bcount > 0)
                                 begin
                                    tx_setup_data(rx_tx_shmem_addr, rx_tx_bcount, rx_tx_byte_enb, data_pkt_v, 
                                                  dphases_v, 1'b0, 32'h00000000); 
                                    dptr_v = 0; 
                                    tx_data_v = {64{1'b0}}; 
                                    tx_dv_v = 1'b0; 
                                    tx_dfr_v = 1'b1; 
                                 end
                                 else
                                 begin
                                    tx_dv_v = 1'b0; 
                                    tx_dfr_v = 1'b0; 
                                    dphases_v = 0; 
                                 end 
                              end
                              else
                              begin
                                 vc_intf_get_req(VC_NUM, req_valid_v, req_desc_v, lcladdr_v, imm_valid_v, imm_data_v); 
                                 if ((tx_fc_check(req_desc_v, tx_cred)) & (req_valid_v == 1'b1) & (req_ack_cleared_v == 1'b1))
                                 begin
                                    vc_intf_set_ack(VC_NUM); 
                                    req_ack_cleared_v = vc_intf_clr_ack(VC_NUM); 
                                    tx_setup_req(req_desc_v, lcladdr_v, imm_valid_v, imm_data_v, data_pkt_v, dphases_v); 
                                    tx_state_v = TXST_DESC; 
                                    tx_desc_v = req_desc_v; 
                                    tx_req_v = 1'b1; 
                                    // process main_tx_state
                                    if (dphases_v > 0)
                                    begin
                                       dptr_v = 0; 
                                       tx_data_v = {64{1'b0}}; 
                                       tx_dv_v = 1'b0; 
                                       tx_dfr_v = 1'b1; 
                                    end
                                    else
                                    begin
                                       tx_dv_v = 1'b0; 
                                       tx_dfr_v = 1'b0; 
                                    end 
                                    if (is_non_posted(req_desc_v))
                                    begin
                                       exp_compl_tag_v = req_desc_v[79:72]; 
                                       if (has_data(req_desc_v))
                                       begin
                                          exp_compl_bcount_v = 0; 
                                       end
                                       else
                                       begin
                                          exp_compl_bcount_v = calc_byte_count(req_desc_v); 
                                       end 
                                    end 
                                 end
                                 else
                                 begin
                                    tx_state_v = TXST_IDLE; 
                                    rx_mask_v = 1'b0; 
                                 end 
                              end 
                           end 
                        end
               TXST_DESC, TXST_DATA :
                        begin
                           // Handle the Tx Data Signals 
                           if ((dphases_v > 0) & (tx_ws == 1'b0) & (tx_dv_last_v == 1'b1))
                           begin
                              dphases_v = dphases_v - 1; 
                              dptr_v = dptr_v + 1; 
                           end 
                           if (dphases_v > 0)
                           begin
                              tx_data_v = data_pkt_v[(dptr_v*64)+:64]; 
                              tx_dv_v = 1'b1; 
                              if (dphases_v > 1)
                              begin
                                 tx_dfr_v = 1'b1; 
                              end
                              else
                              begin
                                 tx_dfr_v = 1'b0; 
                              end 
                           end
                           else
                           begin
                              tx_data_v = {64{1'b0}}; 
                              tx_dv_v = 1'b0; 
                              tx_dfr_v = 1'b0; 
                           end 
                           if (tx_state_v == TXST_DESC)
                           begin
                              if (tx_ack == 1'b1)
                              begin
                                 tx_req_v = 1'b0; 
                                 tx_desc_v = {128{1'b0}}; 
                                 if (dphases_v > 0)
                                 begin
                                    tx_state_v = TXST_DATA; 
                                 end
                                 else
                                 begin
                                    tx_state_v = TXST_IDLE; 
                                 end 
                              end
                              else
                              begin
                                 tx_req_v = 1'b1; 
                                 tx_state_v = TXST_DESC; 
                              end 
                           end
                           else
                           begin
                              if (dphases_v > 0)
                              begin
                                 tx_state_v = TXST_DATA; 
                              end
                              else
                              begin
                                 tx_state_v = TXST_IDLE; 
                              end 
                           end 
                        end
               default :
                        begin
                        end
            endcase 
         end 
         tx_state <= tx_state_v ; 
         rx_mask <= rx_mask_v ; 
         tx_req <= tx_req_v ; 
         tx_req_int <= tx_req_v ; 
         tx_desc <= tx_desc_v ; 
         tx_dfr <= tx_dfr_v ; 
         tx_data <= tx_data_v ; 
         tx_dv <= tx_dv_v ; 
         tx_dv_last <= tx_dv_last_v ; 
         tx_err <= tx_err_v ; 
         tx_rx_ack <= tx_rx_ack_v ; 
         exp_compl_tag <= exp_compl_tag_v ; 
         exp_compl_bcount <= exp_compl_bcount_v ; 
      end 
   end 

   // purpose: This reflects the reset value in shared variables
   always 
   begin : reset_flag
      // process reset_flag
      if (VC_NUM > 0)
      begin
         forever #100000; // Only one VC needs to do this
      end
      else
      begin
         vc_intf_reset_flag(rstn); 
      end 
      @(rstn); 
   end 

  integer tx_pkts ;
  integer tx_qwords ;
  integer rx_pkts ;
  integer rx_qwords ;
  integer rx_dv_last ;
  reg clr_pndg ;

  initial
  begin
    clr_pndg = 0;
  end

  always@(posedge clk_in)
  begin
     if (vc_intf_sample_perf(VC_NUM) == 1'b1)
     begin
        if (clr_pndg == 1'b0)
        begin
           vc_intf_set_perf(VC_NUM,tx_pkts,tx_qwords,rx_pkts,rx_qwords);
           tx_pkts   = 0 ;
           tx_qwords = 0 ;
           rx_pkts   = 0 ;
           rx_qwords = 0 ;
           clr_pndg  = 1'b1 ;
        end
     end
     else
     begin
        if (clr_pndg == 1'b1)
           begin
              vc_intf_clr_perf(VC_NUM) ;
              clr_pndg = 1'b0 ;
           end
     end
     if (tx_dv_last == 1'b1 && tx_ws == 1'b0)
     begin
        tx_qwords = tx_qwords + 1;
     end
     if (tx_req_int == 1'b1 && tx_ack == 1'b1)
     begin
        tx_pkts = tx_pkts + 1;
     end
     if (rx_dv_last == 1'b1 && rx_ws_int == 1'b0)
     begin
        rx_qwords = rx_qwords + 1;
     end
     if (rx_req == 1'b1 && rx_ack_int == 1'b1)
     begin
        rx_pkts = rx_pkts + 1;
     end
     rx_dv_last = rx_dv ;
  end

endmodule
