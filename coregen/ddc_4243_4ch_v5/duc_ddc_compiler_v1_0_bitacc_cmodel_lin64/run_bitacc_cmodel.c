//-----------------------------------------------------------------------------
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.0
//  \   \        Filename: $RCSfile: run_bitacc_cmodel.c,v $
//  /   /        Date Last Modified: $Date: 2010/06/04 13:46:43 $
// /___/   /\    Date Created: 2009
// \   \  /  \
//  \___\/\___\
//
// Device  : All
// Library : duc_ddc_compiler_v1_0
// Purpose : Bit accurate C model smoke-test
//-----------------------------------------------------------------------------
//  (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
//
// DUC/DDC C model smoke-test. Instantiates a DUC/DDC object
// and passes some data through it.
//

#include <iostream>
#include <fstream>
#include <cctype>
#include <string>
#include <cmath>

#include "duc_ddc_compiler_v1_0_bitacc_cmodel.h"

// Work around for-scoping bug in MSVC (if necessary):
#ifndef for
#define for if(0) ; else for
#endif

// Simple error handling function

static void msg_print(void* dummy, int error, const char* msg)
{ std::cerr << msg << std::endl;
}


// Trivial function to exit program with an error message

void die(const std::string& msg)
{ std::cerr << msg << "\n";
  exit(1);
}

// Input and output of core configuration information

std::istream& operator>> (std::istream& is, xip_ducddc_v1_0_config& x)
{
  return is
   >> x.core_type
   >> x.ch_bandwidth
   >> x.if_passband
   >> x.digital_if
   >> x.rf_rate
   >> x.clock_rate
   >> x.n_carriers
   >> x.n_antennas
   >> x.din_width
   >> x.dout_width
   >> x.rounding_mode;
}

std::ostream& operator<< (std::ostream& os, const xip_ducddc_v1_0_config& x)
{
  return os
   << x.core_type    << ' '
   << x.ch_bandwidth << ' '
   << x.if_passband  << ' '
   << x.digital_if   << ' '
   << x.rf_rate      << ' '
   << x.clock_rate   << ' '
   << x.n_carriers   << ' '
   << x.n_antennas   << ' '
   << x.din_width    << ' '
   << x.dout_width   << ' '
   << x.rounding_mode << std::endl;
}

// Input and output of transaction responses

std::istream& operator>> (std::istream& is, xip_ducddc_v1_0_data_resp& r)
{
  // Two-phase extractor:
  if (r.dout_max_size == 0)
  {
    // read header only
    is >> r.dout_size >> r.dout_clean >> r.dout_dim0 >> r.dout_dim1;
  }
  else
  {
    // read data
    for (int a = 0; a < r.dout_dim0; a++)
    {
      for (int c = 0; c < r.dout_dim1; c++)
      {
        for (int s = 0; s < r.dout_size; s++)
        {
          is >> r.dout_i[a][c][s] >> r.dout_q[a][c][s];
        }
      }
    }
  }

  return is;
}

std::ostream& operator<< (std::ostream& os, const xip_ducddc_v1_0_data_resp& r)
{
  os << r.dout_size << ' ' << r.dout_clean << ' ' << r.dout_dim0 << ' ' << r.dout_dim1 << std::endl;

  for (int a = 0; a < r.dout_dim0; a++)
  {
    for (int c = 0; c < r.dout_dim1; c++)
    {
      for (int s = 0; s < r.dout_size; s++)
      {
        os << r.dout_i[a][c][s] << ' ' << r.dout_q[a][c][s] << ' ';
      }
      os << std::endl;
    }
    os << std::endl;
  }

  return os;
}

// Comparison function for transaction responses

bool operator== (xip_ducddc_v1_0_data_resp& x, xip_ducddc_v1_0_data_resp& y)
{
  if (x.dout_size  != y.dout_size)  return false;
  if (x.dout_clean != y.dout_clean) return false;
  if (x.dout_dim0  != y.dout_dim0)  return false;
  if (x.dout_dim1  != y.dout_dim1)  return false;

  for (int a = 0; a < x.dout_dim0; a++)
  { for (int c = 0; c < x.dout_dim1; c++)
    { for (int s = 0; s < x.dout_size; s++)
      {
        if (x.dout_i[a][c][s] != y.dout_i[a][c][s]) return false;
        if (x.dout_q[a][c][s] != y.dout_q[a][c][s]) return false;
      }
    }
  }
  return true;
}

bool operator!= (xip_ducddc_v1_0_data_resp& x, xip_ducddc_v1_0_data_resp& y)
{ return !(x==y);
}

// Create impulse (actually a step function stretched over N samples)
void makeImpulse(xip_ducddc_v1_0_data_req& req, int N = 1)
{
  for (int a = 0; a < req.din_dim0; a++)
  { for (int c = 0; c < req.din_dim1; c++)
    { for (int i = 0; i < req.din_size; i++)
      {
        req.din_i[a][c][i] = req.din_q[a][c][i] = (i < N) ? 0.0 : 0.5;
      }
    }
  }
}

// Main application code

int main(int argc, char *argv[])
{
  bool do_generate = false;
  std::string filename = "ducddc_testcases.dat";

  for (int ii = 1; ii < argc; ii++)
  {
    if (argv[ii][0]=='-')
    { if (tolower(argv[ii][1])=='g')
        do_generate = true;
    }
    else
    {
      filename = argv[ii];
    }
  }

  if (!do_generate)
  {
    // Check some testcases

    int err = 0;
    xip_ducddc_v1_0_config cfg;

    std::ifstream infile(filename.c_str());

    if (!infile) die ("Couldn't open " + filename + " for reading!");

    while (infile >> cfg)
    {
      cfg.name = "";
      // Create an instance of the model
      xip_ducddc_v1_0 *dut = xip_ducddc_v1_0_create(&cfg, &msg_print, 0);
      if (!dut) die("Error creating DUCDDC object!");

      // Use lots of samples for DDC, fewer for DUC
      unsigned samples = cfg.core_type ? 10000 : 1000;
  
      // Create request and response structures to hold input and output data
      xip_ducddc_v1_0_data_req  req;
      xip_ducddc_v1_0_data_resp resp, gold;

      // Allocate input buffer
      if (xip_ducddc_v1_0_alloc_data_req(dut, &req, samples)) die("Error allocating request structure!");

      // Calculate size of output buffer required
      if (xip_ducddc_v1_0_data_calc_size(dut, &req, &resp)) die ("Error calculating response size!");

      // Allocate output buffer
      if (xip_ducddc_v1_0_alloc_data_resp(dut, &resp, resp.dout_size)) die ("Error allocating response structure!");

      // Read golden data for comparison
      gold.dout_max_size = 0;
      if (!(infile >> gold)) die ("Error reading response header!");

      // Header information retrieved; now allocate buffer
      if (xip_ducddc_v1_0_alloc_data_resp(dut, &gold, resp.dout_size)) die ("Error allocating response structure!");

      if (!(infile >> gold)) die ("Error reading response data!");

      // Fill input buffer with impulse response
      makeImpulse(req, 4);

      // Run this transaction through the model
      if (xip_ducddc_v1_0_data_do(dut, &req, &resp)) die("Error processing data!");

      // Compare result
      if (resp != gold)
      {
        err = 1;
        std::cerr << "Comparison failed!" << std::endl;
      }
  
      // Free request and response structures
      if (xip_ducddc_v1_0_free_data_req((xip_ducddc_v1_0*)&dut, &req)) die("Error freeing request structure");
      if (xip_ducddc_v1_0_free_data_resp((xip_ducddc_v1_0*)&dut, &resp)) die("Error freeing response structure");
  
      // Destroy model instance and release resources
      if (xip_ducddc_v1_0_destroy(dut)) die("Error destroying DUCDDC object");
    }
  
    std::cout << "DUCDDC Smoke Test " << (err ? "FAILED" : "PASSED") << std::endl;
    // Finished!
    return err;

  }
  else
  {
    // Generate some testcases
    
    std::ofstream outfile(filename.c_str());

    if (!outfile) die ("Couldn't open " + filename + " for writing!");

    static xip_ducddc_v1_0_config cfgs[] =
    // name  ddc ch_bw if_pb dig_if rf_rate   clk_rate    cars ants din_width dout_width rnd_mode
    { { "",  0,  5,    5,    0,     76800000,  384000000, 1,   1,   14,       14,        0       },
      { "",  0,  5,    30,   0,     184320000, 368640000, 4,   1,   15,       15,        1       },
      { "",  0,  20,   40,   0,     122880000, 491520000, 2,   1,   14,       16,        0       },
      { "",  1,  5,    5,    0,     184320000, 184320000, 1,   1,   14,       14,        0       },
      { "",  1,  3,    30,   0,     92160000,  184320000, 5,   1,   15,       16,        0       },
      { "",  1,  10,   40,   1,     153600000, 460800000, 4,   1,   12,       18,        1       },
      { 0 }
    };

    outfile.precision(16);
    xip_ducddc_v1_0_config *cfg = cfgs;

    while (cfg->name)
    {
      // Print configuration
      outfile << *cfg;
  
      // Create an instance of the model
      xip_ducddc_v1_0 *dut = xip_ducddc_v1_0_create(cfg, &msg_print, 0);
      if (!dut) die("Error creating DUCDDC object!");
  
      // Create request and response structures to hold input and output data
      xip_ducddc_v1_0_data_req  req;
      xip_ducddc_v1_0_data_resp resp;
  
      // Use lots of samples for DDC, fewer for DUC
      unsigned samples = cfg->core_type ? 10000 : 1000;
  
      // Allocate input buffer
      if (xip_ducddc_v1_0_alloc_data_req(dut, &req, samples)) die("Error allocating request structure!");
  
      // Calculate size of output buffer required
      if (xip_ducddc_v1_0_data_calc_size(dut, &req, &resp)) die ("Error calculating response size!");
  
      // Allocate output buffer
      if (xip_ducddc_v1_0_alloc_data_resp(dut, &resp, resp.dout_size)) die ("Error allocating response structure!");

      // Fill input buffer with impulse response
      makeImpulse(req, 4);

      // Run this transaction through the model
      if (xip_ducddc_v1_0_data_do(dut, &req, &resp)) die("Error processing data!");
  
      // Dump result
      outfile << resp;
  
      // Free request and response structures
      if (xip_ducddc_v1_0_free_data_req((xip_ducddc_v1_0*)&dut, &req)) die("Error freeing request structure");
      if (xip_ducddc_v1_0_free_data_resp((xip_ducddc_v1_0*)&dut, &resp)) die("Error freeing response structure");

      // Destroy model instance and release resources
      if (xip_ducddc_v1_0_destroy(dut)) die("Error destroying DUCDDC object");

      ++cfg;
    }

    // Finished!
    return 0;

  }
}


/* EOF run_bitacc_cmodel.c */
