//-----------------------------------------------------------------------------
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor: Xilinx
// \   \   \/    Version: 1.0
//  \   \        Filename: $RCSfile: duc_ddc_compiler_v1_0_bitacc_cmodel.h,v $
//  /   /        Date Last Modified: $Date: 2010/03/08 12:04:09 $
// /___/   /\    Date Created: 2009
// \   \  /  \
//  \___\/\___\
//
// Device  : All
// Library : example_v1_0
// Purpose : Header file for bit accurate C model
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

#ifndef _XIP_DUCDDC_V1_0_BITACC_CMODEL_H
#define _XIP_DUCDDC_V1_0_BITACC_CMODEL_H

#ifdef NT
#define DLLIMPORT __declspec(dllimport)
#else
#define DLLIMPORT
#endif

#ifndef Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
#define Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL DLLIMPORT
#endif

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Constant definitions for "core_type" field of config structure:
 */

#define XIP_DUCDDC_CORE_IS_DUC 0
#define XIP_DUCDDC_CORE_IS_DDC 1

/**
 * Constant definitions for "ch_bandwidth" field of config structure
 */

#define XIP_DUCDDC_BANDWIDTH_LTE_1M4      1
#define XIP_DUCDDC_BANDWIDTH_LTE_3M       3
#define XIP_DUCDDC_BANDWIDTH_LTE_5M       5
#define XIP_DUCDDC_BANDWIDTH_LTE_10M      10
#define XIP_DUCDDC_BANDWIDTH_LTE_15M      15
#define XIP_DUCDDC_BANDWIDTH_LTE_20M      20
#define XIP_DUCDDC_BANDWIDTH_TDSCDMA_1M6  2

/**
 * Constant definitions for "digital_if" field of config structure
 */

#define XIP_DUCDDC_DIGITAL_IF_0Hz         0
#define XIP_DUCDDC_DIGITAL_IF_FS_DIV_4    1

/**
 * Constant definitions for rounding mode (because this may depend on device family)
 */
#define XIP_DUCDDC_ROUND_TIES_UP          0
#define XIP_DUCDDC_ROUND_TIES_EVEN        1

/**
 * Definitions for maximum number of carriers/antennas
 */

#define XIP_DUCDDC_MAX_CARRIERS           18
#define XIP_DUCDDC_MAX_ANTENNAS           8

/**
 * Constant definitions for input/output precision (bits after binary point)
 */

#define XIP_DUCDDC_MIN_DIN_WIDTH          11
#define XIP_DUCDDC_MAX_DIN_WIDTH          18
#define XIP_DUCDDC_MIN_DOUT_WIDTH         11
#define XIP_DUCDDC_MAX_DOUT_WIDTH         18

/**
 * Typedefs for data and status words
 */

typedef double xip_ducddc_data;
typedef int    xip_ducddc_status;

/**
 * Error codes
 */

#define XIP_DUCDDC_STATUS_OK        0
#define XIP_DUCDDC_STATUS_ERROR     1

/**
 * Error-handling callback type
 */
typedef void (*msg_handler)(void* handle, int error, const char* msg);

typedef struct
{
  /**
   * duc_ddc_compiler_v1_0 Core configuration structure.
   *
   * Must be created and populated in order to instantiate the model.
   */

  const char *name;   //@- Instance name (arbitrary)
  int  core_type;     //@- DUC or DDC (see above for encoding)
  int  ch_bandwidth;  //@- Channel bandwidth (see above for encoding)
  int  if_passband;   //@- IF passband (in MHz)
  int  digital_if;    //@- Digital IF setting (see above for encoding)
  int  rf_rate;       //@- RF sample rate, in samples per second
  int  clock_rate;    //@- Used to calculate 'oversampling' factor
  int  n_carriers;    //@- Number of carriers
  int  n_antennas;    //@- Number of antennas
  int  din_width;     //@- Width (precision) of input data
  int  dout_width;    //@- Width (precision) of output data
  int  rounding_mode; //@- Round ties up (POSIX/MATLAB) or to even (IEEE)

} xip_ducddc_v1_0_config;


typedef struct
{
  /**
   * Data port request structure. Contains a two-dimensional array of pointers
   * to sample data buffers - one pointer per carrier, per antenna. In the case
   * of a DDC, the second index is ignored, and input data for a given antenna
   * should be presented on carrier 0 only.
   */

  size_t din_size;   //@- Number of samples (per carrier, per antenna) in I (and Q) input buffers
  size_t din_dim0;   //@- Number of antennas
  size_t din_dim1;   //@- Number of carriers

  xip_ducddc_data *din_i[XIP_DUCDDC_MAX_ANTENNAS][XIP_DUCDDC_MAX_CARRIERS]; //@- Real part of sample data
  xip_ducddc_data *din_q[XIP_DUCDDC_MAX_ANTENNAS][XIP_DUCDDC_MAX_CARRIERS]; //@- Imaginary part of sample data

} xip_ducddc_v1_0_data_req;


typedef struct
{
  /**
   * Data port response structure. Contains a two-dimensional array of pointers
   * to sample data buffers - one pointer per carrier, per antenna. In the case
   * of a DUC, the second index is ignored, and output data for a given antenna
   * will be presented on carrier 0.
   */

  size_t dout_size;     //@- Number of samples (per carrier, per antenna) output in I (and Q) input buffers
  size_t dout_max_size; //@- Number of samples (per carrier, per antenna) allocated in I (and Q) input buffers
  size_t dout_clean;    //@- Number of clean samples (per carrier, per antenna) output in I (and Q) input buffers
  size_t dout_dim0;     //@- Number of antennas
  size_t dout_dim1;     //@- Number of carriers

  xip_ducddc_data *dout_i[XIP_DUCDDC_MAX_ANTENNAS][XIP_DUCDDC_MAX_CARRIERS]; //@- Real part of sample data
  xip_ducddc_data *dout_q[XIP_DUCDDC_MAX_ANTENNAS][XIP_DUCDDC_MAX_CARRIERS]; //@- Imaginary part of sample data

} xip_ducddc_v1_0_data_resp;

/**
 * DUCDDC handle type (opaque to user).
 */
struct _xip_ducddc_v1_0;
typedef struct _xip_ducddc_v1_0 xip_ducddc_v1_0;

/**
 * Fill in a configuration structure with the core's default values.
 *
 * @param     config     The configuration structure to be populated
 * @returns   Exit code  XIP_DUCDDC_STATUS_*
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_default_config(xip_ducddc_v1_0_config *config);

/**
 * Get version of model.
 *
 * @returns   String  Textual representation of model version
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
const char* xip_ducddc_v1_0_get_version(void);

/**
 * Create a new instance of the core based on some configuration values.
 *
 * @param     config      Pointer to a xip_ducddc_v1_0_config structure
 * @param     handler     Callback function for errors and warnings (providing a null
 *                        pointer means no messages are output)
 * @param     handle      Optional argument to be passed back to callback function
 *
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_v1_0 *xip_ducddc_v1_0_create(
  const xip_ducddc_v1_0_config *config,
  msg_handler                   handler,
  void                         *handle
);

/**
 * Reset an instance of the core.
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_reset(xip_ducddc_v1_0 *s);

/**
 * Apply a transaction on the data port.
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @param     req         Pointer to xip_ducddc_v1_0_data_req request structure
 * @param     resp        Pointer to xip_ducddc_v1_0_data_resp response structure
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_data_do
  ( xip_ducddc_v1_0           *s,
    xip_ducddc_v1_0_data_req  *req,
    xip_ducddc_v1_0_data_resp *resp
  );

/**
 * Calculate size of output in response to transaction.
 *
 * The number of input samples in the request structure is examined, and
 * used to compute the number of output samples that would be produced if
 * this transaction were presented to the xip_ducddc_v1_0_data_do function.
 * This number is written to the "dout_size" field of the response structure.
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @param     req         Pointer to xip_ducddc_v1_0_data_req request structure
 * @param     resp        Pointer to xip_ducddc_v1_0_data_resp response structure
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_data_calc_size
  ( xip_ducddc_v1_0           *s,
    xip_ducddc_v1_0_data_req  *req,
    xip_ducddc_v1_0_data_resp *resp
  );

/**
 * Query parameters of mixer.
 *
 * @param    freq_raster    Holds returned frequency raster, in Hz
 * @param    phase_raster   Holds returned phase raster, in radians
 * @param    gain_step      Holds returned minimum non-zero carrier gain available (DUC only)
 * @returns  Exit code      XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_ctrl_get_raster
  ( xip_ducddc_v1_0 *s,
    double *freq_raster,
    double *phase_raster,
    double *gain_step
  );

/**
 * Set parameters of a carrier.
 *
 * Values supplied will be quantized according to the mixer's raster parameters.
 *
 * @param    index       Index of carrier to manipulate
 * @param    f           Carrier frequency, in Hz
 * @param    phi         Carrier phase offset, in radians
 * @param    beta        Carrier gain
 * @returns  Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_ctrl_set_carrier
  ( xip_ducddc_v1_0 *s,
    int    index,
    double f,
    double phi,
    double beta
  );

/**
 * Query parameters of a carrier.
 *
 * @param    index       Index of carrier to manipulate
 * @param    f           Holds returned carrier frequency, in Hz
 * @param    phi         Holds returned carrier phase offset, in radians
 * @param    beta        Holds returned carrier gain
 * @returns  Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_ctrl_get_carrier
  ( xip_ducddc_v1_0 *s,
    int     index,
    double *f,
    double *phi,
    double *beta
  );

/**
 * Destroy an instance of the core and free any resources allocated.
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_destroy(xip_ducddc_v1_0 *s);

/**
 * Allocate appropriate buffers in a data request structure.
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @param     r           Pointer to request structure to set up
 * @param     n_samples   Number of samples to allocate (per carrier, per antenna)
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_alloc_data_req
  ( xip_ducddc_v1_0          *s,
    xip_ducddc_v1_0_data_req *r,
    unsigned n_samples
  );

/**
 * Allocate appropriate buffers in a data response structure.
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @param     r           Pointer to response structure to set up
 * @param     n_samples   Number of samples to allocate (per carrier, per antenna)
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_alloc_data_resp
  ( xip_ducddc_v1_0           *s,
    xip_ducddc_v1_0_data_resp *r,
    unsigned n_samples
  );

/**
 * Deallocate the buffers in a data request structure allocated by xip_ducddc_v1_0_alloc_data_req
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @param     r           Pointer to request structure to free
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_free_data_req
  ( xip_ducddc_v1_0          *s,
    xip_ducddc_v1_0_data_req *r
  );

/**
 * Deallocate the buffers in a data request structure allocated by xip_ducddc_v1_0_alloc_data_resp
 *
 * @param     s           Pointer to xip_ducddc_v1_0 state structure
 * @param     r           Pointer to response structure to free
 * @returns   Exit code   XIP_DUCDDC_STATUS_*
 *
 */
Ip_xilinx_ip_duc_ddc_compiler_v1_0_DLL
xip_ducddc_status xip_ducddc_v1_0_free_data_resp
  ( xip_ducddc_v1_0           *s,
    xip_ducddc_v1_0_data_resp *r
  );

#ifdef __cplusplus
} /* End of "C" linkage block */
#endif

#endif  /* _XIP_DUCDDC_V1_0_BITACC_CMODEL_H */

/* --- EOF --- */
