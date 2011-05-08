   //-----------------------------------------------------------------------------
   // Title         : PCI Express BFM Message Logging Include File  
   // Project       : PCI Express MegaCore function
   //-----------------------------------------------------------------------------
   // File          : altpcietb_bfm_log.v
   // Author        : Altera Corporation
   //-----------------------------------------------------------------------------
   // Description :
   // This include file provides routines to log various information to the standard
   // output 
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

   // Constants for the logging package 
   parameter EBFM_MSG_DEBUG = 0; 
   parameter EBFM_MSG_INFO = 1; 
   parameter EBFM_MSG_WARNING = 2; 
   parameter EBFM_MSG_ERROR_INFO = 3; // Preliminary Error Info Message 
   parameter EBFM_MSG_ERROR_CONTINUE = 4; 
   // Fatal Error Messages always stop the simulation
   parameter EBFM_MSG_ERROR_FATAL = 101; 
   parameter EBFM_MSG_ERROR_FATAL_TB_ERR = 102; 

   // Maximum Message Length in characters 
   parameter EBFM_MSG_MAX_LEN = 100 ;

   // purpose: sets the suppressed_msg_mask
   task ebfm_log_set_suppressed_msg_mask;
      input [EBFM_MSG_ERROR_CONTINUE:EBFM_MSG_DEBUG] msg_mask; 

      begin
         // ebfm_log_set_suppressed_msg_mask
         bfm_log_common.suppressed_msg_mask = msg_mask; 
      end
   endtask

   // purpose: sets the stop_on_msg_mask
   task ebfm_log_set_stop_on_msg_mask;
      input [EBFM_MSG_ERROR_CONTINUE:EBFM_MSG_DEBUG] msg_mask; 

      begin
         // ebfm_log_set_stop_on_msg_mask
         bfm_log_common.stop_on_msg_mask = msg_mask; 
      end
   endtask

   // purpose: Opens the Log File with the specified name
   task ebfm_log_open;
      input [200*8:1] fn; // Log File Name

      begin
         bfm_log_common.log_file = $fopen(fn);
      end
   endtask

   // purpose: Opens the Log File with the specified name
   task ebfm_log_close;

      begin
         // ebfm_log_close
         $fclose(bfm_log_common.log_file); 
         bfm_log_common.log_file = 0; 
      end
   endtask

   // purpose: stops the simulation, with flag to indicate success or not
   function ebfm_log_stop_sim;
      input success; 
      integer success;

      begin
         if (success == 1)
         begin
            $display("SUCCESS: Simulation stopped due to successful completion!");
            `ifdef VCS
            $finish;
            `else
            $stop ;
            `endif
         end
         else
         begin
            $display("FAILURE: Simulation stopped due to error!");
            `ifdef VCS
            $finish;
            `else
            $stop ;
            `endif
         end 
         ebfm_log_stop_sim = 1'b0 ;
      end
   endfunction

   // purpose: This displays a message of the specified type
   function ebfm_display;
      input msg_type; 
      integer msg_type;
      input [EBFM_MSG_MAX_LEN*8:1] message; 

      reg [9*8:1]  prefix ; 
      reg [80*8:1] amsg; 
      reg sup; 
      reg stp; 
      reg dummy ;
      integer i ;
      time ctime ;
      integer itime ; 
      
      begin
         for (i = 0 ; i < EBFM_MSG_MAX_LEN ; i = i + 1) 
           begin : msg_shift 
              if (message[(EBFM_MSG_MAX_LEN*8)-:8] != 8'h00)
                begin
                   disable msg_shift ;
                end
              message = message << 8 ;
           end
         if (msg_type > EBFM_MSG_ERROR_CONTINUE)
           begin
              sup = 1'b0; 
              stp = 1'b1; 
              case (msg_type)
                EBFM_MSG_ERROR_FATAL :
                  begin
                     amsg   = "FAILURE: Simulation stopped due to Fatal error!" ; 
                     prefix = "FATAL:   "; 
                  end
                EBFM_MSG_ERROR_FATAL_TB_ERR :
                  begin
                     amsg   = "FAILURE: Simulation stopped due error in Testbench/BFM design!"; 
                     prefix = "FATAL:   "; 
                  end
                default :
                  begin
                     amsg   = "FAILURE: Simulation stopped due to unknown message type!"; 
                     prefix = "FATAL:   "; 
                  end
              endcase 
           end
         else
           begin
              sup = bfm_log_common.suppressed_msg_mask[msg_type]; 
              stp = bfm_log_common.stop_on_msg_mask[msg_type]; 
              if (stp == 1'b1)
                begin
                   amsg   = "FAILURE: Simulation stopped due to enabled error!"; 
                end
              if (msg_type < EBFM_MSG_INFO)
                begin
                     prefix = "DEBUG:   ";
                end
              else
                begin
                   if (msg_type < EBFM_MSG_WARNING)
                     begin
                        prefix = "INFO:    ";
                     end
                   else
                     begin
                        if (msg_type > EBFM_MSG_WARNING)
                          begin
                             prefix = "ERROR:   "; 
                          end
                        else
                          begin
                             prefix = "WARNING: "; 
                          end 
                     end 
                end 
           end // else: !if(msg_type > EBFM_MSG_ERROR_CONTINUE)
         itime = ($time/1000) ;
         // Display the message if not suppressed
         if (sup != 1'b1)
           begin
              if (bfm_log_common.log_file != 0)
                begin
                   $fdisplay(bfm_log_common.log_file,"%s %d %s %s",prefix,itime,"ns",message); 
                end 
              $display("%s %d %s %s",prefix,itime,"ns",message);
           end 
         // Stop if requested
         if (stp == 1'b1)
           begin
              if (bfm_log_common.log_file != 0)
                begin
                   $fdisplay(bfm_log_common.log_file, "%s", amsg); 
                end 
              $display("%s",amsg); 
              dummy = ebfm_log_stop_sim(0); 
           end 
         // Dummy function return so we can call from other functions
         ebfm_display = 1'b0 ;
      end
   endfunction

   // purpose: produce 1-digit hexadecimal string from a vector 
   function [8:1] himage1;
      input [3:0] vec; 

      begin
         case (vec)
           4'h0 : himage1 = "0" ;
           4'h1 : himage1 = "1" ;
           4'h2 : himage1 = "2" ;
           4'h3 : himage1 = "3" ;
           4'h4 : himage1 = "4" ;
           4'h5 : himage1 = "5" ;
           4'h6 : himage1 = "6" ;
           4'h7 : himage1 = "7" ;
           4'h8 : himage1 = "8" ;
           4'h9 : himage1 = "9" ;
           4'hA : himage1 = "A" ;
           4'hB : himage1 = "B" ;
           4'hC : himage1 = "C" ;
           4'hD : himage1 = "D" ;
           4'hE : himage1 = "E" ;
           4'hF : himage1 = "F" ;
           4'bzzzz : himage1 = "Z" ;
           default : himage1 = "X" ;          
         endcase
      end
   endfunction // himage1

   // purpose: produce 2-digit hexadecimal string from a vector 
   function [16:1] himage2 ;
      input [7:0] vec;
      begin
         himage2 = {himage1(vec[7:4]),himage1(vec[3:0])} ;
      end
   endfunction // himage2

   // purpose: produce 4-digit hexadecimal string from a vector 
   function [32:1] himage4 ;
      input [15:0] vec;
      begin
         himage4 = {himage2(vec[15:8]),himage2(vec[7:0])} ;
      end
   endfunction // himage4

   // purpose: produce 8-digit hexadecimal string from a vector 
   function [64:1] himage8 ;
      input [31:0] vec;
      begin
         himage8 = {himage4(vec[31:16]),himage4(vec[15:0])} ;
      end
   endfunction // himage8

   // purpose: produce 16-digit hexadecimal string from a vector 
   function [128:1] himage16 ;
      input [63:0] vec;
      begin
         himage16 = {himage8(vec[63:32]),himage8(vec[31:0])} ;
      end
   endfunction // himage16

   // purpose: produce 1-digit decimal string from an integer
   function [8:1] dimage1 ;
      input [31:0] num ;
      begin
         case (num) 
           0 : dimage1 = "0" ;
           1 : dimage1 = "1" ;
           2 : dimage1 = "2" ;
           3 : dimage1 = "3" ;
           4 : dimage1 = "4" ;
           5 : dimage1 = "5" ;
           6 : dimage1 = "6" ;
           7 : dimage1 = "7" ;
           8 : dimage1 = "8" ;
           9 : dimage1 = "9" ;
           default : dimage1 = "U" ;
         endcase // case(num)
      end
   endfunction // dimage1

   // purpose: produce 2-digit decimal string from an integer
   function [16:1] dimage2 ;
      input [31:0] num ;
      begin
         dimage2 = {dimage1(num/10),dimage1(num % 10)} ;
      end
   endfunction // dimage2

   // purpose: produce 3-digit decimal string from an integer
   function [24:1] dimage3 ;
      input [31:0] num ;
      begin
         dimage3 = {dimage1(num/100),dimage2(num % 100)} ;
      end
   endfunction // dimage3

   // purpose: produce 4-digit decimal string from an integer
   function [32:1] dimage4 ;
      input [31:0] num ;
      begin
         dimage4 = {dimage1(num/1000),dimage3(num % 1000)} ;
      end
   endfunction // dimage4

   // purpose: produce 5-digit decimal string from an integer
   function [40:1] dimage5 ;
      input [31:0] num ;
      begin
         dimage5 = {dimage1(num/10000),dimage4(num % 10000)} ;
      end
   endfunction // dimage5

   // purpose: produce 6-digit decimal string from an integer
   function [48:1] dimage6 ;
      input [31:0] num ;
      begin
         dimage6 = {dimage1(num/100000),dimage5(num % 100000)} ;
      end
   endfunction // dimage6

   // purpose: produce 7-digit decimal string from an integer
   function [56:1] dimage7 ;
      input [31:0] num ;
      begin
         dimage7 = {dimage1(num/1000000),dimage6(num % 1000000)} ;
      end
   endfunction // dimage7

  // purpose: select the correct dimage call for ascii conversion
  function  [800:1] image ;
     input  [800:1] msg ;
     input  [32:1]  num ;
     begin
        if (num <= 10)
        begin
           image = {msg, dimage1(num)};
        end
        else if (num <= 100)
        begin
           image = {msg, dimage2(num)};
        end
        else if (num <= 1000)
        begin
           image = {msg, dimage3(num)};
        end
        else if (num <= 10000)
        begin
           image = {msg, dimage4(num)};
        end
        else if (num <= 100000)
        begin
           image = {msg, dimage5(num)};
        end
        else if (num <= 1000000)
        begin
           image = {msg, dimage6(num)};
        end
        else image = {msg, dimage7(num)};
     end
   endfunction
  
