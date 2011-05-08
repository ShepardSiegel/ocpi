   //-----------------------------------------------------------------------------
   // Title         : PCI Express BFM Root Shared Memory Package
   // Project       : PCI Express MegaCore function
   //-----------------------------------------------------------------------------
   // File          : altpcie_bfm_shmem.v
   // Author        : Altera Corporation
   //-----------------------------------------------------------------------------
   // Description :
   // This entity provides the Root Port BFM shared memory which can be used for
   // the following functions
   // * Source of data for transmitted write operations
   // * Source of data for received read operations
   // * Receipient of data for received write operations
   // * Receipient of data for received completions
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

   parameter SHMEM_FILL_ZERO = 0;
   parameter SHMEM_FILL_BYTE_INC = 1;
   parameter SHMEM_FILL_WORD_INC = 2;
   parameter SHMEM_FILL_DWORD_INC = 4;
   parameter SHMEM_FILL_QWORD_INC = 8;
   parameter SHMEM_FILL_ONE = 15;
   parameter SHMEM_SIZE = 2 ** SHMEM_ADDR_WIDTH;
   parameter BAR_TABLE_SIZE = 64;
   parameter BAR_TABLE_POINTER = SHMEM_SIZE - BAR_TABLE_SIZE;
   parameter SCR_SIZE = 64;
   parameter CFG_SCRATCH_SPACE = SHMEM_SIZE - BAR_TABLE_SIZE - SCR_SIZE;

   task shmem_write;
      input addr;
      integer addr;
      input [63:0] data;
      input leng;
      integer leng;

      integer rleng;
      integer i ;

      reg dummy ;

      begin
         if (leng > 8)
           begin
              dummy = ebfm_display(EBFM_MSG_ERROR_FATAL,"Task SHMEM_WRITE only accepts write lengths up to 8") ;
              rleng = 8 ;
           end
         else if ( addr < BAR_TABLE_POINTER + BAR_TABLE_SIZE & addr >= CFG_SCRATCH_SPACE & bfm_shmem_common.protect_bfm_shmem )
            begin
              dummy = ebfm_display(EBFM_MSG_ERROR_INFO,"Task SHMEM_WRITE attempted to overwrite the write protected area of the shared memory") ;
              dummy = ebfm_display(EBFM_MSG_ERROR_INFO,"This protected area contains the following data critical to the operation of the BFM:") ;
              dummy = ebfm_display(EBFM_MSG_ERROR_INFO,{"The BFM internal memory area, 64B located at ", himage8(CFG_SCRATCH_SPACE)}) ;
              dummy = ebfm_display(EBFM_MSG_ERROR_INFO,{"The BAR Table, 64B located at ", himage8(BAR_TABLE_POINTER)}) ;
              dummy = ebfm_display(EBFM_MSG_ERROR_INFO,{"All other locations in the shared memory are available from 0 to ", himage8(CFG_SCRATCH_SPACE - 1)}) ;
              dummy = ebfm_display(EBFM_MSG_ERROR_INFO,"Please change your SHMEM_WRITE call to a different memory location") ;
              dummy = ebfm_display(EBFM_MSG_ERROR_FATAL,"Halting Simulation") ;
            end
         else
           begin
              rleng = leng ;
           end
         for(i = 0; i <= (rleng - 1); i = i + 1)
           begin
              bfm_shmem_common.shmem[addr + i] = data[(i*8)+:8];
           end
      end
   endtask

   function [63:0] shmem_read;
      input addr;
      integer addr;
      input leng;
      integer leng;

      reg[63:0] rdata;
      integer rleng ;
      integer i ;

      reg dummy ;

      begin
         rdata = {64{1'b0}} ;
         if (leng > 8)
           begin
              dummy = ebfm_display(EBFM_MSG_ERROR_FATAL,"Task SHMEM_READ only accepts read lengths up to 8") ;
              rleng = 8 ;
           end
         else
           begin
              rleng = leng ;
           end
         for(i = 0; i <= (rleng - 1); i = i + 1)
           begin
              rdata[(i * 8)+:8] = bfm_shmem_common.shmem[addr + i];
           end
         shmem_read = rdata;
      end
   endfunction

   // purpose: display shared memory data
   function shmem_display;
      input addr;
      integer addr;
      input leng;
      integer leng;
      input word_size;
      integer word_size;
      input flag_addr;
      integer flag_addr;
      input msg_type;
      integer msg_type;

      integer iaddr;
      reg [60*8:1] oneline ;
      reg [128:1] data_str[0:15] ;
      reg [8*5:1] flag ;
      integer i ;

      reg dummy ;

      begin
         // shmem_display
         iaddr = addr ;
         // Backup address to beginning of word if needed
         if (iaddr % word_size > 0)
           begin
              iaddr = iaddr - (iaddr % word_size);
           end
         dummy = ebfm_display(msg_type, "");
         dummy = ebfm_display(msg_type, "Shared Memory Data Display:");
         dummy = ebfm_display(msg_type, "Address  Data");
         dummy = ebfm_display(msg_type, "-------  ----");
         while (iaddr < (addr + leng))
           begin
              for (i = 0; i < 16 ; i = i + word_size)
                begin : one_line
                   if ( (iaddr + i) > (addr + leng) )
                     begin
                        data_str[i] = "        " ;
                     end
                   else
                     begin
                        case (word_size)
                          8       : data_str[i] = himage16(shmem_read(iaddr + i,8)) ;
                          4       : data_str[i] = {"            ",himage8(shmem_read(iaddr + i,4))} ;
                          2       : data_str[i] = {"                ",himage4(shmem_read(iaddr + i,2))} ;
                          default : data_str[i] = {"                  ",himage2(shmem_read(iaddr + i,1))} ;
                        endcase // case(word_size)
                     end
                end // block: one_line
              if ((flag_addr >= iaddr) & (flag_addr < (iaddr + 16)))
                begin
                   flag = " <===" ;
                end
              else
                begin
                   flag = "     " ;
                end
              // Now compile the whole line
              oneline = {480{1'b0}} ;
              case (word_size)
                8 : oneline = {himage8(iaddr),
                               " ",data_str[0]," ",data_str[8],flag} ;
                4 : oneline = {himage8(iaddr),
                               " ",data_str[0][64:1]," ",data_str[4][64:1],
                               " ",data_str[8][64:1]," ",data_str[12][64:1],
                               flag} ;
                2 : oneline = {himage8(iaddr),
                               " ",data_str[0][32:1]," ",data_str[2][32:1],
                               " ",data_str[4][32:1]," ",data_str[6][32:1],
                               " ",data_str[8][32:1]," ",data_str[10][32:1],
                               " ",data_str[12][32:1]," ",data_str[14][32:1],
                               flag} ;
                default : oneline = {himage8(iaddr),
                               " ",data_str[0][16:1]," ",data_str[1][16:1],
                               " ",data_str[2][16:1]," ",data_str[3][16:1],
                               " ",data_str[4][16:1]," ",data_str[5][16:1],
                               " ",data_str[6][16:1]," ",data_str[7][16:1],
                               " ",data_str[8][16:1]," ",data_str[9][16:1],
                               " ",data_str[10][16:1]," ",data_str[11][16:1],
                               " ",data_str[12][16:1]," ",data_str[13][16:1],
                               " ",data_str[14][16:1]," ",data_str[15][16:1],
                               flag} ;
              endcase
              dummy = ebfm_display(msg_type, oneline);
              iaddr = iaddr + 16;
           end // while (iaddr < (addr + leng))
         // Dummy return so we can call from other functions
         shmem_display = 1'b0 ;
      end
   endfunction

   task shmem_fill;
      input addr;
      integer addr;
      input mode;
      integer mode;
      input leng; // Length to fill in bytes
      integer leng;
      input[63:0] init;

      integer rembytes;
      reg[63:0] data;
      integer uaddr;
      parameter[7:0] ZDATA = {8{1'b0}};
      parameter[7:0] ODATA = {8{1'b1}};

      begin
         rembytes = leng ;
         data = init ;
         uaddr = addr ;
         while (rembytes > 0)
         begin
            case (mode)
               SHMEM_FILL_ZERO :
                        begin
                           shmem_write(uaddr, ZDATA,1);
                           rembytes = rembytes - 1;
                           uaddr = uaddr + 1;
                        end
               SHMEM_FILL_BYTE_INC :
                        begin
                           shmem_write(uaddr, data, 1);
                           data[7:0] = data[7:0] + 1;
                           rembytes = rembytes - 1;
                           uaddr = uaddr + 1;
                        end
               SHMEM_FILL_WORD_INC :
                        begin
                           begin : xhdl_3
                              integer i;
                              for(i = 0; i <= 1; i = i + 1)
                              begin
                                 if (rembytes > 0)
                                 begin
                                    shmem_write(uaddr, data[(i*8)+:8], 1);
                                    rembytes = rembytes - 1;
                                    uaddr = uaddr + 1;
                                 end
                              end
                           end // i
                           data[15:0] = data[15:0] + 1;
                        end
               SHMEM_FILL_DWORD_INC :
                        begin
                           begin : xhdl_4
                              integer i;
                              for(i = 0; i <= 3; i = i + 1)
                              begin
                                 if (rembytes > 0)
                                 begin
                                    shmem_write(uaddr, data[(i*8)+:8], 1);
                                    rembytes = rembytes - 1;
                                    uaddr = uaddr + 1;
                                 end
                              end
                           end // i
                           data[31:0] = data[31:0] + 1 ;
                        end
               SHMEM_FILL_QWORD_INC :
                        begin
                           begin : xhdl_5
                              integer i;
                              for(i = 0; i <= 7; i = i + 1)
                              begin
                                 if (rembytes > 0)
                                 begin
                                    shmem_write(uaddr, data[(i*8)+:8], 1);
                                    rembytes = rembytes - 1;
                                    uaddr = uaddr + 1;
                                 end
                              end
                           end // i
                           data[63:0] = data[63:0] + 1;
                        end
               SHMEM_FILL_ONE :
                        begin
                           shmem_write(uaddr, ODATA, 1);
                           rembytes = rembytes - 1;
                           uaddr = uaddr + 1;
                        end
               default :
                        begin
                        end
            endcase
         end
      end
   endtask

   // Returns 1 if okay
   function [0:0] shmem_chk_ok;
      input addr;
      integer addr;
      input mode;
      integer mode;
      input leng; // Length to fill in bytes
      integer leng;
      input[63:0] init;
      input display_error;
      integer display_error;

      reg dummy ;

      integer rembytes;
      reg[63:0] data;
      reg[63:0] actual;
      integer uaddr;
      integer daddr;
      integer dlen;
      integer incr_count;
      parameter[7:0] ZDATA = {8{1'b0}};
      parameter[7:0] ODATA = {8{1'b1}};
      reg [36*8:1] actline;
      reg [36*8:1] expline;
      integer word_size;

      begin
         rembytes = leng ;
         uaddr = addr ;
         data = init ;
         actual = init ;
         incr_count = 0 ;
         case (mode)
            SHMEM_FILL_WORD_INC :
                     begin
                        word_size = 2;
                     end
            SHMEM_FILL_DWORD_INC :
                     begin
                        word_size = 4;
                     end
            SHMEM_FILL_QWORD_INC :
                     begin
                        word_size = 8;
                     end
            default :
                     begin
                        word_size = 1;
                     end
         endcase // case(mode)
         begin : compare_loop
         while (rembytes > 0)
         begin
            case (mode)
               SHMEM_FILL_ZERO :
                 begin
                    actual[7:0] = shmem_read(uaddr, 1);
                    if (actual[7:0] != ZDATA)
                      begin
                         expline = {"    Expected Data: ", himage2(ZDATA[7:0]), "              "};
                         actline = {"      Actual Data: ", himage2(actual[7:0]), "              "};
                         disable compare_loop;
                      end
                    rembytes = rembytes - 1;
                    uaddr = uaddr + 1;
                 end
               SHMEM_FILL_BYTE_INC :
                 begin
                    actual[7:0] = shmem_read(uaddr, 1);
                    if (actual[7:0] != data[7:0])
                      begin
                         expline = {"    Expected Data: ", himage2(data[7:0]), "              "};
                         actline = {"      Actual Data: ", himage2(actual[7:0]), "              "};
                         disable compare_loop;
                      end
                    data[7:0] = data[7:0] + 1;
                    rembytes = rembytes - 1;
                    uaddr = uaddr + 1;
                 end
               SHMEM_FILL_WORD_INC :
                 begin
                    actual[7:0] = shmem_read(uaddr, 1);
                    if (actual[7:0] != data[(incr_count * 8)+:8])
                      begin
                         expline = {"    Expected Data: ", himage2(data[(incr_count * 8)+:8]), "              "};
                         actline = {"      Actual Data: ", himage2(actual[7:0]), "              "};
                         disable compare_loop;
                      end
                    if (incr_count == 1)
                      begin
                         data[15:0] = data[15:0] + 1 ;
                         incr_count = 0;
                      end
                    else
                      begin
                         incr_count = incr_count + 1;
                      end
                    rembytes = rembytes - 1;
                    uaddr = uaddr + 1;
                 end
               SHMEM_FILL_DWORD_INC :
                 begin
                    actual[7:0] = shmem_read(uaddr, 1);
                    if (actual[7:0] != data[(incr_count * 8)+:8])
                      begin
                         expline = {"    Expected Data: ", himage2(data[(incr_count * 8)+:8]), "              "};
                         actline = {"      Actual Data: ", himage2(actual[7:0]), "              "};
                         disable compare_loop;
                      end
                    if (incr_count == 3)
                      begin
                         data[31:0] = data[31:0] + 1;
                         incr_count = 0;
                      end
                    else
                      begin
                         incr_count = incr_count + 1;
                      end
                    rembytes = rembytes - 1;
                    uaddr = uaddr + 1;
                 end
               SHMEM_FILL_QWORD_INC :
                 begin
                    actual[7:0] = shmem_read(uaddr, 1);
                    if (actual[7:0] != data[(incr_count * 8)+:8])
                      begin
                         expline = {"    Expected Data: ", himage2(data[(incr_count * 8)+:8]), "              "};
                         actline = {"      Actual Data: ", himage2(actual[7:0]), "              "};
                         disable compare_loop;
                      end
                    if (incr_count == 7)
                      begin
                         data[63:0] = data[63:0] + 1;
                         incr_count = 0;
                      end
                    else
                      begin
                         incr_count = incr_count + 1;
                      end
                    rembytes = rembytes - 1;
                    uaddr = uaddr + 1;
                 end
               SHMEM_FILL_ONE :
                 begin
                    actual[7:0] = shmem_read(uaddr, 1);
                    if (actual[7:0] != ODATA)
                      begin
                         expline = {"    Expected Data: ", himage2(ODATA[7:0]), "              "};
                         actline = {"      Actual Data: ", himage2(actual[7:0]), "              "};
                         disable compare_loop;
                      end
                    rembytes = rembytes - 1;
                    uaddr = uaddr + 1;
                 end
               default :
                 begin
                 end
            endcase
         end
         end // block: compare_loop
         if (rembytes > 0)
         begin
            if (display_error == 1)
            begin
               dummy = ebfm_display(EBFM_MSG_ERROR_INFO, "");
               dummy = ebfm_display(EBFM_MSG_ERROR_INFO, {"Shared memory data miscompare at address: ", himage8(uaddr)});
               dummy = ebfm_display(EBFM_MSG_ERROR_INFO, expline);
               dummy = ebfm_display(EBFM_MSG_ERROR_INFO, actline);
               // Backup and display a little before the miscompare
               // Figure amount to backup
               daddr = uaddr % 32; // Back up no more than 32 bytes
               // There was a miscompare, display an error message
               if (daddr < 16)
               begin
                  // But at least 16
                  daddr = daddr + 16;
               end
               // Backed up display address
               daddr = uaddr - daddr;
               // Don't backup more than start of compare
               if (daddr < addr)
               begin
                  daddr = addr;
               end
               // Try to display 64 bytes
               dlen = 64;
               // But don't display beyond the end of the compare
               if (daddr + dlen > addr + leng)
               begin
                  dlen = (addr + leng) - daddr;
               end
               dummy = shmem_display(daddr, dlen, word_size, uaddr, EBFM_MSG_ERROR_INFO);
            end
            shmem_chk_ok = 0;
         end
         else
         begin
            shmem_chk_ok = 1;
         end
      end
   endfunction
//`endif
