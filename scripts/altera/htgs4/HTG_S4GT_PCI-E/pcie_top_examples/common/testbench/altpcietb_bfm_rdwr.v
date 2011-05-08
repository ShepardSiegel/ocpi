   //-----------------------------------------------------------------------------
   // Title         : PCI Express BFM Package of Read/Write Routines
   // Project       : PCI Express MegaCore function
   //-----------------------------------------------------------------------------
   // File          : altpcietb_bfm_rdwr.v
   // Author        : Altera Corporation
   //-----------------------------------------------------------------------------
   // Description :
   // This package provides all of the PCI Express BFM Read, Write and Utility
   // Routines.
   //-----------------------------------------------------------------------------
   // Copyright © 2005 Altera Corporation. All rights reserved.  Altera products are
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

   `include "altpcietb_bfm_req_intf.v"

   function [3:0] ebfm_calc_firstbe;
      input byte_address;
      integer byte_address;
      input byte_length;
      integer byte_length;

      begin
         case (byte_address % 4)
            0 :
                     begin
                        case (byte_length)
                           0 : ebfm_calc_firstbe = 4'b0000;
                           1 : ebfm_calc_firstbe = 4'b0001;
                           2 : ebfm_calc_firstbe = 4'b0011;
                           3 : ebfm_calc_firstbe = 4'b0111;
                           default : ebfm_calc_firstbe = 4'b1111;
                        endcase
                     end
            1 :
                     begin
                        case (byte_length)
                           0 : ebfm_calc_firstbe = 4'b0000;
                           1 : ebfm_calc_firstbe = 4'b0010;
                           2 : ebfm_calc_firstbe = 4'b0110;
                           default : ebfm_calc_firstbe = 4'b1110;
                        endcase
                     end
            2 :
                     begin
                        case (byte_length)
                           0 : ebfm_calc_firstbe = 4'b0000;
                           1 : ebfm_calc_firstbe = 4'b0100;
                           default : ebfm_calc_firstbe = 4'b1100;
                        endcase
                     end
            3 :
                     begin
                        case (byte_length)
                           0 : ebfm_calc_firstbe = 4'b0000;
                           default : ebfm_calc_firstbe = 4'b1000;
                        endcase
                     end
            default :
                     begin
                        ebfm_calc_firstbe = 4'b0000;
                     end
         endcase
      end
   endfunction

   function [3:0] ebfm_calc_lastbe;
      input byte_address;
      integer byte_address;
      input byte_length;
      integer byte_length;

      begin
         if ((byte_address % 4) + byte_length > 4)
         begin
            case ((byte_address + byte_length) % 4)
               0 : ebfm_calc_lastbe = 4'b1111;
               3 : ebfm_calc_lastbe = 4'b0111;
               2 : ebfm_calc_lastbe = 4'b0011;
               1 : ebfm_calc_lastbe = 4'b0001;
               default : ebfm_calc_lastbe = 4'bXXXX;
            endcase
         end
         else
         begin
            ebfm_calc_lastbe = 4'b0000;
         end
      end
   endfunction

   // purpose: This is the full featured configuration read that has all
   // optional behavior via the arguments
   task ebfm_cfgrd;
      input bus_num;
      integer bus_num;
      input dev_num;
      integer dev_num;
      input fnc_num;
      integer fnc_num;
      input regb_ad;
      integer regb_ad;
      input regb_ln;
      integer regb_ln;
      input lcladdr;
      integer lcladdr;
      input compl_wait;
      input need_handle;
      output[2:0] compl_status;
      output handle;
      integer handle;

      reg[192:0] info_v;
      integer tag_v;
      reg i_need_handle;

      begin
         info_v = {193{1'b0}} ;
         // Get a TAG
         i_need_handle = compl_wait | need_handle;
         req_intf_get_tag(tag_v, i_need_handle, lcladdr);
         // Assemble the request
         if ((bus_num == RP_PRI_BUS_NUM) & (dev_num == RP_PRI_DEV_NUM))
         begin
            info_v[127:120] = 8'h04; // CfgRd0
         end
         else
         begin
            info_v[127:120] = 8'h05; // CfgRd1
         end
         info_v[119:112] = 8'h00; // R, TC, RRRR fields all 0
         info_v[111:104] = 8'h00; // TD, EP, Attr, RR, LL all 0
         info_v[103:96] = 8'h01; // Length 1 DW
         info_v[95:80] = RP_REQ_ID; // Requester ID
         info_v[79:72] = tag_v ;
         info_v[71:68] = 4'h0; // Last DW BE
         info_v[67:64] = ebfm_calc_firstbe(regb_ad, regb_ln);
         info_v[63:56] = bus_num[7:0] ;
         info_v[55:51] = dev_num[4:0] ;
         info_v[50:48] = fnc_num[2:0] ;
         info_v[47:44] = 4'h0; // RRRR
         info_v[43:34] = (regb_ad / 4) ;
         info_v[33:32] = 2'b00; // RR
         // Make the request
         req_intf_vc_req(info_v);
         // Wait for completion if specified to do so
         if (compl_wait == 1'b1)
         begin
            req_intf_wait_compl(tag_v, compl_status, need_handle);
         end
         else
         begin
            compl_status = "UUU";
         end
         // Return the handle
         if (need_handle == 1'b0)
         begin
            handle = -1;
         end
         else
         begin
            handle = tag_v;
         end
      end
   endtask

   // purpose: Configuration Read that waits for completion automatically
   task ebfm_cfgrd_wait;
      input bus_num;
      integer bus_num;
      input dev_num;
      integer dev_num;
      input fnc_num;
      integer fnc_num;
      input regb_ad;
      integer regb_ad;
      input regb_ln;
      integer regb_ln;
      input lcladdr;
      integer lcladdr;
      output[2:0] compl_status;

      integer dum_hnd;

      begin
         ebfm_cfgrd(bus_num, dev_num, fnc_num, regb_ad, regb_ln, lcladdr,
         1'b1, 1'b0, compl_status, dum_hnd);
      end
   endtask

   // purpose: Configuration Read that does not wait, does not return handle
   //          Need to assume completes okay and is known to be done by the
   //          time a subsequent read completes.
   task ebfm_cfgrd_nowt;
      input bus_num;
      integer bus_num;
      input dev_num;
      integer dev_num;
      input fnc_num;
      integer fnc_num;
      input regb_ad;
      integer regb_ad;
      input regb_ln;
      integer regb_ln;
      input lcladdr;
      integer lcladdr;

      integer dum_hnd;
      reg[2:0] dum_sts;

      begin
         ebfm_cfgrd(bus_num, dev_num, fnc_num, regb_ad, regb_ln, lcladdr,
         1'b0, 1'b0, dum_sts, dum_hnd);
      end
   endtask

   // purpose: This is the full featured configuration write that has all
   // optional behavior via the arguments
   task ebfm_cfgwr;
      input bus_num;
      integer bus_num;
      input dev_num;
      integer dev_num;
      input fnc_num;
      integer fnc_num;
      input regb_ad;
      integer regb_ad;
      input regb_ln;
      integer regb_ln;
      input lcladdr;
      integer lcladdr;
      input imm_valid;
      input[31:0] imm_data;
      input compl_wait;
      input need_handle;
      output[2:0] compl_status;
      output handle;
      integer handle;

      reg[192:0] info_v;
      integer tag_v;
      reg i_need_handle;

      begin
         info_v = {193{1'b0}} ;
         // Get a TAG
         i_need_handle = compl_wait | need_handle;
         req_intf_get_tag(tag_v, i_need_handle, -1);
         // Assemble the request
         info_v[192] = imm_valid;
         info_v[191:160] = imm_data;
         info_v[159:128] = lcladdr;
         if ((bus_num == RP_PRI_BUS_NUM) & (dev_num == RP_PRI_DEV_NUM))
         begin
            info_v[127:120] = 8'h44; // CfgWr0
         end
         else
         begin
            info_v[127:120] = 8'h45; // CfgWr1
         end
         info_v[119:112] = 8'h00; // R, TC, RRRR fields all 0
         info_v[111:104] = 8'h00; // TD, EP, Attr, RR, LL all 0
         info_v[103:96] = 8'h01; // Length 1 DW
         info_v[95:80] = RP_REQ_ID; // Requester ID
         info_v[79:72] = tag_v ;
         info_v[71:68] = 4'h0; // Last DW BE
         info_v[67:64] = ebfm_calc_firstbe(regb_ad, regb_ln);
         info_v[63:56] = bus_num[7:0] ;
         info_v[55:51] = dev_num[4:0] ;
         info_v[50:48] = fnc_num[2:0] ;
         info_v[47:44] = 4'h0; // RRRR
         info_v[43:34] = (regb_ad / 4) ;
         info_v[33:32] = 2'b00; // RR
         // Make the request
         req_intf_vc_req(info_v);
         // Wait for completion if specified to do so
         if (compl_wait == 1'b1)
         begin
            req_intf_wait_compl(tag_v, compl_status, need_handle);
         end
         else
         begin
            compl_status = "UUU";
         end
         // Return the handle
         if (need_handle == 1'b0)
         begin
            handle = -1;
         end
         else
         begin
            handle = tag_v;
         end
      end
   endtask

   // purpose: Configuration Write, Immediate Data, that waits for completion automatically
   task ebfm_cfgwr_imm_wait;
      input bus_num;
      integer bus_num;
      input dev_num;
      integer dev_num;
      input fnc_num;
      integer fnc_num;
      input regb_ad;
      integer regb_ad;
      input regb_ln;
      integer regb_ln;
      input[31:0] imm_data;
      output[2:0] compl_status;

      integer dum_hnd;

      begin
         ebfm_cfgwr(bus_num, dev_num, fnc_num, regb_ad, regb_ln, 0, 1'b1,
         imm_data, 1'b1, 1'b0, compl_status, dum_hnd);
      end
   endtask

   // purpose: Configuration Write, Immediate Data, no wait, no handle
   task ebfm_cfgwr_imm_nowt;
      input bus_num;
      integer bus_num;
      input dev_num;
      integer dev_num;
      input fnc_num;
      integer fnc_num;
      input regb_ad;
      integer regb_ad;
      input regb_ln;
      integer regb_ln;
      input[31:0] imm_data;

      reg[2:0] dum_sts;
      integer dum_hnd;

      begin
         ebfm_cfgwr(bus_num, dev_num, fnc_num, regb_ad, regb_ln, 0, 1'b1,
         imm_data, 1'b0, 1'b0, dum_sts, dum_hnd);
      end
   endtask

   function [9:0] calc_dw_len;
      input byte_adr;
      integer byte_adr;
      input byte_len;
      integer byte_len;

      integer adr_len;
      reg[9:0] dw_len;

      begin
         // calc_dw_len
         adr_len = byte_len + (byte_adr % 4);
         if (adr_len % 4 == 0)
         begin
            dw_len = (adr_len / 4);
         end
         else
         begin
            dw_len = ((adr_len / 4) + 1);
         end
         calc_dw_len = dw_len;
      end
   endfunction

   task ebfm_memwr;
      input[63:0] pcie_addr;
      input lcladdr;
      integer lcladdr;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;

      reg[192:0] info_v;
      integer baddr_v;

      begin
         info_v = {193{1'b0}} ;
         // ebfm_memwr
         baddr_v = pcie_addr[11:0] ;
         // Assemble the request
         info_v[159:128] = lcladdr ;
         if (pcie_addr[63:32] == 32'h00000000)
         begin
            info_v[127:120] = 8'h40; // 3DW Header w/Data MemWr
            info_v[63:34] = pcie_addr[31:2];
            info_v[31:0] = {32{1'b0}};
         end
         else
         begin
            info_v[127:120] = 8'h60; // 4DW Header w/Data MemWr
            info_v[63:2] = pcie_addr[63:2];
         end
         info_v[119] = 1'b0; // Reserved bit
         info_v[118:116] = tclass;
         info_v[115:112] = 4'h0; // Reserved bits all 0
         info_v[111:106] = 6'b000000; // TD, EP, Attr, RR all 0
         info_v[105:96] = calc_dw_len(baddr_v, byte_len);
         info_v[95:80] = RP_REQ_ID; // Requester ID
         info_v[79:72] = 8'h00;
         info_v[71:68] = ebfm_calc_lastbe(baddr_v, byte_len);
         info_v[67:64] = ebfm_calc_firstbe(baddr_v, byte_len);
         // Make the request
         req_intf_vc_req(info_v);
      end
   endtask

   task ebfm_memwr_imm;
      input[63:0] pcie_addr;
      input[31:0] imm_data;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;

      reg[192:0] info_v;
      integer baddr_v;

      begin
         info_v = {193{1'b0}} ;
         // ebfm_memwr_imm
         baddr_v = pcie_addr[11:0];
         // Assemble the request
         info_v[192] = 1'b1;
         info_v[191:160] = imm_data ;
         if (pcie_addr[63:32] == 32'h00000000)
         begin
            info_v[127:120] = 8'h40; // 3DW Header w/Data MemWr
            info_v[63:34] = pcie_addr[31:2];
            info_v[31:0] = {32{1'b0}};
         end
         else
         begin
            info_v[127:120] = 8'h60; // 4DW Header w/Data MemWr
            info_v[63:2] = pcie_addr[63:2];
         end
         info_v[119] = 1'b0; // Reserved bit
         info_v[118:116] = tclass ;
         info_v[115:112] = 4'h0; // Reserved bits all 0
         info_v[111:106] = 6'b000000; // TD, EP, Attr, RR all 0
         info_v[105:96] = calc_dw_len(baddr_v, byte_len);
         info_v[95:80] = RP_REQ_ID; // Requester ID
         info_v[79:72] = 8'h00 ;
         info_v[71:68] = ebfm_calc_lastbe(baddr_v, byte_len);
         info_v[67:64] = ebfm_calc_firstbe(baddr_v, byte_len);
         // Make the request
         req_intf_vc_req(info_v);
      end
   endtask

   // purpose: This is the full featured memory read that has all
   // optional behavior via the arguments
   task ebfm_memrd;
      input[63:0] pcie_addr;
      input lcladdr;
      integer lcladdr;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;
      input compl_wait;
      input need_handle;
      output[2:0] compl_status;
      output handle;
      integer handle;

      reg[192:0] info_v;
      integer tag_v;
      reg i_need_handle;
      integer baddr_v;

      begin
         info_v = {193{1'b0}} ;
         // Get a TAG
         i_need_handle = compl_wait | need_handle;
         req_intf_get_tag(tag_v, i_need_handle, lcladdr);
         baddr_v = pcie_addr[11:0];
         // Assemble the request
         info_v[159:128] = lcladdr ;
         if (pcie_addr[63:32] == 32'h00000000)
         begin
            info_v[127:120] = 8'h00; // 3DW Header w/o Data MemWr
            info_v[63:34] = pcie_addr[31:2];
            info_v[31:0] = {32{1'b0}};
         end
         else
         begin
            info_v[127:120] = 8'h20; // 4DW Header w/o Data MemWr
            info_v[63:2] = pcie_addr[63:2];
         end
         info_v[119] = 1'b0; // Reserved bit
         info_v[118:116] = tclass ;
         info_v[115:112] = 4'h0; // Reserved bits all 0
         info_v[111:106] = 6'b000000; // TD, EP, Attr, RR all 0
         info_v[105:96] = calc_dw_len(baddr_v, byte_len);
         info_v[95:80] = RP_REQ_ID; // Requester ID
         info_v[79:72] = tag_v ;
         info_v[71:68] = ebfm_calc_lastbe(baddr_v, byte_len);
         info_v[67:64] = ebfm_calc_firstbe(baddr_v, byte_len);
         // Make the request
         req_intf_vc_req(info_v);
         // Wait for completion if specified to do so
         if (compl_wait == 1'b1)
         begin
            req_intf_wait_compl(tag_v, compl_status, need_handle);
         end
         else
         begin
            compl_status = "UUU";
         end
         // Return the handle
         if (need_handle == 1'b0)
         begin
            handle = -1;
         end
         else
         begin
            handle = tag_v;
         end
      end
   endtask

   task ebfm_barwr;
      input bar_table;
      integer bar_table;
      input bar_num;
      integer bar_num;
      input pcie_offset;
      integer pcie_offset;
      input lcladdr;
      integer lcladdr;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;

      reg[63:0] cbar;
      integer rem_len;
      integer offset;
      integer cur_len;
      reg[63:0] paddr;

      reg dummy ;

      begin
         rem_len = byte_len ;
         offset = 0 ;
         cbar = shmem_read(bar_table + (bar_num * 4), 8);
         if (((cbar[0]) == 1'b1) | ((cbar[2]) == 1'b0))
         begin
            cbar[63:32] = {32{1'b0}};
         end
         paddr = ({cbar[63:4], 4'b0000}) + pcie_offset;
         while (rem_len > 0)
         begin
            if ((cbar[0]) == 1'b1)
            begin
               dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, "Accessing I/O or Expansion ROM BAR is unsupported");
            end
            else
            begin
               cur_len = req_intf_max_payload_size(1'b0) - paddr[1:0];
               if (cur_len > rem_len)
               begin
                  cur_len = rem_len;
               end
               if (((paddr % 4096) + cur_len) > 4096)
               begin
                  cur_len = 4096 - (paddr % 4096);
               end
               ebfm_memwr( paddr, lcladdr + offset, cur_len, tclass);
            end
            offset = offset + cur_len;
            rem_len = rem_len - cur_len;
            paddr = paddr + cur_len;
         end
      end
   endtask

   task ebfm_barwr_imm;
      input bar_table;
      integer bar_table;
      input bar_num;
      integer bar_num;
      input pcie_offset;
      integer pcie_offset;
      input[31:0] imm_data;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;

      reg[63:0] cbar;

      reg dummy ;

      begin
         cbar = shmem_read(bar_table + (bar_num * 4), 8);
         if (((cbar[0]) == 1'b1) | ((cbar[2]) == 1'b0))
         begin
            cbar[63:32] = {32{1'b0}};
         end
         if ((cbar[0]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, "Accessing I/O or Expansion ROM BAR is unsupported");
         end
         else
         begin
            cbar[3:0] = 4'b0000;
            cbar = cbar + pcie_offset;
            ebfm_memwr_imm(cbar, imm_data, byte_len,
            tclass);
         end
      end
   endtask

   task ebfm_barrd;
      input bar_table;
      integer bar_table;
      input bar_num;
      integer bar_num;
      input pcie_offset;
      integer pcie_offset;
      input lcladdr;
      integer lcladdr;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;
      input compl_wait;
      input need_handle;
      output[2:0] compl_status;
      output handle;
      integer handle;

      reg[2:0] dum_status;
      integer dum_handle;
      reg[63:0] cbar;
      integer rem_len;
      integer offset;
      integer cur_len;
      reg[63:0] paddr;

      reg dummy ;

      begin
         rem_len = byte_len ;
         offset = 0 ;
         // ebfm_barrd
         cbar = shmem_read(bar_table + (bar_num * 4), 8);
         if (((cbar[0]) == 1'b1) | ((cbar[2]) == 1'b0))
         begin
            cbar[63:32] = {32{1'b0}};
         end
         paddr = ({cbar[63:4], 4'b0000}) + pcie_offset;
         while (rem_len > 0)
         begin
            if ((cbar[0]) == 1'b1)
            begin
               dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, "Accessing I/O or Expansion ROM BAR is unsupported");
            end
            else
            begin
               // Need to make sure we don't cross a DW boundary
               cur_len = req_intf_rp_max_rd_req_size(1'b0) - paddr[1:0];
               if (cur_len > rem_len)
               begin
                  cur_len = rem_len;
               end
               if (((paddr % 4096) + cur_len) > 4096)
               begin
                  cur_len = 4096 - (paddr % 4096);
               end
               if (rem_len == cur_len)
               begin
                  // If it is the last one use the passed in compl/handle parms
                  ebfm_memrd(paddr, lcladdr + offset,
                             cur_len, tclass, compl_wait, need_handle, compl_status,
                             handle);
               end
               else
               begin
                  // Otherwise no wait, assume it all completes and the final one
                  // pushes ahead
                  ebfm_memrd(paddr, lcladdr + offset,
                             cur_len, tclass, 1'b0, 1'b0, dum_status, dum_handle);
               end
            end
            offset = offset + cur_len;
            rem_len = rem_len - cur_len;
            paddr = paddr + cur_len;
         end
      end
   endtask

   task ebfm_barrd_wait;
      input bar_table;
      integer bar_table;
      input bar_num;
      integer bar_num;
      input pcie_offset;
      integer pcie_offset;
      input lcladdr;
      integer lcladdr;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;

      reg[2:0] dum_status;
      integer dum_handle;

      begin
         // ebfm_barrd_wait
         ebfm_barrd(bar_table, bar_num, pcie_offset, lcladdr, byte_len,
         tclass, 1'b1, 1'b0, dum_status, dum_handle);
      end
   endtask

   task ebfm_barrd_nowt;
      input bar_table;
      integer bar_table;
      input bar_num;
      integer bar_num;
      input pcie_offset;
      integer pcie_offset;
      input lcladdr;
      integer lcladdr;
      input byte_len;
      integer byte_len;
      input tclass;
      integer tclass;

      reg[2:0] dum_status;
      integer dum_handle;

      begin
         // ebfm_barrd_nowt
         ebfm_barrd(bar_table, bar_num, pcie_offset, lcladdr, byte_len,
         tclass, 1'b0, 1'b0, dum_status, dum_handle);
      end
   endtask

   task rdwr_start_perf_sample;
   begin
        req_intf_start_perf_sample;
   end
   endtask

   task rdwr_disp_perf_sample;
   output tx_mbit_ps;
   integer tx_mbit_ps;
   output rx_mbit_ps;
   integer rx_mbit_ps;
   output bytes_transmitted;
   integer bytes_transmitted;
   begin
        req_intf_disp_perf_sample(tx_mbit_ps, rx_mbit_ps, bytes_transmitted);
   end
   endtask

