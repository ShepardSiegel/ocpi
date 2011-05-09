   //-----------------------------------------------------------------------------
   // Title         : PCI Express BFM Package of Configuration Routines
   // Project       : PCI Express MegaCore function
   //-----------------------------------------------------------------------------
   // File          : altpcietb_bfm_configure.v
   // Author        : Altera Corporation
   //-----------------------------------------------------------------------------
   // Description :
   // This package provides routines to setup the configuration spaces of the
   // Root Port and End Point sections of the testbench.
   //-----------------------------------------------------------------------------
   // Copyright © 2009 Altera Corporation. All rights reserved.  Altera products are
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

   // This is where the PCI Express Capability is for the MegaCore Function
   parameter PCIE_CAP_PTR = 128;

   task cfg_wr_bars;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input bar_base;
      integer bar_base;
      input typ1;

      integer maxbar;
      integer rombar;
      reg[2:0] compl_status;

      begin
         if (typ1 == 1'b1)
           begin
              maxbar = 5;
              rombar = 14;
           end
         else
           begin
              maxbar = 9;
              rombar = 12;
           end
         begin : xhdl_0
            integer i;
            for(i = 4; i <= maxbar; i = i + 1)
            begin
               ebfm_cfgwr_imm_nowt(bnm, dev, fnc, (i * 4), 4,
               shmem_read(bar_base + ((i - 4) * 4), 4));
            end
         end // i
         ebfm_cfgwr_imm_wait(bnm, dev, fnc, (rombar * 4), 4,
         shmem_read(bar_base + 24, 4), compl_status);
      end
   endtask

   task cfg_rd_bars;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input bar_base;
      integer bar_base;
      input typ1;

      integer maxbar;
      integer rombar;
      reg[2:0] compl_status;

      begin
         if (typ1 == 1'b1)
           begin
              maxbar = 5;
              rombar = 14;
           end
         else
           begin
              maxbar = 9;
              rombar = 12;
           end
         begin : xhdl_1
            integer i;
            for(i = 4; i <= maxbar; i = i + 1)
            begin
               ebfm_cfgrd_nowt(bnm, dev, fnc, (i * 4), 4, bar_base + ((i - 4) * 4));
            end
         end // i
         ebfm_cfgrd_wait(bnm, dev, fnc, (rombar * 4), 4, bar_base + 24, compl_status);
      end
   endtask

   // purpose: Configures the Address Window Registers in the Root Port
   task ebfm_cfg_rp_addr;
      // Prefetchable Base and Limits  must be supplied
      input[63:0] pci_pref_base;
      input[63:0] pci_pref_limit;
      // Non-Prefetchable Space Base and Limits are optional
      input[31:0] pci_nonp_base;
      input[31:0] pci_nonp_limit;
      // IO Space Base and Limits are optional
      input[31:0] pci_io_base;
      input[31:0] pci_io_limit;

      parameter bnm = RP_PRI_BUS_NUM;
      parameter dev = RP_PRI_DEV_NUM;

      begin  // ebfm_cfg_rp_addr
         // Configure the I/O Base and Limit Registers
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 28, 4,
                             {16'h0000,
                              pci_io_limit[15:12], 4'h0,
                              pci_io_base[15:12], 4'h0});
         // Configure the Non-Prefetchable Base & Limit Registers
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 32, 4,
                             {pci_nonp_limit[31:20], 4'h0,
                              pci_nonp_base[31:20], 4'h0});
         // Configure the Prefetchable Base & Limit Registers
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 36, 4,
                             {pci_pref_limit[31:20], 4'h0,
                              pci_pref_base[31:20], 4'h0});
         // Configure the Upper Prefetchable Base Register
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 40, 4,
                             pci_pref_base[63:32]);
         // Configure the Upper Prefetchable Limit Register
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 44, 4,
                             pci_pref_limit[63:32]);
         // Configure the Upper I/O Base and Limit Registers
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 48, 4,
                             {pci_io_limit[31:16],
                              pci_io_base[31:16]});

      end
   endtask

   task ebfm_cfg_rp_basic;
      // The Secondary Side Bus Number Defaults to 1 more than the Primary
      input sec_bnm_offset; // Secondary Side Bus Number
                            // Offset from Primary
      // The number of subordinate busses defaults to 1
      integer sec_bnm_offset; // Number of Subordinate Busses
      input num_sub_bus;
      integer num_sub_bus;

      reg[31:0] tmp_slv;
      parameter bnm = RP_PRI_BUS_NUM;
      parameter dev = RP_PRI_DEV_NUM;

      begin  // ebfm_cfg_rp_basic
         // Configure the command register
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 4, 4, 32'h00000006);
         // Configure the Bus number Registers
         // Primary BUS
         tmp_slv[7:0] = bnm ;
         // Secondary BUS (primary + offset)
         tmp_slv[15:8] = (bnm + sec_bnm_offset);
         // Maximum Subordinate BUS (primary + offset + num - 1)
         tmp_slv[23:16] = (bnm + sec_bnm_offset + num_sub_bus - 1);
         tmp_slv[31:24] = 8'h0;
         ebfm_cfgwr_imm_nowt(bnm, dev, 0, 24, 4, tmp_slv);

      end
   endtask

   task assign_bar;
      inout[63:0] bar;
      inout[63:0] amin; // amin = address minimum
      input[63:0] amax; // amax = address maximum

      reg[63:0] tbar;   // tbar = temporary bar
      reg[63:0] bsiz;   // bsiz = bar size

      begin
         tbar = {bar[63:4], 4'b0000};
         bsiz = (~tbar) + 1;
         // See if amin already on the boundary
         if ((amin & ~tbar) == 0)
         begin
            tbar = tbar & amin; // Lowest assignment
         end
         else
         begin
            // The lower bits were not 0, then we have to round up to the
            // next boundary
            tbar = (amin + bsiz) & tbar ;
         end
         if ((tbar + bsiz - 1) > amax)
         begin
            // We cant make the assignement
            bar[63:4] = {60{1'bx}};
         end
         else
         begin
            bar[63:4] = tbar[63:4];
            amin = tbar + bsiz;
         end
      end
   endtask

   task assign_bar_from_top;
      inout[63:0] bar;
      input[63:0] amin; // amin = address minimum
      inout[63:0] amax; // amax = address maximum

      reg[63:0] tbar;   // tbar = temporary bar
      reg[63:0] bsiz;   // bsiz = bar size

      begin
         bsiz = (~{bar[63:4], 4'b0000}) + 1;
         tbar = amax - bsiz + 1;  // Highest Assignment
         tbar = tbar & bar[63:0]; // Round Down
         if (tbar < amin)
         begin
            // We cant make the assignment
            bar[63:4] = {60{1'bx}};
         end
         else
         begin
            bar[63:4] = tbar[63:4];
            amax = tbar - 1;
         end
      end
   endtask

   // purpose: Describes the attributes of the BAR and the assigned address
   task describe_bar;
      input bar_num;
      integer bar_num;
      input bar_lsb;
      integer bar_lsb;
      input[63:0] bar;
      input       addr_unused ;

      reg[(6)*8:1] bar_num_str;
      reg[(10)*8:1] bar_size_str;
      reg[(16)*8:1] bar_type_str;
      reg bar_enabled;
      reg[(17)*8:1] addr_str;

      reg dummy ;

      begin  // describe_bar
         bar_enabled  = 1'b1 ;
         case (bar_lsb)
            4  : bar_size_str = " 16 Bytes ";
            5  : bar_size_str = " 32 Bytes ";
            6  : bar_size_str = " 64 Bytes ";
            7  : bar_size_str = "128 Bytes ";
            8  : bar_size_str = "256 Bytes ";
            9  : bar_size_str = "512 Bytes ";
            10 : bar_size_str = "  1 KBytes";
            11 : bar_size_str = "  2 KBytes";
            12 : bar_size_str = "  4 KBytes";
            13 : bar_size_str = "  8 KBytes";
            14 : bar_size_str = " 16 KBytes";
            15 : bar_size_str = " 32 KBytes";
            16 : bar_size_str = " 64 KBytes";
            17 : bar_size_str = "128 KBytes";
            18 : bar_size_str = "256 KBytes";
            19 : bar_size_str = "512 KBytes";
            20 : bar_size_str = "  1 MBytes";
            21 : bar_size_str = "  2 MBytes";
            22 : bar_size_str = "  4 MBytes";
            23 : bar_size_str = "  8 MBytes";
            24 : bar_size_str = " 16 MBytes";
            25 : bar_size_str = " 32 MBytes";
            26 : bar_size_str = " 64 MBytes";
            27 : bar_size_str = "128 MBytes";
            28 : bar_size_str = "256 MBytes";
            29 : bar_size_str = "512 MBytes";
            30 : bar_size_str = "  1 GBytes";
            31 : bar_size_str = "  2 GBytes";
            32 : bar_size_str = "  4 GBytes";
            33 : bar_size_str = "  8 GBytes";
            34 : bar_size_str = " 16 GBytes";
            35 : bar_size_str = " 32 GBytes";
            36 : bar_size_str = " 64 GBytes";
            37 : bar_size_str = "128 GBytes";
            38 : bar_size_str = "256 GBytes";
            39 : bar_size_str = "512 GBytes";
            40 : bar_size_str = "  1 TBytes";
            41 : bar_size_str = "  2 TBytes";
            42 : bar_size_str = "  4 TBytes";
            43 : bar_size_str = "  8 TBytes";
            44 : bar_size_str = " 16 TBytes";
            45 : bar_size_str = " 32 TBytes";
            46 : bar_size_str = " 64 TBytes";
            47 : bar_size_str = "128 TBytes";
            48 : bar_size_str = "256 TBytes";
            49 : bar_size_str = "512 TBytes";
            50 : bar_size_str = "  1 PBytes";
            51 : bar_size_str = "  2 PBytes";
            52 : bar_size_str = "  4 PBytes";
            53 : bar_size_str = "  8 PBytes";
            54 : bar_size_str = " 16 PBytes";
            55 : bar_size_str = " 32 PBytes";
            56 : bar_size_str = " 64 PBytes";
            57 : bar_size_str = "128 PBytes";
            58 : bar_size_str = "256 PBytes";
            59 : bar_size_str = "512 PBytes";
            60 : bar_size_str = "  1 EBytes";
            61 : bar_size_str = "  2 EBytes";
            62 : bar_size_str = "  4 EBytes";
            63 : bar_size_str = "  8 EBytes";
            default :
                     begin
                        bar_size_str = "Disabled  ";
                        bar_enabled = 0;
                     end
         endcase
         if (bar_num == 6)
         begin
            bar_num_str = "ExpROM";
         end
         else
         begin
            bar_num_str = {"BAR", dimage1(bar_num), "  "};
         end
         if (bar_enabled)
         begin
            if ((bar[2]) == 1'b1)
            begin
               bar_num_str = {"BAR", dimage1(bar_num+1), ":", dimage1(bar_num)};
            end
            if (addr_unused == 1'b1 )
              begin
                 addr_str = "Not used in RP   ";
              end
            else
              begin
                 if ( (bar[32] == 1'b0) | (bar[32] == 1'b1) )
                   begin
                      if ((bar[2]) == 1'b1)
                        begin
                           addr_str[136:73] = himage8(bar[63:32]);
                        end
                      else
                        begin
                           addr_str[136:73] = "        ";
                        end
                      addr_str[72:65] = " ";
                      addr_str[64:1] = himage8({bar[31:4], 4'b0000});
                   end
                 else
                   begin
                      addr_str = "Unassigned!!!    ";
                   end // else: !if( (bar[32] == 1'b0) | (bar[32] == 1'b1) )
              end // else: !if(addr_unused == 1'b1 )
            if ((bar[0]) == 1'b1)
              begin
                 bar_type_str = "IO Space        ";
              end
            else
            begin
               if ((bar[3]) == 1'b1)
               begin
                  bar_type_str = "Prefetchable    ";
               end
               else
               begin
                  bar_type_str = "Non-Prefetchable";
               end
            end
            dummy = ebfm_display(EBFM_MSG_INFO, {bar_num_str, " ", bar_size_str,
            " ", addr_str, " ", bar_type_str});
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, {bar_num_str, " ", bar_size_str});
         end
      end
   endtask

   // purpose: configure a set of bars
   task ebfm_cfg_bars;
      input bnm;         // Bus Number
      integer bnm;
      input dev;         // Device Number
      integer dev;
      input fnc;         // Function Number
      integer fnc;
      input bar_table;   // Base Address in Shared Memory to
      integer bar_table; // store programmed value of BARs
      output bar_ok;
      inout[31:0] io_min;
      inout[31:0] io_max;
      inout[63:0] m32min;
      inout[63:0] m32max;
      inout[63:0] m64min;
      inout[63:0] m64max;
      input display;
      integer display;
      input addr_map_4GB_limit;

      reg[63:0] io_min_v;
      reg[63:0] io_max_v;
      reg[63:0] m32min_v;
      reg[63:0] m32max_v;
      reg[63:0] m64min_v;
      reg[63:0] m64max_v;
      reg typ1;
      reg[2:0] compl_status;
      integer nbar;
      reg[63:0] bars[0:6];
      integer sm_bar[0:6];
      integer bar_lsb[0:6];

      reg [7:0] htype ;

      reg dummy ;

      reg [63:0] bars_xhdl ;

      begin  // ebfm_cfg_bars
         io_min_v = {32'h00000000,io_min} ;
         io_max_v = {32'h00000000,io_max} ;
         m32min_v = m32min ;
         m32max_v = m32max ;
         m64min_v = m64min ;
         m64max_v = m64max ;
         sm_bar[0] = 0 ;
         sm_bar[1] = 1 ;
         sm_bar[2] = 2 ;
         sm_bar[3] = 3 ;
         sm_bar[4] = 4 ;
         sm_bar[5] = 5 ;
         sm_bar[6] = 6 ;

         bar_ok = 1'b1;
         shmem_fill(bar_table, SHMEM_FILL_ONE, 32, {64{1'b0}});
         // Clear the last bit of the ROMBAR which is the enable bit...
         shmem_write(bar_table + 24, 8'hFE, 1) ;
         // Read Header Type Field into last DWORD
         ebfm_cfgrd_wait(bnm, dev, fnc, 12, 4, bar_table + 28, compl_status);
         htype = shmem_read(bar_table + 30, 1) ;
         if (htype[6:0] == 7'b0000001)
         begin
            typ1 = 1'b1;
         end
         else
         begin
            typ1 = 1'b0;
         end
         cfg_wr_bars(bnm, dev, fnc, bar_table, typ1);
         shmem_fill(bar_table, SHMEM_FILL_ZERO, 28, {64{1'b0}});
         shmem_fill(bar_table + 32, SHMEM_FILL_ZERO, 32, {64{1'b0}});
         cfg_rd_bars(bnm, dev, fnc, bar_table + 32, typ1);
         // Load each BAR into the local BAR array
         // Find the Least Significant Writable bit in each BAR
         nbar = 0;
         while (nbar < 7)
           begin
              bars[nbar] = shmem_read((bar_table + 32 + (nbar * 4)), 8);
              bars_xhdl = bars[nbar];
              if ((bars_xhdl[2]) == 1'b0)
                begin
                   // 32 bit
                   if ((bars_xhdl[31]) == 1'b1)
                     begin
                        // if valid
                        bars_xhdl[63:32] = {32{1'b1}};
                     end
                   else
                     begin
                        // if not valid
                        bars_xhdl[63:32] = {32{1'b0}};
                     end
                end
              else
                begin
                   // 64-bit BAR, mark the next one invalid
                   bar_lsb[nbar + 1] = 64;
                end

              bars[nbar] = bars_xhdl ;
              if (bars_xhdl[63:4] == 0)
                begin
                   bar_lsb[nbar] = 64;
                end
              else
                begin
                   begin : xhdl_3
                      integer j;
                      for(j = 4; j <= 63; j = j + 1)
                        begin : lsb_loop
                           if ((bars_xhdl[j]) == 1'b1)
                             begin
                                bar_lsb[nbar] = j;
                                disable xhdl_3 ;
                             end
                        end
                   end // j
                end

              // Increment 1 for 32bit BARs or 2 for 64bit BARs.
              bars_xhdl = bars[nbar];
              if ((bars_xhdl[2]) == 1'b0)
                begin
                   nbar = nbar + 1;
                end
              else
                begin
                   nbar = nbar + 2;
                end
           end // i

         begin : xhdl_4
            integer i;
            for(i = 0; i <= 5; i = i + 1)
              begin
                 // Sort the BARs in order smallest to largest
                 begin : xhdl_5
                    integer j;
                    for(j = i + 1; j <= 6; j = j + 1)
                      begin
                         if (bar_lsb[sm_bar[j]] < bar_lsb[sm_bar[i]])
                           begin
                              nbar = sm_bar[i];
                              sm_bar[i] = sm_bar[j];
                              sm_bar[j] = nbar;
                           end
                      end
                 end // j
              end
         end // i

         // Fill all of the I/O BARs First, Smallest to Largest
         begin : xhdl_6
            integer i;
            for(i = 0; i <= 6; i = i + 1)
            begin
               if (bar_lsb[sm_bar[i]] < 64)
                 begin
                  bars_xhdl = bars[sm_bar[i]];
                    if ((bars_xhdl[0]) == 1'b1)
                      begin
                         assign_bar(bars[sm_bar[i]], io_min_v, io_max_v);
                      end
                 end
            end
         end // i
         // Now fill all of the 32-bit Non-Prefetchable BARs, Smallest to Largest
         begin : xhdl_7
            integer i;
            for(i = 0; i <= 6; i = i + 1)
              begin
                 if (bar_lsb[sm_bar[i]] < 64)
                   begin
                      bars_xhdl = bars[sm_bar[i]];
                      if (bars_xhdl[3:0] == 4'b0000)
                        begin
                           assign_bar(bars[sm_bar[i]], m32min_v, m32max_v);
                        end
                   end
              end
         end // i
         // Now fill all of the 32-bit Prefetchable BARs (and 64-bit Prefetchable BARs if addr_map_4GB_limit is set),
         // Largest to Smallest. From the top of memory.
         begin : xhdl_8
            integer i;
            for(i = 6; i >= 0; i = i - 1)
              begin
                 if (bar_lsb[sm_bar[i]] < 64)
                   begin
                      bars_xhdl = bars[sm_bar[i]];
                      if (bars_xhdl[3:0] == 4'b1000 ||
                         (addr_map_4GB_limit && bars_xhdl[3:0] == 4'b1100))
                        begin
                           assign_bar_from_top(bars[sm_bar[i]], m32min_v, m32max_v);
                        end
                   end
              end
         end // i
         // Now fill all of the 64-bit Prefetchable BARs, Smallest to Largest, if addr_map_4GB_limit is not set.
         if (addr_map_4GB_limit == 1'b0)
         begin : xhdl_9
            integer i;
            for(i = 0; i <= 6; i = i + 1)
            begin
               if (bar_lsb[sm_bar[i]] < 64)
                 begin
                    bars_xhdl = bars[sm_bar[i]];
                    if (bars_xhdl[3:0] == 4'b1100)
                      begin
                         assign_bar(bars[sm_bar[i]], m64min_v, m64max_v);
                      end
                 end
            end
         end // i
         // Now put all of the BARs back in memory
         nbar = 0;
         if (display == 1)
           begin
              dummy = ebfm_display(EBFM_MSG_INFO, "");
              dummy = ebfm_display(EBFM_MSG_INFO, "BAR Address Assignments:");
              dummy = ebfm_display(EBFM_MSG_INFO, {"BAR   ", " ", "Size      ", " ", "Assigned Address ", " ", "Type"});
              dummy = ebfm_display(EBFM_MSG_INFO, {"---   ", " ", "----      ", " ", "---------------- ", " "});
           end
         while (nbar < 7)
           begin
              if (display == 1)
                begin
                   // Show the user what we have done
                   describe_bar(nbar, bar_lsb[nbar], bars[nbar],1'b0) ;
                end
              bars_xhdl = bars[nbar];
              // Check and see if the BAR was unabled to be assigned!!
              if (bars_xhdl[32] === 1'bx)
                begin
                   bar_ok = 1'b0;
                   // Clean up the X's...
                   bars[nbar] = {{60{1'b0}},bars[nbar][3:0]} ;
                end
              bars_xhdl = bars[nbar];
              if ((bars_xhdl[2]) != 1'b1)
                begin
                   shmem_write(bar_table + (nbar * 4), bars_xhdl[31:0], 4);
                   nbar = nbar + 1;
                end
            else
              begin
                 shmem_write(bar_table + (nbar * 4), bars_xhdl[63:0], 8);
                 nbar = nbar + 2;
              end
           end
         // Temporarily turn on the lowest bit of the ExpROM BAR so it is enabled
         shmem_write(bar_table + 24, 8'h01, 1) ;
         cfg_wr_bars(bnm, dev, fnc, bar_table, typ1);
         // Turn off the lowest bit of the ExpROM BAR so rest of the BFM knows it is a memory BAR
         shmem_write(bar_table + 24, 8'h00, 1) ;
         if (display == 1)
           begin
              dummy = ebfm_display(EBFM_MSG_INFO, "");
           end
         m64max = m64max_v;
         m64min = m64min_v;
         m32max = m32max_v;
         m32min = m32min_v;
         io_max = io_max_v[31:0];
         io_min = io_min_v[31:0];
      end
   endtask

   task ebfm_display_link_status_reg;
      input root_port;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;

      reg[2:0] compl_status;
      reg[15:0] link_sts;
      reg[15:0] link_ctrl;
      reg[15:0] link_cap;

      reg dummy ;

      begin
         ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 16, 4, CFG_SCRATCH_SPACE, compl_status);
         link_sts  = shmem_read(CFG_SCRATCH_SPACE + 2, 2);
         link_ctrl = shmem_read(CFG_SCRATCH_SPACE,2);
         ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 12, 4, CFG_SCRATCH_SPACE, compl_status);
         link_cap = shmem_read(CFG_SCRATCH_SPACE ,2);
         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Link Status Register (", himage4(link_sts), "):"});
         else
             dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Link Status Register (", himage4(link_sts), "):"});

         dummy = ebfm_display(EBFM_MSG_INFO, {"    Negotiated Link Width: x", dimage1(link_sts[9:4])}) ;

         if ((link_sts[12]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "        Slot Clock Config: System Reference Clock Used");
        // Setting common clk cfg bit
        link_ctrl = 16'h0040 | link_ctrl;
        ebfm_cfgwr_imm_wait(bnm,dev,fnc,144,2, {16'h0000, link_ctrl}, compl_status);
       // retrain the link
       ebfm_cfgwr_imm_wait(RP_PRI_BUS_NUM,RP_PRI_DEV_NUM,fnc,144,2, 32'h0000_0060, compl_status);
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "        Slot Clock Config: Local Clock Used");
         end

         if (root_port==1) // dummy read to wait for link to come up
           ebfm_cfgrd_wait(1, 1, fnc, PCIE_CAP_PTR + 16, 4, CFG_SCRATCH_SPACE, compl_status);

         // check link speed
         ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 16, 4, CFG_SCRATCH_SPACE, compl_status);
         link_sts  = shmem_read(CFG_SCRATCH_SPACE + 2, 2);
         if (link_sts[3:0] == 4'h1)
           dummy = ebfm_display(EBFM_MSG_INFO, {"       Current Link Speed: 2.5GT/s"}) ;
         else if (link_sts[3:0] == 4'h2)
           dummy = ebfm_display(EBFM_MSG_INFO, {"       Current Link Speed: 5.0GT/s"}) ;
         else
           dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, {"       Current Link Speed is Unsupported"}) ;

         if (link_sts[3:0] != link_cap[3:0]) // link is not at its full speed
       begin
       ebfm_cfgwr_imm_wait(RP_PRI_BUS_NUM,RP_PRI_DEV_NUM,fnc,144,2, 32'h0000_0020, compl_status);
           ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 16, 4, CFG_SCRATCH_SPACE, compl_status);

         if (root_port==1) // dummy read to wait for link to come up
           ebfm_cfgrd_wait(1, 1, fnc, PCIE_CAP_PTR + 16, 4, CFG_SCRATCH_SPACE, compl_status);
       // Make sure the config Rd is not sent before the retraining starts
           ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 16, 4, CFG_SCRATCH_SPACE, compl_status);
           link_sts  = shmem_read(CFG_SCRATCH_SPACE + 2, 2);
           if (link_sts[3:0] == 4'h1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"           New Link Speed: 2.5GT/s"}) ;
           else if (link_sts[3:0] == 4'h2)
             dummy = ebfm_display(EBFM_MSG_INFO, {"           New Link Speed: 5.0GT/s"}) ;
       else
             dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, {"       New Link Speed is Unsupported"}) ;

       end

         if (link_sts[3:0] != link_cap[3:0])
           dummy = ebfm_display(EBFM_MSG_INFO, "           Link fails to operate at Maximum Rate") ;




     dummy = ebfm_display(EBFM_MSG_INFO,"");


      end
   endtask

   task ebfm_display_link_control_reg;
      input root_port;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;
      reg[2:0] compl_status;
      reg[15:0] link_ctrl;
      reg dummy;
      begin
         ebfm_cfgrd_wait(bnm,dev,fnc,PCIE_CAP_PTR+16,4,CFG_SCRATCH_SPACE,compl_status);
     link_ctrl = shmem_read(CFG_SCRATCH_SPACE,2);
     if (root_port==1)
         dummy = ebfm_display(EBFM_MSG_INFO,{"  RP PCI Express Link Control Register (", himage4(link_ctrl), "):"} );
     else
         dummy = ebfm_display(EBFM_MSG_INFO,{"  EP PCI Express Link Control Register (", himage4(link_ctrl), "):"} );

     if (link_ctrl[6] == 1'b1)
     begin
        dummy = ebfm_display(EBFM_MSG_INFO,"      Common Clock Config: System Reference Clock Used") ;
     end
     else
     begin
        dummy = ebfm_display(EBFM_MSG_INFO,"      Common Clock Config: Local Clock Used") ;
     end
     dummy = ebfm_display(EBFM_MSG_INFO,"");
      end
   endtask

   task ebfm_display_dev_control_status_reg;
      input root_port;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;

      reg[2:0] compl_status;
      reg[31:0] dev_cs;

      reg dummy ;

      begin
         ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 8, 4,
         CFG_SCRATCH_SPACE, compl_status);
         dev_cs = shmem_read(CFG_SCRATCH_SPACE, 4);
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Device Control Register (",
                                                  himage4(dev_cs[15:0]), "):"});
         else
             dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Device Control Register (",
                                                  himage4(dev_cs[15:0]), "):"});

         dummy = ebfm_display(EBFM_MSG_INFO, {"  Error Reporting Enables: ",
                                              himage1(dev_cs[3:0])});
         if ((dev_cs[4]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "         Relaxed Ordering: Enabled");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "         Relaxed Ordering: Disabled");
         end
         case (dev_cs[7:5])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "              Max Payload: 128 Bytes");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "              Max Payload: 256 Bytes");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "              Max Payload: 512 Bytes");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "              Max Payload: 1KBytes");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "              Max Payload: 2KBytes");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "              Max Payload: 4KBytes");
            default :
                     begin
                        dummy = ebfm_display(EBFM_MSG_INFO,
                                             {"              Max Payload: Unknown",
                                              himage1(dev_cs[2:0])});
                     end
         endcase
         if ((dev_cs[8]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "             Extended Tag: Enabled");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "             Extended Tag: Disabled");
         end
         case (dev_cs[14:12])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "         Max Read Request: 128 Bytes");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "         Max Read Request: 256 Bytes");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "         Max Read Request: 512 Bytes");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "         Max Read Request: 1KBytes");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "         Max Read Request: 2KBytes");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "         Max Read Request: 4KBytes");
            default :
                     begin
                        dummy = ebfm_display(EBFM_MSG_INFO, {"         Max Read Request: Unknown",
                                                             himage1(dev_cs[2:0])});
                     end
         endcase
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Device Status Register (",
                                                  himage4(dev_cs[31:16]), "):"});
         else
             dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Device Status Register (",
                                                  himage4(dev_cs[31:16]), "):"});
         dummy = ebfm_display(EBFM_MSG_INFO, "");
      end
   endtask

   // purpose: display PCI Express Capability Info
   task display_pcie_cap;
      input       root_port;
      input[31:0] pcie_cap;
      input[31:0] dev_cap;
      input[31:0] link_cap;
      input[31:0] dev_cap2;

      integer pwr_limit;
      reg l;

      reg dummy ;




      begin
         // display_pcie_cap
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Capabilities Register (",
                                                  himage4(pcie_cap[31:16]), "):"});
         else
             dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Capabilities Register (",
                                                  himage4(pcie_cap[31:16]), "):"});

         dummy = ebfm_display(EBFM_MSG_INFO, {"       Capability Version: ",
                                              himage1(pcie_cap[19:16])});
         case (pcie_cap[23:20])
            4'b0000 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: Native Endpoint");
            4'b0001 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: Legacy Endpoint");
            4'b0100 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: Root Port");
            4'b0101 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: Switch Upstream port");
            4'b0110 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: Switch Downstream port");
            4'b0111 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: Express-to-PCI bridge");
            4'b1000 : dummy = ebfm_display(EBFM_MSG_INFO, "                Port Type: PCI-to-Express bridge");
            default : dummy = ebfm_display(EBFM_MSG_INFO, {"                Port Type: UNKNOWN", himage1(pcie_cap[23:20])});
         endcase
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Device Capabilities Register (",
                                                  himage8(dev_cap), "):"});
         else
             dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Device Capabilities Register (",
                                                  himage8(dev_cap), "):"});

         case (dev_cap[2:0])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "    Max Payload Supported: 128 Bytes");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "    Max Payload Supported: 256 Bytes");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "    Max Payload Supported: 512 Bytes");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "    Max Payload Supported: 1KBytes");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "    Max Payload Supported: 2KBytes");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "    Max Payload Supported: 4KBytes");
            default : dummy = ebfm_display(EBFM_MSG_INFO, {"    Max Payload Supported: Unknown", himage1(dev_cap[2:0])});
         endcase
         if ((dev_cap[5]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "             Extended Tag: Supported");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "             Extended Tag: Not Supported");
         end
         case (dev_cap[8:6])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: Less Than 64 ns");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: 64 ns to 128 ns");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: 128 ns to 256 ns");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: 256 ns to 512 ns");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: 512 ns to 1 us");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: 1 us to 2 us");
            3'b110 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: 2 us to 4 us");
            3'b111 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L0s Latency: More than 4 us");
            default :
                     begin
                     end
         endcase
         case (dev_cap[11:9])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: Less Than 1 us");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: 1 us to 2 us");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: 2 us to 4 us");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: 4 us to 8 us");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: 8 us to 16 us");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: 16 us to 32 us");
            3'b110 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: 32 us to 64 us");
            3'b111 : dummy = ebfm_display(EBFM_MSG_INFO, "   Acceptable L1  Latency: More than 64 us");
            default :
                     begin
                     end
         endcase
         if ((dev_cap[12]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "         Attention Button: Present");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "         Attention Button: Not Present");
         end
         if ((dev_cap[13]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "      Attention Indicator: Present");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "      Attention Indicator: Not Present");
         end
         if ((dev_cap[14]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "          Power Indicator: Present");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "          Power Indicator: Not Present");
         end
         dummy = ebfm_display(EBFM_MSG_INFO, "");

         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Link Capabilities Register (",
                                                  himage8(link_cap), "):"});
         else
             dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Link Capabilities Register (",
                                                  himage8(link_cap), "):"});

         dummy = ebfm_display(EBFM_MSG_INFO, {"       Maximum Link Width: x",
                                              dimage1(link_cap[9:4])}) ;

         if (link_cap[3:0] == 4'h1)
           dummy = ebfm_display(EBFM_MSG_INFO, {"     Supported Link Speed: 2.5GT/s"}) ;
         else if (link_cap[3:0] == 4'h2)
           dummy = ebfm_display(EBFM_MSG_INFO, {"     Supported Link Speed: 5.0GT/s or 2.5GT/s"}) ;
         else
           dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, {"     Supported Link Speed: Undefined"}) ;

         if ((link_cap[10]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "                L0s Entry: Supported");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "                L0s Entry: Not Supported");
         end
         if ((link_cap[11]) == 1'b1)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "                L1  Entry: Supported");
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, "                L1  Entry: Not Supported");
         end
         case (link_cap[14:12])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: Less Than 64 ns");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: 64 ns to 128 ns");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: 128 ns to 256 ns");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: 256 ns to 512 ns");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: 512 ns to 1 us");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: 1 us to 2 us");
            3'b110 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: 2 us to 4 us");
            3'b111 : dummy = ebfm_display(EBFM_MSG_INFO, "         L0s Exit Latency: More than 4 us");
            default :
                     begin
                     end
         endcase
         case (link_cap[17:15])
            3'b000 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: Less Than 1 us");
            3'b001 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: 1 us to 2 us");
            3'b010 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: 2 us to 4 us");
            3'b011 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: 4 us to 8 us");
            3'b100 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: 8 us to 16 us");
            3'b101 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: 16 us to 32 us");
            3'b110 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: 32 us to 64 us");
            3'b111 : dummy = ebfm_display(EBFM_MSG_INFO, "         L1  Exit Latency: More than 64 us");
            default :
                     begin
                     end
         endcase
         dummy = ebfm_display(EBFM_MSG_INFO, {"              Port Number: ", himage2(link_cap[31:24])});


       if (link_cap[19] == 1'b1)
             dummy = ebfm_display(EBFM_MSG_INFO, "  Surprise Dwn Err Report: Supported");
       else
             dummy = ebfm_display(EBFM_MSG_INFO, "  Surprise Dwn Err Report: Not Supported");

       if (link_cap[20] == 1'b1)
             dummy = ebfm_display(EBFM_MSG_INFO, "   DLL Link Active Report: Supported");
       else
             dummy = ebfm_display(EBFM_MSG_INFO, "   DLL Link Active Report: Not Supported");


           dummy = ebfm_display(EBFM_MSG_INFO, "");


         // Spec 2.0 Caps
         if (pcie_cap[19:16] == 4'h2)
       begin

       if (root_port==1)
           dummy = ebfm_display(EBFM_MSG_INFO, {"  RP PCI Express Device Capabilities 2 Register (",
                            himage8(dev_cap2), "):"});
       else
           dummy = ebfm_display(EBFM_MSG_INFO, {"  EP PCI Express Device Capabilities 2 Register (",
                            himage8(dev_cap2), "):"});

       if (dev_cap2[4] == 1'b1)
         case (dev_cap2[3:0])
         4'h0: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: Not Supported");
         4'h1: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: A (50us to 10ms)");
         4'h2: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: B (10ms to 250ms)");
         4'h3: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: AB (50us to 250ms)");
         4'h6: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: BC (10ms to 4s)");
         4'h7: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: ABC (50us to 4s)");
         4'hE: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: BCD (10ms to 64s)");
         4'hF: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: ABCD (50us to 64s)");
         default: dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: Reserved");
         endcase
       else
         dummy = ebfm_display(EBFM_MSG_INFO, "  Completion Timeout Rnge: Not Supported");

       end






      end
   endtask



   // purpose: configure the PCI Express Capabilities
   task ebfm_cfg_pcie_cap;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;
      input rp_max_rd_req_size;
      integer rp_max_rd_req_size;
      input display;
      integer display;
      input display_rp_config;
      integer display_rp_config;


      reg[2:0] compl_status;
      integer EP_PCIE_CAP ;
      integer EP_DEV_CAP ;
      integer EP_DEV_CAP2 ;
      integer EP_DEV_CTRL2 ;
      integer EP_LINK_CTRL2 ;
      integer EP_LINK_CAP ;
      integer RP_PCIE_CAP ;
      integer RP_DEV_CAP ;
      integer RP_DEV_CS;
      integer RP_LINK_CTRL;
      integer RP_DEV_CAP2;
      integer RP_LINK_CAP;
      reg[31:0] ep_pcie_cap_r;
      reg[31:0] rp_pcie_cap_r;
      reg[31:0] ep_dev_cap_r;
      reg[31:0] rp_dev_cap_r;
      reg[15:0] ep_dev_control;
      reg[15:0] rp_dev_control;
      reg[15:0] rp_dev_cs;
      integer max_size;

      reg dummy ;

      begin // ebfm_cfg_pcie_cap
         ep_dev_control = {16{1'b0}} ;
         rp_dev_control = {16{1'b0}} ;
         EP_PCIE_CAP = CFG_SCRATCH_SPACE + 0;
         EP_DEV_CAP  = CFG_SCRATCH_SPACE + 4;
         EP_LINK_CAP = CFG_SCRATCH_SPACE + 8;
         RP_PCIE_CAP = CFG_SCRATCH_SPACE + 16;
         RP_DEV_CAP  = CFG_SCRATCH_SPACE + 20;
         EP_DEV_CAP2  = CFG_SCRATCH_SPACE + 24;
         RP_DEV_CS   = CFG_SCRATCH_SPACE + 36;
         RP_LINK_CTRL = CFG_SCRATCH_SPACE + 40;
         RP_DEV_CAP2  = CFG_SCRATCH_SPACE + 44;
         RP_LINK_CAP  = CFG_SCRATCH_SPACE + 48;
         // Read the EP PCI Express Capabilities (at a known address in the MegaCore
         // function)
         if (display == 1)
         begin
            ebfm_display_link_status_reg(0, bnm,dev,fnc,CFG_SCRATCH_SPACE+32);
            ebfm_display_link_control_reg(0, bnm,dev,fnc,CFG_SCRATCH_SPACE+32);
         end
         if (display_rp_config==1) begin
            ebfm_display_link_status_reg(1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, RP_LINK_CTRL);
            ebfm_display_link_control_reg(1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, RP_LINK_CTRL);
         end



         ebfm_cfgrd_nowt(bnm, dev, fnc, PCIE_CAP_PTR, 4, EP_PCIE_CAP);
         ebfm_cfgrd_nowt(bnm, dev, fnc, PCIE_CAP_PTR + 4, 4, EP_DEV_CAP);
         ebfm_cfgrd_nowt(bnm, dev, fnc, PCIE_CAP_PTR + 36, 4, EP_DEV_CAP2);
         ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 12, 4, EP_LINK_CAP, compl_status);
         ebfm_cfgrd_nowt(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, 128, 4, RP_PCIE_CAP);
       //  ebfm_cfgrd_nowt(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, 128, 4, RP_DEV_CS);
         ebfm_cfgrd_nowt(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, 128 + 36, 4, RP_DEV_CAP2);
         ebfm_cfgrd_nowt(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, 128 + 12, 4, RP_LINK_CAP);
         ebfm_cfgrd_wait(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, 132 , 4, RP_DEV_CAP, compl_status);
         ep_pcie_cap_r = shmem_read(EP_PCIE_CAP, 4);
         rp_pcie_cap_r = shmem_read(RP_PCIE_CAP, 4);
         ep_dev_cap_r = shmem_read(EP_DEV_CAP, 4);
         rp_dev_cap_r = shmem_read(RP_DEV_CAP, 4);
         if (ep_pcie_cap_r[7:0] != 8'h10)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, "PCI Express Capabilities not at expected Endpoint config address");
         end
         if (rp_pcie_cap_r[7:0] != 8'h10)
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL_TB_ERR, "PCI Express Capabilities not at expected Root Port config address");
         end
         if (display == 1)
         begin
            display_pcie_cap(
                 0,
                 ep_pcie_cap_r,
                 ep_dev_cap_r,
                 shmem_read(EP_LINK_CAP, 4),
                 shmem_read(EP_DEV_CAP2, 4)
                 );
          end
          if (display_rp_config==1) begin
                display_pcie_cap(
                     1,
                     rp_pcie_cap_r,
                     rp_dev_cap_r,
                     shmem_read(RP_LINK_CAP, 4),
                     shmem_read(RP_DEV_CAP2, 4)
                 );
          end


         // Error Reporting Enables (RP BFM does not handle for now)
         ep_dev_control[3:0] = {4{1'b0}};
         rp_dev_control[3:0] = {4{1'b0}};
         // Enable Relaxed Ordering
         ep_dev_control[4] = 1'b1;
         rp_dev_control[4] = 1'b1;
         // Enable Extended Tag if requested for EP
         ep_dev_control[8] = ep_dev_cap_r[5];
         if (EBFM_NUM_TAG > 32)
         begin
            rp_dev_control[8] = 1'b1;
         end
         else
         begin
            rp_dev_control[8] = 1'b0;
         end
         // Disable Phantom Functions
         ep_dev_control[9] = 1'b0;
         rp_dev_control[9] = 1'b0;
         // Disable Aux Power PM Enable
         ep_dev_control[10] = 1'b0;
         rp_dev_control[10] = 1'b0;
         // Disable No Snoop
         ep_dev_control[11] = 1'b0;
         rp_dev_control[11] = 1'b0;
         if (ep_dev_cap_r[2:0] < rp_dev_cap_r[2:0])
         begin
            // Max Payload Size
            ep_dev_control[7:5] = ep_dev_cap_r[2:0];
            rp_dev_control[7:5] = ep_dev_cap_r[2:0];
            // Max Read Request Size
            // Note the reference design can break up the read requests into smaller
            // completion packets, so we can go for the full 4096 bytes. But the
            // root port BFM can't create multiple completions, so tell the endpoint
            // to be restricted to the max payload size
            ep_dev_control[14:12] = ep_dev_cap_r[2:0];
            rp_dev_control[14:12] = 3'b101;
         end
         else
         begin
            // Max Payload Size
            ep_dev_control[7:5] = rp_dev_cap_r[2:0];
            rp_dev_control[7:5] = rp_dev_cap_r[2:0];
            // Max Read Request Size
            // Note the reference design can break up the read requests into smaller
            // completion packets, so we can go for the full 4096 bytes. But the
            // root port BFM can't create multiple completions, so tell the endpoint
            // to be restricted to the max payload size
            ep_dev_control[14:12] = rp_dev_cap_r[2:0];
            rp_dev_control[14:12] = 3'b101;
         end
         case (ep_dev_control[7:5])
            3'b000 : max_size = 128;
            3'b001 : max_size = 256;
            3'b010 : max_size = 512;
            3'b011 : max_size = 1024;
            3'b100 : max_size = 2048;
            3'b101 : max_size = 4096;
            default : max_size = 128;
         endcase
         // Tell the BFM what the limits are...
         req_intf_set_max_payload(max_size, max_size, rp_max_rd_req_size);
         ebfm_cfgwr_imm_nowt(bnm, dev, fnc, PCIE_CAP_PTR + 8, 4, {16'h0000, ep_dev_control});
         ebfm_cfgwr_imm_nowt(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, PCIE_CAP_PTR + 8, 4, {16'h0000, rp_dev_control});

         if (display == 1)
         begin
             ebfm_display_dev_control_status_reg(0, bnm, dev, fnc, CFG_SCRATCH_SPACE + 32);
             ebfm_display_vc(0, bnm,dev,fnc,CFG_SCRATCH_SPACE + 32) ;
         end
         if (display_rp_config==1) begin
             ebfm_display_dev_control_status_reg(1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, RP_LINK_CTRL);
             ebfm_display_vc(1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, RP_LINK_CTRL) ;
         end

      end
   endtask

   // purpose: Display the "critical" BARs
   task ebfm_display_read_only;
      input root_port;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;

      reg[2:0] compl_status;

      reg dummy ;

      begin



         // ebfm_display_read_only
         ebfm_cfgrd_nowt(bnm, dev, fnc, 0, 4, CFG_SCRATCH_SPACE);
         ebfm_cfgrd_nowt(bnm, dev, fnc, 8, 4, CFG_SCRATCH_SPACE + 8);
         ebfm_cfgrd_nowt(bnm, dev, fnc, 44, 4, CFG_SCRATCH_SPACE + 4);
         ebfm_cfgrd_nowt(bnm, dev, fnc, 60, 4, CFG_SCRATCH_SPACE + 16);
         ebfm_cfgrd_wait(bnm, dev, fnc, 12, 4, CFG_SCRATCH_SPACE + 12, compl_status);
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         dummy = ebfm_display(EBFM_MSG_INFO, {"Configuring Bus ", dimage3(bnm),
                                              ", Device ", dimage3(dev),
                                              ", Function ", dimage2(fnc)});

         if (root_port==1)
             dummy = ebfm_display(EBFM_MSG_INFO, "  RP Read Only Configuration Registers:");
         else
             dummy = ebfm_display(EBFM_MSG_INFO, "  EP Read Only Configuration Registers:");

         dummy = ebfm_display(EBFM_MSG_INFO, {"                Vendor ID: ",
         himage4(shmem_read(CFG_SCRATCH_SPACE, 2))});
         dummy = ebfm_display(EBFM_MSG_INFO, {"                Device ID: ",
         himage4(shmem_read(CFG_SCRATCH_SPACE + 2, 2))});
         dummy = ebfm_display(EBFM_MSG_INFO, {"              Revision ID: ",
         himage2(shmem_read(CFG_SCRATCH_SPACE + 8, 1))});
         dummy = ebfm_display(EBFM_MSG_INFO, {"               Class Code: ",
                                              himage2(shmem_read(CFG_SCRATCH_SPACE + 11, 1)),
                                              himage4(shmem_read(CFG_SCRATCH_SPACE + 9, 2))});
         if (shmem_read(CFG_SCRATCH_SPACE + 14, 1) == 8'h00)
         begin
            dummy = ebfm_display(EBFM_MSG_INFO, {"      Subsystem Vendor ID: ",
                                                 himage4(shmem_read(CFG_SCRATCH_SPACE + 4, 2))});
            dummy = ebfm_display(EBFM_MSG_INFO, {"             Subsystem ID: ",
                                                 himage4(shmem_read(CFG_SCRATCH_SPACE + 6, 2))});
         end
         case (shmem_read(CFG_SCRATCH_SPACE + 17,1))
            8'h00 : dummy = ebfm_display(EBFM_MSG_INFO,"            Interrupt Pin: No INTx# pin used");
            8'h01 : dummy = ebfm_display(EBFM_MSG_INFO,"            Interrupt Pin: INTA# used");
            8'h02 : dummy = ebfm_display(EBFM_MSG_INFO,"            Interrupt Pin: INTB# used");
            8'h03 : dummy = ebfm_display(EBFM_MSG_INFO,"            Interrupt Pin: INTC# used");
            8'h04 : dummy = ebfm_display(EBFM_MSG_INFO,"            Interrupt Pin: INTD# used");
            default: dummy = ebfm_display(EBFM_MSG_ERROR_FATAL,"            Interrupt Pin: Interrupt Pin Register has Illegal Value.");
         endcase
         dummy = ebfm_display(EBFM_MSG_INFO, "");
      end
   endtask

   // purpose: Display the root port BARs
   task ebfm_display_rp_bar;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;

      reg[2:0] compl_status;

      reg dummy ;
      reg [63:0] bar;
      integer i,j,k,bar_lsb;

      begin

         // find bar size
         ebfm_cfgwr_imm_wait(bnm,dev,fnc,16,4, 32'hFFFF_FFFF, compl_status);
         ebfm_cfgwr_imm_wait(bnm,dev,fnc,20,4, 32'hFFFF_FFFF, compl_status);
         // don't enable expansion ROM BAR
         ebfm_cfgwr_imm_wait(bnm,dev,fnc,56,4, 32'hFFFF_FFFE, compl_status);
         // I/O base and limit
         ebfm_cfgwr_imm_wait(bnm,dev,fnc,28,2, 16'hFFFF, compl_status);
         // Prefet base and limit
         ebfm_cfgwr_imm_wait(bnm,dev,fnc,36,4, 32'hFFFF_FFFF, compl_status);

         ebfm_cfgrd_wait(bnm, dev, fnc, 16, 4, CFG_SCRATCH_SPACE, compl_status);
         ebfm_cfgrd_wait(bnm, dev, fnc, 20, 4, CFG_SCRATCH_SPACE + 4, compl_status);
         ebfm_cfgrd_wait(bnm, dev, fnc, 56, 4, CFG_SCRATCH_SPACE + 8, compl_status);
         ebfm_cfgrd_wait(bnm, dev, fnc, 28, 4, CFG_SCRATCH_SPACE + 12, compl_status);
         ebfm_cfgrd_wait(bnm, dev, fnc, 36, 4, CFG_SCRATCH_SPACE + 16, compl_status);

         dummy = ebfm_display(EBFM_MSG_INFO, "  RP Base Address Registers:");

         dummy = ebfm_display(EBFM_MSG_INFO, "");
         dummy = ebfm_display(EBFM_MSG_INFO, "BAR Address Assignments:");
         dummy = ebfm_display(EBFM_MSG_INFO, {"BAR   ", " ", "Size      ", " ", "Assigned Address ", " ", "Type"});
         dummy = ebfm_display(EBFM_MSG_INFO, {"---   ", " ", "----      ", " ", "---------------- ", " "});
         bar = shmem_read(CFG_SCRATCH_SPACE, 8);

         for (i = 0; i < 2; i = i + 1)
           begin
              bar_lsb = 64;
              
              if (bar[2] == 1'b1) // extend the end limit for 64 bit BAR
                k = 1;
              else
                k = 0;
              
              // find first one
              begin : find_first
                 for(j = 4; j <= k*32 + 31; j = j + 1)
                   begin : lsb_loop
                      if ((bar[j]) == 1'b1)
                        begin
                           bar_lsb = j ;
                           disable find_first ;
                        end
                   end
              end
              
              describe_bar(i,bar_lsb,bar,1'b1);
              if (bar[2] == 1'b1)  // Found 64 bit BAR 
                i = i + 1;
              else
                // Move the second BAR to first position for second time around
                bar[31:0] = bar[63:32] ;
                           
           end // for (i = 0; i < 2; i = i + 1)

         // expansion rom
         bar = 0;
         bar = shmem_read(CFG_SCRATCH_SPACE + 8, 4);
         bar_lsb = 64;
         
         begin : ff_eeprom
            for(j = 4 ; j <= 31; j = j + 1)
              begin : loop_eeprom
                 if ((bar[j]) == 1'b1)
                   begin
                      bar_lsb = j;
                      disable ff_eeprom ;
                   end
              end
         end
         describe_bar(6,bar_lsb,bar,1'b1);
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         
         // check IO base/limit
         bar = 0;
         bar = shmem_read(CFG_SCRATCH_SPACE +12, 2);
         if (bar[31:0] == 0)
           dummy = ebfm_display(EBFM_MSG_INFO,"   I/O Base and Limit Register: Disable ");
         else if (bar[0] == 0)
           dummy = ebfm_display(EBFM_MSG_INFO,"   I/O Base and Limit Register: 16Bit ");
         else if (bar[0] == 1)
           dummy = ebfm_display(EBFM_MSG_INFO,"   I/O Base and Limit Register: 32Bit ");
         else
           dummy = ebfm_display(EBFM_MSG_INFO,"   I/O Base and Limit Register: Reserved ");
         
         // check Prefetchable Memory base/limit
         bar = 0;
         bar = shmem_read(CFG_SCRATCH_SPACE + 16, 4);
         if (bar[31:0] == 0)
           dummy = ebfm_display(EBFM_MSG_INFO,"   Prefetchable Base and Limit Register: Disable ");
         else if (bar[3:0] == 0) //
           dummy = ebfm_display(EBFM_MSG_INFO,"   Prefetchable Base and Limit Register: 32Bit ");
         else if (bar[3:0] == 1)
           dummy = ebfm_display(EBFM_MSG_INFO,"   Prefetchable Base and Limit Register: 64Bit ");
         else
           dummy = ebfm_display(EBFM_MSG_INFO,"   Prefetchable Base and Limit Register: Reserved ");
         
         dummy = ebfm_display(EBFM_MSG_INFO, "");
         

      end
   endtask


   // purpose: Display the MSI Information
   task ebfm_display_msi;
       input bnm;
       integer bnm;
       input dev;
       integer dev;
       input fnc;
       integer fnc;
       input CFG_SCRATCH_SPACE;
       integer CFG_SCRATCH_SPACE;

       reg [2:0] compl_status;
       reg[15:0] message_control_r;

       reg dummy ;

       begin
          ebfm_cfgrd_wait(bnm, dev, fnc, 80, 4, CFG_SCRATCH_SPACE, compl_status);
          dummy = ebfm_display(EBFM_MSG_INFO,"  PCI MSI Capability Register:") ;
          message_control_r = shmem_read(CFG_SCRATCH_SPACE+2,2) ;
          if (message_control_r[7] == 1'b1)
             dummy = ebfm_display(EBFM_MSG_INFO,"   64-Bit Address Capable: Supported");
          else
             dummy = ebfm_display(EBFM_MSG_INFO,"   64-Bit Address Capable: Not Supported");
          case (message_control_r[3:1])
             3'b000 : dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested:  1") ;
             3'b001 : dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested:  2") ;
             3'b010 : dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested:  4") ;
             3'b011 : dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested:  8") ;
             3'b100 : dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested: 16") ;
             3'b101 : dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested: 32") ;
             default: dummy = ebfm_display(EBFM_MSG_INFO,"       Messages Requested: Reserved") ;
          endcase
       dummy = ebfm_display(EBFM_MSG_INFO,"") ;
       end
   endtask

   // purpose: Display the MSI-X Information
   task ebfm_display_msix;
       input bnm;
       integer bnm;
       input dev;
       integer dev;
       input fnc;
       integer fnc;
       input CFG_SCRATCH_SPACE;
       integer CFG_SCRATCH_SPACE;

       reg [2:0] compl_status;
       reg [31:0] dword;

       reg dummy ;

       begin
          ebfm_cfgwr_imm_wait(bnm,dev,fnc,104,4, 32'h8000_0000, compl_status);
          ebfm_cfgrd_wait(bnm, dev, fnc, 104, 4, CFG_SCRATCH_SPACE, compl_status);
          dword = shmem_read(CFG_SCRATCH_SPACE,4) ;
          if (dword[31] == 1'b1) // check for implementation
        begin
            dummy = ebfm_display(EBFM_MSG_INFO,"  PCI MSI-X Capability Register:") ;
            dummy = ebfm_display(EBFM_MSG_INFO, {"               Table Size: ", himage4(dword[26:16])});

            ebfm_cfgrd_wait(bnm, dev, fnc, 108, 4, CFG_SCRATCH_SPACE, compl_status);
            dword = shmem_read(CFG_SCRATCH_SPACE,4) ;
            dummy = ebfm_display(EBFM_MSG_INFO, {"                Table BIR: ", himage1(dword[2:0])});
            dummy = ebfm_display(EBFM_MSG_INFO, {"             Table Offset: ", himage8(dword[31:3])});

            ebfm_cfgrd_wait(bnm, dev, fnc, 112, 4, CFG_SCRATCH_SPACE, compl_status);
            dword = shmem_read(CFG_SCRATCH_SPACE,4) ;
            dummy = ebfm_display(EBFM_MSG_INFO, {"                  PBA BIR: ", himage1(dword[2:0])});
            dummy = ebfm_display(EBFM_MSG_INFO, {"               PBA Offset: ", himage8(dword[31:3])});

        dummy = ebfm_display(EBFM_MSG_INFO,"") ;

        // Disable MSIX
            ebfm_cfgwr_imm_wait(bnm,dev,fnc,104,4, 32'h0000_0000, compl_status);
        end
       end
    endtask

   // purpose: Display the Advance Error Reporting Information
   task ebfm_display_aer;
       input root_port;
       input bnm;
       integer bnm;
       input dev;
       integer dev;
       input fnc;
       integer fnc;
       input CFG_SCRATCH_SPACE;
       integer CFG_SCRATCH_SPACE;

       reg [2:0] compl_status;
       reg [31:0] dword;

       reg dummy ;

       begin
          ebfm_cfgrd_wait(bnm, dev, fnc, 2048, 4, CFG_SCRATCH_SPACE, compl_status);
          dword = shmem_read(CFG_SCRATCH_SPACE,4) ;
          if (dword[15:0] == 16'h0001) // check for implementation
        begin
            if (root_port==1)
                dummy = ebfm_display(EBFM_MSG_INFO,"  RP PCI Express AER Capability Register:") ;
            else
                dummy = ebfm_display(EBFM_MSG_INFO,"  EP PCI Express AER Capability Register:") ;

        // turn on check and gen on root port
        ebfm_cfgwr_imm_wait(RP_PRI_BUS_NUM,RP_PRI_DEV_NUM,fnc,2072,2, 16'h0140, compl_status);

            ebfm_cfgrd_wait(bnm, dev, fnc, 2072, 4, CFG_SCRATCH_SPACE, compl_status);
            dword = shmem_read(CFG_SCRATCH_SPACE,4) ;

        ebfm_cfgwr_imm_wait(bnm,dev,fnc,2072,2, {dword[14:0],1'b0}, compl_status);
        if (dword[7] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"       ECRC Check Capable: Supported"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"       ECRC Check Capable: Not Supported"});

        if (dword[5] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"  ECRC Generation Capable: Supported"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"  ECRC Generation Capable: Not Supported"});

        dummy = ebfm_display(EBFM_MSG_INFO,"") ;
        end

       end
    endtask


   // purpose: Display the Advance Error Reporting Information
   task ebfm_display_slot_cap;
       input root_port;
       input bnm;
       integer bnm;
       input dev;
       integer dev;
       input fnc;
       integer fnc;
       input CFG_SCRATCH_SPACE;
       integer CFG_SCRATCH_SPACE;

       reg [2:0] compl_status;
       reg [31:0] dword;

       reg dummy ;

       begin
          // read the Slot Capability Register
          ebfm_cfgrd_wait(bnm, dev, fnc, PCIE_CAP_PTR + 20, 4, CFG_SCRATCH_SPACE, compl_status);
          dword = shmem_read(CFG_SCRATCH_SPACE,4) ;


        if (root_port==1)
            dummy = ebfm_display(EBFM_MSG_INFO,{"   RP PCI Express Slot Capability Register (", himage8(dword), "):"});
        else
            dummy = ebfm_display(EBFM_MSG_INFO,{"   EP PCI Express Slot Capability Register (", himage8(dword), "):"});


        if (dword[0] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"       Attention Button: Present"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"       Attention Button: Not Present"});


        if (dword[1] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"       Power Controller: Present"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"       Power Controller: Not Present"});


        if (dword[2] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"             MRL Sensor: Present"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"             MRL Sensor: Not Present"});


        if (dword[3] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"    Attention Indicator: Present"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"    Attention Indicator: Not Present"});

        if (dword[4] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"        Power Indicator: Present"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"        Power Indicator: Not Present"});

        if (dword[5] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"      Hot-Plug Surprise: Supported"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"      Hot-Plug Surprise: Not Supported"});

        if (dword[6] == 1'b1)
              dummy = ebfm_display(EBFM_MSG_INFO, {"       Hot-Plug Capable: Supported"});
        else
              dummy = ebfm_display(EBFM_MSG_INFO, {"       Hot-Plug Capable: Not Supported"});


        dummy = ebfm_display(EBFM_MSG_INFO,{"        Slot Power Limit Value: ", himage1(dword[14:7])}) ;

        dummy = ebfm_display(EBFM_MSG_INFO,{"        Slot Power Limit Scale: ", himage1(dword[16:15])}) ;

        dummy = ebfm_display(EBFM_MSG_INFO,{"          Physical Slot Number: ", himage1(dword[31:19])}) ;

        dummy = ebfm_display(EBFM_MSG_INFO,"") ;


       end
    endtask


    // purpose: Display the Virtual Channel Capabilities
   task ebfm_display_vc;
      input root_port;
      input bnm;
      integer bnm;
      input dev;
      integer dev;
      input fnc;
      integer fnc;
      input CFG_SCRATCH_SPACE;
      integer CFG_SCRATCH_SPACE;

      reg [2:0] compl_status;
      reg[15:0] port_vc_cap_r;
      reg [2:0] low_vc;

      reg dummy ;

      begin  // ebfm_display_vc
        ebfm_cfgrd_wait(bnm,dev,fnc,260,4,CFG_SCRATCH_SPACE, compl_status);

        port_vc_cap_r = shmem_read(CFG_SCRATCH_SPACE,2) ;
        // Low priority VC = 0 means there is no Low priority VC
        // Low priority VC = 1 means there are 2 Low priority VCs etc
    if (port_vc_cap_r[6:4] == 3'b000)
    begin
        low_vc = 3'b000;
    end
    else
    begin
        low_vc = port_vc_cap_r[6:4] + 1;
    end
        if (root_port==1)
            dummy = ebfm_display(EBFM_MSG_INFO,"  RP PCI Express Virtual Channel Capability:") ;
        else
            dummy = ebfm_display(EBFM_MSG_INFO,"  EP PCI Express Virtual Channel Capability:") ;

        dummy = ebfm_display(EBFM_MSG_INFO,{"         Virtual Channel: ", himage1({1'b0,port_vc_cap_r[2:0]} +1)}) ;
        dummy = ebfm_display(EBFM_MSG_INFO,{"         Low Priority VC: ", himage1({1'b0,low_vc})}) ;
        dummy = ebfm_display(EBFM_MSG_INFO,"") ;
    end
  endtask

   // purpose: Performs all of the steps neccesary to configure the
   // root port and the endpoint on the link
   task ebfm_cfg_rp_ep_main;
      input bar_table;
      integer bar_table;
      // Constant Display the Config Spaces of the EP after config setup
      input ep_bus_num;
      integer ep_bus_num;
      input ep_dev_num;
      integer ep_dev_num;
      input rp_max_rd_req_size;
      integer rp_max_rd_req_size;
      input display_ep_config;    // 1 to display
      integer display_ep_config;
      input display_rp_config;    // 1 to display
      integer display_rp_config;
      input addr_map_4GB_limit;


      reg[31:0] io_min_v;
      reg[31:0] io_max_v;
      reg[63:0] m32min_v;
      reg[63:0] m32max_v;
      reg[63:0] m64min_v;
      reg[63:0] m64max_v;
      reg[2:0] compl_status;
      reg bar_ok;

      reg dummy ;

      integer i ;

      begin  // ebfm_cfg_rp_ep_main
         io_min_v = EBFM_BAR_IO_MIN ;
         io_max_v = EBFM_BAR_IO_MAX ;
         m32min_v = {32'h00000000,EBFM_BAR_M32_MIN};
         m32max_v = {32'h00000000,EBFM_BAR_M32_MAX};
         m64min_v = EBFM_BAR_M64_MIN;
         m64max_v = EBFM_BAR_M64_MAX;
         if  (display_rp_config == 1'b1) // Limit the BAR allocation to less than 4GB
      begin
           m32max_v[31:0] = m32max_v[31:0] & 32'h7fff_ffff;
           m64min_v = 64'h0000_0000_8000_0000;
      end

         // Wait until the Root Port is done being reset before proceeding further
         #10;

         req_intf_wait_reset_end;

         // Unlock the bfm shared memory for initialization
         bfm_shmem_common.protect_bfm_shmem = 1'b0;

         // Perform the basic configuration of the Root Port
         ebfm_cfg_rp_basic((ep_bus_num - RP_PRI_BUS_NUM), 1);

         if ((display_ep_config == 1) | (display_rp_config == 1)) begin
            dummy = ebfm_display(EBFM_MSG_INFO, "Completed initial configuration of Root Port.");
         end

         if (display_ep_config == 1)
         begin
            ebfm_display_read_only(0, (ep_bus_num - RP_PRI_BUS_NUM), 1, 0, CFG_SCRATCH_SPACE);
            ebfm_display_msi(ep_bus_num,1,0,CFG_SCRATCH_SPACE) ;
            ebfm_display_msix(ep_bus_num,1,0,CFG_SCRATCH_SPACE) ;
            ebfm_display_aer(0, ep_bus_num,1,0,CFG_SCRATCH_SPACE) ;
         end

         if (display_rp_config == 1) begin
             // dummy write to ensure link is at L0
             ebfm_cfgwr_imm_wait(ep_bus_num, ep_dev_num, 0, 4, 4, 32'h00000007, compl_status);

             ebfm_display_read_only(1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, CFG_SCRATCH_SPACE);
             ebfm_display_rp_bar(RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, CFG_SCRATCH_SPACE);
             ebfm_display_msi(RP_PRI_BUS_NUM,RP_PRI_DEV_NUM,0,CFG_SCRATCH_SPACE) ;
             ebfm_display_aer(1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, CFG_SCRATCH_SPACE) ;
             ebfm_display_slot_cap (1, RP_PRI_BUS_NUM, RP_PRI_DEV_NUM, 0, CFG_SCRATCH_SPACE) ;
         end

         ebfm_cfg_pcie_cap((ep_bus_num - RP_PRI_BUS_NUM), 1, 0, CFG_SCRATCH_SPACE, rp_max_rd_req_size, display_ep_config, display_rp_config);

         // Configure BARs (Throw away the updated min/max addresses)
         ebfm_cfg_bars(ep_bus_num, ep_dev_num, 0, bar_table, bar_ok,
                       io_min_v, io_max_v, m32min_v, m32max_v, m64min_v, m64max_v,
                       display_ep_config, addr_map_4GB_limit);
         if (bar_ok == 1'b1)
         begin
            if ((display_ep_config == 1) | (display_rp_config == 1))
            begin
               dummy = ebfm_display(EBFM_MSG_INFO, "Completed configuration of Endpoint BARs.");
            end
         end
         else
         begin
            dummy = ebfm_display(EBFM_MSG_ERROR_FATAL, "Unable to assign all of the Endpoint BARs.");
         end

         // Configure Root Port Address Windows
         ebfm_cfg_rp_addr(
         (m32max_v + 1),    // Pref32 grew down
         (m64min_v - 1),    // Pref64 grew up
         (EBFM_BAR_M32_MIN),    // NonP started here
         (m32min_v[31:0] - 1),  // NonP ended here
         (EBFM_BAR_IO_MIN), // I/O Started Here
         (io_min_v - 1));   // I/O ended Here

         ebfm_cfgwr_imm_wait(ep_bus_num, ep_dev_num, 0, 4, 4, 32'h00000007, compl_status);

         // Protect the critical BFM data from being accidentally overwritten.
         bfm_shmem_common.protect_bfm_shmem = 1'b1;

      end
   endtask

   task ebfm_cfg_rp_ep;   // Wrapper task called by End Point
      input bar_table;
      integer bar_table;
      // Constant Display the Config Spaces of the EP after config setup
      input ep_bus_num;
      integer ep_bus_num;
      input ep_dev_num;
      integer ep_dev_num;
      input rp_max_rd_req_size;
      integer rp_max_rd_req_size;
      input display_ep_config;    // 1 to display
      integer display_ep_config;
      input addr_map_4GB_limit;

      ebfm_cfg_rp_ep_main (bar_table, ep_bus_num, ep_dev_num, rp_max_rd_req_size, display_ep_config, 0, addr_map_4GB_limit);

   endtask


   task ebfm_cfg_rp_ep_rootport;   // Wrapper task called by Root Port
      input bar_table;
      integer bar_table;
      // Constant Display the Config Spaces of the EP after config setup
      input ep_bus_num;
      integer ep_bus_num;
      input ep_dev_num;
      integer ep_dev_num;
      input rp_max_rd_req_size;
      integer rp_max_rd_req_size;
      input display_ep_config;    // 1 to display
      integer display_ep_config;
      input display_rp_config;    // 1 to display
      integer display_rp_config;
      input addr_map_4GB_limit;

      ebfm_cfg_rp_ep_main (bar_table, ep_bus_num, ep_dev_num, rp_max_rd_req_size, display_ep_config, display_rp_config, addr_map_4GB_limit);

   endtask


   // purpose: returns whether specified BAR is memory or I/O and the size
   task ebfm_cfg_decode_bar;
      input bar_table;   // Pointer to BAR info
      integer bar_table;
      input bar_num;     // bar number to check
      integer bar_num;
      output log2_size;  // Log base 2 of the Size
      integer log2_size;
      output is_mem;     // Is memory (not I/O)
      output is_pref;    // Is prefetchable
      output is_64b;     // Is 64bit

      reg[63:0] bar64;
      parameter[31:0] ZERO32 = {32{1'b0}};
      integer maxlsb;

      begin
         bar64 = shmem_read((bar_table + 32 + (bar_num * 4)), 8);
         // Check if BAR is unassigned
         if (bar64[31:0] == ZERO32)
         begin
            log2_size = 0;
            is_mem = 1'b0;
            is_pref = 1'b0;
            is_64b = 1'b0;
         end
         else
         begin
            is_mem = ~bar64[0];
            is_pref = (~bar64[0]) & bar64[3];
            is_64b = (~bar64[0]) & bar64[2];
            if (((bar64[0]) == 1'b1) | ((bar64[2]) == 1'b0))
            begin
               maxlsb = 31;
            end
            else
            begin
               maxlsb = 63;
            end
            begin : xhdl_10
               integer i;
               for(i = 4; i <= maxlsb; i = i + 1)
               begin : check_loop
                  if ((bar64[i]) == 1'b1)
                  begin
                     log2_size = i;
                     disable xhdl_10 ;
                  end
               end
            end // i in 4 to maxlsb
         end
      end
   endtask
