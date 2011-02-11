//-----------------------------------------------------------------------------
// Title         : PCI Express BFM Package for Request Interface 
// Project       : PCI Express MegaCore function
//-----------------------------------------------------------------------------
// File          : altpcietb_bfm_req_intf.v
// Author        : Altera Corporation
//-----------------------------------------------------------------------------
// Description :
// This package provides the interface for passing the requests between the
// Read/Write Request package and ultimately the user's driver and the VC
// Interface Entitites
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


//`ifdef __ALTPCIETB_BFM_REQ_INTF__
//`else
// `define __ALTPCIETB_BFM_REQ_INTF__
// `include "altpcietb_bfm_constants.v" 
// `include "altpcietb_bfm_log.v" 
   // This constant defines how long to wait whenever waiting for some external event...
   parameter NUM_PS_TO_WAIT = 8000 ;

   // purpose: Sets the Max Payload size variables
   task req_intf_set_max_payload;
      input max_payload_size; 
      integer max_payload_size;
      input ep_max_rd_req; // 0 means use max_payload_size    
      integer ep_max_rd_req;
      input rp_max_rd_req; 
      integer rp_max_rd_req;

      begin
         // 0 means use max_payload_size    
         // set_max_payload
         bfm_req_intf_common.bfm_max_payload_size = max_payload_size; 
         if (ep_max_rd_req > 0)
         begin
            bfm_req_intf_common.bfm_ep_max_rd_req = ep_max_rd_req; 
         end
         else
         begin
            bfm_req_intf_common.bfm_ep_max_rd_req = max_payload_size; 
         end 
         if (rp_max_rd_req > 0)
         begin
            bfm_req_intf_common.bfm_rp_max_rd_req = rp_max_rd_req; 
         end
         else
         begin
            bfm_req_intf_common.bfm_rp_max_rd_req = max_payload_size; 
         end 
      end
   endtask

   // purpose: Returns the stored max payload size
   function integer req_intf_max_payload_size;
   input dummy;
      begin
         req_intf_max_payload_size = bfm_req_intf_common.bfm_max_payload_size; 
      end
   endfunction

   // purpose: Returns the stored end point max read request size
   function integer req_intf_ep_max_rd_req_size;
   input dummy;
      begin
         req_intf_ep_max_rd_req_size = bfm_req_intf_common.bfm_ep_max_rd_req; 
      end
   endfunction

   // purpose: Returns the stored root port max read request size
   function integer req_intf_rp_max_rd_req_size;
   input dummy;
      begin
         req_intf_rp_max_rd_req_size = bfm_req_intf_common.bfm_rp_max_rd_req; 
      end
   endfunction

   // purpose: procedure to wait until the root port is done being reset
   task req_intf_wait_reset_end;

      begin
         while (bfm_req_intf_common.reset_in_progress == 1'b1)
         begin
            #NUM_PS_TO_WAIT; 
         end 
      end
   endtask

   // purpose: procedure to get a free tag from the pool. Waits for one
   // to be free if none available initially
   task req_intf_get_tag;
      output tag; 
      integer tag;
      input need_handle; 
      input lcl_addr; 
      integer lcl_addr;

      integer tag_v; 

      begin
         tag_v = EBFM_NUM_TAG ;
         while ((tag_v > EBFM_NUM_TAG - 1) & (bfm_req_intf_common.reset_in_progress == 1'b0))
         begin : main_tloop
            // req_intf_get_tag
            // Find a tag to use
            begin : xhdl_0
               integer i;
               for(i = 0; i <= EBFM_NUM_TAG - 1; i = i + 1)
               begin : sub_tloop
                  if (((bfm_req_intf_common.tag_busy[i]) == 1'b0) & 
                      ((bfm_req_intf_common.hnd_busy[i]) == 1'b0))
                  begin
                     bfm_req_intf_common.tag_busy[i] = 1'b1; 
                     bfm_req_intf_common.hnd_busy[i] = need_handle; 
                     bfm_req_intf_common.tag_lcl_addr[i] = lcl_addr; 
                     tag_v = i; 
                     disable main_tloop; 
                  end 
               end
            end // i
            #(NUM_PS_TO_WAIT); 
         end 
         if (bfm_req_intf_common.reset_in_progress == 1'b1)
         begin
            tag = EBFM_NUM_TAG; 
         end
         else
         begin
            tag = tag_v; 
         end 
      end
   endtask

   // purpose: makes a request pending for the appropriate VC interface
   task req_intf_vc_req;
      input[192:0] info_v; 

      integer vcnum; 

      reg dummy ;
      
      begin
         // Get the Virtual Channel Number from the Traffic Class Number
         vcnum = bfm_req_intf_common.tc2vc_map[info_v[118:116]]; 
         if (vcnum >= EBFM_NUM_VC)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                         {"Attempt to transmit Packet with TC mapped to unsupported VC.", 
                          "TC: ", dimage1(info_v[118:116]),
                          ", VC: ", dimage1(vcnum)}); 
         end 
         // Make sure the ACK from any previous requests are cleared
         while (((bfm_req_intf_common.req_info_ack[vcnum]) == 1'b1) & 
                (bfm_req_intf_common.reset_in_progress == 1'b0))
         begin
            #(NUM_PS_TO_WAIT); 
         end 
         if (bfm_req_intf_common.reset_in_progress == 1'b1)
           begin
              // Exit
              disable req_intf_vc_req ; 
           end 
         // Make the Request
         bfm_req_intf_common.req_info[vcnum] = info_v; 
         bfm_req_intf_common.req_info_valid[vcnum] = 1'b1; 
         // Now wait for it to be acknowledged
         while ((bfm_req_intf_common.req_info_ack[vcnum] == 1'b0) & 
                (bfm_req_intf_common.reset_in_progress == 1'b0))
         begin
            #(NUM_PS_TO_WAIT); 
         end 
         // Clear the request
         bfm_req_intf_common.req_info[vcnum] = {193{1'b0}}; 
         bfm_req_intf_common.req_info_valid[vcnum] = 1'b0; 
      end
   endtask

   // purpose: Releases a reserved handle
   task req_intf_release_handle;
      input handle; 
      integer handle;

      reg dummy ;
      
      begin
         // req_intf_release_handle
         if ((bfm_req_intf_common.hnd_busy[handle]) != 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                         {"Attempt to release Handle ", 
                          dimage4(handle), 
                          " that is not reserved."}); 
         end 
         bfm_req_intf_common.hnd_busy[handle] = 1'b0; 
      end
   endtask

   // purpose: Wait for completion on the specified handle
   task req_intf_wait_compl;
      input handle; 
      integer handle;
      output[2:0] compl_status; 
      input keep_handle; 

      reg dummy ;
      
      begin
         if ((bfm_req_intf_common.hnd_busy[handle]) != 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                         {"Attempt to wait for completion on Handle ", 
                          dimage4(handle), 
                          " that is not reserved."}); 
         end 
         while ((bfm_req_intf_common.reset_in_progress == 1'b0) & 
                (bfm_req_intf_common.tag_busy[handle] == 1'b1))
         begin
            #(NUM_PS_TO_WAIT); 
         end 
         if ((bfm_req_intf_common.tag_busy[handle]) == 1'b0)
         begin
            compl_status = bfm_req_intf_common.tag_status[handle]; 
         end
         else
         begin
            compl_status = "UUU"; 
         end 
         if (keep_handle != 1'b1)
         begin
            req_intf_release_handle(handle); 
         end 
      end
   endtask

   // purpose: This gets the pending request (if any) for the specified VC
   task vc_intf_get_req;
      input vc_num; 
      integer vc_num;
      output req_valid; 
      output[127:0] req_desc; 
      output lcladdr; 
      integer lcladdr;
      output imm_valid; 
      output[31:0] imm_data; 

      begin
         // vc_intf_get_req
         req_desc  = bfm_req_intf_common.req_info[vc_num][127:0]; 
         lcladdr   = bfm_req_intf_common.req_info[vc_num][159:128]; 
         imm_data  = bfm_req_intf_common.req_info[vc_num][191:160]; 
         imm_valid = bfm_req_intf_common.req_info[vc_num][192]; 
         req_valid = bfm_req_intf_common.req_info_valid[vc_num]; 
      end
   endtask

   // purpose: This sets the acknowledgement for a pending request
   task vc_intf_set_ack;
      input vc_num; 
      integer vc_num;

      reg dummy ;
      
      begin
         if (bfm_req_intf_common.req_info_valid[vc_num] != 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                         {"VC Interface ", 
                          dimage1(vc_num), 
                          " tried to ACK a request that is not there."}); 
         end 
         if (bfm_req_intf_common.req_info_ack[vc_num] != 1'b0)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                         {"VC Interface ", 
                          dimage1(vc_num), 
                          " tried to ACK a request second time."}); 
         end 
         bfm_req_intf_common.req_info_ack[vc_num] = 1'b1; 
      end
   endtask

   // purpose: This conditionally clears the acknowledgement for a pending request
   //          It only clears the ack if the req valid has been cleared.
   //          Returns '1' if the Ack was cleared, else returns '0'.
   function [0:0] vc_intf_clr_ack;
      input vc_num; 
      integer vc_num;

      begin
         if ((bfm_req_intf_common.req_info_valid[vc_num]) == 1'b0)
         begin
            bfm_req_intf_common.req_info_ack[vc_num] = 1'b0; 
            vc_intf_clr_ack = 1'b1; 
         end
         else
         begin
            vc_intf_clr_ack = 1'b0; 
         end 
      end
   endfunction

   // purpose: This routine is to record the completion of a previous non-posted request
   task vc_intf_rpt_compl;
      input tag; 
      integer tag;
      input[2:0] status; 

      reg dummy ;
      
      begin
         // vc_intf_rpt_compl
         bfm_req_intf_common.tag_status[tag] = status; 
         if ((bfm_req_intf_common.tag_busy[tag]) != 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, 
                         {"Tried to clear a tag that was not busy. Tag: ", 
                          dimage4(tag)}); 
         end 
         bfm_req_intf_common.tag_busy[tag] = 1'b0; 
      end
   endtask

   task vc_intf_reset_flag;
      input rstn; 

      begin
         bfm_req_intf_common.reset_in_progress = ~rstn; 
      end
   endtask

   function integer vc_intf_get_lcl_addr;
      input tag; 
      integer tag;

      begin
         // vc_intf_get_lcl_addr
         if ((bfm_req_intf_common.tag_lcl_addr[tag] != -1) & 
             ((bfm_req_intf_common.tag_busy[tag] == 1'b1) | 
              (bfm_req_intf_common.hnd_busy[tag] == 1'b1)))
         begin
            vc_intf_get_lcl_addr = bfm_req_intf_common.tag_lcl_addr[tag]; 
         end
         else
         begin
            vc_intf_get_lcl_addr = -1 ; 
         end 
      end
   endfunction

   function integer vc_intf_sample_perf;
      input vc_num;
      integer vc_num;
      begin
         vc_intf_sample_perf = bfm_req_intf_common.perf_req[vc_num];
      end
   endfunction

  task vc_intf_set_perf; 
  input [31:0] vc_num;
  input [31:0] tx_pkts;
  input [31:0] tx_qwords;
  input [31:0] rx_pkts;
  input [31:0] rx_qwords;
  begin
     bfm_req_intf_common.perf_tx_pkts[vc_num]   = tx_pkts ;
     bfm_req_intf_common.perf_tx_qwords[vc_num] = tx_qwords ;
     bfm_req_intf_common.perf_rx_pkts[vc_num]   = rx_pkts ;
     bfm_req_intf_common.perf_rx_qwords[vc_num] = rx_qwords ;
     bfm_req_intf_common.perf_ack[vc_num]       = 1'b1 ;
  end
  endtask

   task vc_intf_clr_perf;
      input vc_num;
      integer vc_num;
      begin
         bfm_req_intf_common.perf_ack[vc_num] = 1'b0;
      end
   endtask

   task req_intf_start_perf_sample;
   integer i;
   begin
      bfm_req_intf_common.perf_req = {EBFM_NUM_VC{1'b1}};
      bfm_req_intf_common.last_perf_timestamp = $time;
      while (bfm_req_intf_common.perf_req != {EBFM_NUM_VC{1'b0}})
      begin
         #NUM_PS_TO_WAIT;
	 for (i = 1'b0 ; i < EBFM_NUM_VC ; i = i +1)
	 begin
	    if (bfm_req_intf_common.perf_ack[i] == 1'b1)
	    begin
	       bfm_req_intf_common.perf_req[i] = 1'b0;
	    end
	 end
      end
   end
   endtask

   task req_intf_disp_perf_sample;
   integer total_tx_qwords;
   integer total_tx_pkts;
   integer total_rx_qwords;
   integer total_rx_pkts;
   integer tx_mbyte_ps;
   integer rx_mbyte_ps;
   output  tx_mbit_ps;
   integer tx_mbit_ps;
   output  rx_mbit_ps;
   integer rx_mbit_ps;
   integer delta_time;
   integer delta_ns;
   output  bytes_transmitted;
   integer bytes_transmitted;
   reg   [EBFM_MSG_MAX_LEN*8:1] message;
   integer i;
   integer dummy;
   begin
      total_tx_qwords = 0;
      total_tx_pkts   = 0;
      total_rx_qwords = 0;
      total_rx_pkts   = 0;
      delta_time = $time - bfm_req_intf_common.last_perf_timestamp;
      delta_ns = delta_time / 1000;
      req_intf_start_perf_sample ;
      for (i = 0; i < EBFM_NUM_VC; i = i + 1)
      begin
         total_tx_qwords = total_tx_qwords + bfm_req_intf_common.perf_tx_qwords[i] ;
         total_tx_pkts   = total_tx_pkts   + bfm_req_intf_common.perf_tx_pkts[i];
         total_rx_qwords = total_rx_qwords + bfm_req_intf_common.perf_rx_qwords[i];
         total_rx_pkts   = total_rx_pkts   + bfm_req_intf_common.perf_rx_pkts[i];
      end
      tx_mbyte_ps = (total_tx_qwords * 8) / (delta_ns / 1000);
      rx_mbyte_ps = (total_rx_qwords * 8) / (delta_ns / 1000);
      tx_mbit_ps  = tx_mbyte_ps * 8;
      rx_mbit_ps  = rx_mbyte_ps * 8;
      bytes_transmitted = total_tx_qwords*8;
      
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF: Sample Duration: ", delta_ns)," ns"});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:      Tx Packets: ", total_tx_pkts)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:        Tx Bytes: ", total_tx_qwords*8)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:    Tx MByte/sec: ", tx_mbyte_ps)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:     Tx Mbit/sec: ", tx_mbit_ps)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:      Rx Packets: ", total_rx_pkts)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:        Rx Bytes: ", total_rx_qwords*8)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:    Rx MByte/sec: ", rx_mbyte_ps)});
      dummy = ebfm_display(EBFM_MSG_INFO, {image("PERF:     Rx Mbit/sec: ", rx_mbit_ps)});
   end
   endtask

//`endif 
