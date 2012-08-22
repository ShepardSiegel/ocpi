
//-----------------------------------------------------------------------------
//
// (c) Copyright 2009-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Virtex-6 Integrated Block for PCI Express
// File       : PIO_TO_CTRL.v
// Version    : 1.7
//--
//-- Description: Turn-off Control Unit.
//--
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module PIO_TO_CTRL    (

                        clk,
                        rst_n,

                        req_compl_i,
                        compl_done_i,

                        cfg_to_turnoff_n,
                        cfg_turnoff_ok_n

                        );

    input               clk;
    input               rst_n;

    input               req_compl_i;
    input               compl_done_i;

    input               cfg_to_turnoff_n;
    output              cfg_turnoff_ok_n;

    reg                 trn_pending;
    reg                 cfg_turnoff_ok_n;


    // *  Check if completion is pending

    always @ ( posedge clk or negedge rst_n ) begin

        if (!rst_n ) begin

          trn_pending <= 0;

        end else begin

          if (!trn_pending && req_compl_i)

            trn_pending <= 1'b1;

          else if (compl_done_i)

            trn_pending <= 1'b0;

        end

    end

    // *  Turn-off OK if requested and no transaction is pending

     always @ ( posedge clk or negedge rst_n ) begin

      if (!rst_n ) begin

        cfg_turnoff_ok_n <= 1'b1;

      end else begin

        if ( !cfg_to_turnoff_n  && !trn_pending)
          cfg_turnoff_ok_n <= 1'b0;
        else
          cfg_turnoff_ok_n <= 1'b1;

      end

    end


endmodule // PIO_TO_CTRL

