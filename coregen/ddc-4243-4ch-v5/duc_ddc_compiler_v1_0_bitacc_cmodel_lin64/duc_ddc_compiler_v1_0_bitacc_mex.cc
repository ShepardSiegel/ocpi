//  (c) Copyright 2010 Xilinx, Inc. All rights reserved.
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
////////////////////////////////////////////////////////////
#include "mex.h"
#include "duc_ddc_compiler_v1_0_bitacc_cmodel.h"
#include <map>
#include <stdlib.h>

//Map to hold valid state pointers
typedef unsigned int StateHandle;
typedef std::map<StateHandle, xip_ducddc_v1_0*> StateMap;
StateMap stateMap;

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Opcodes
enum MEXOpcode
{
  OP_GET_VERSION=0,
  OP_GET_DEFAULT_CONFIG=1,
  OP_CREATE=2,
  OP_DESTROY=3,
  OP_SIMULATE=4,
  OP_CALCULATE_OUTPUT_SIZES=5,
  OP_GET_RASTER=6,
  OP_GET_CARRIER=7,
  OP_SET_CARRIER=8
};

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//True if mx can be interpreted as a real numeric scalar
inline bool isRealScalar(const mxArray* mx)
{
  return mxGetNumberOfElements(mx)==1 && mxIsNumeric(mx) && !mxIsComplex(mx);
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//True if mx can be interpreted as a real numeric vector
inline bool isRealVector(const mxArray* mx)
{
  return mxGetNumberOfElements(mx)>=1 && mxIsNumeric(mx) && !mxIsComplex(mx);
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//True if mx can be interpreted as a single string
inline bool isString(const mxArray* mx)
{
  return mxIsChar(mx) && mxGetM(mx)==1 && mxGetN(mx)==mxGetNumberOfElements(mx);
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Free memory allocated to s and set to 0 (null)
void freeString(const char*& s)
{
  if (s)
  {
    delete[] s;
    s=0;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Free memory allocated to unsigned char array_data and set to 0 (null)
void freeArray(unsigned char*& array_data, int& array_max_size)
{
  if (array_data)
  {
    delete[] array_data;
    array_data=0;
    array_max_size=0;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Free memory allocated to integer array_data and set to 0 (null)
void freeArray(int*& array_data, int& array_max_size)
{
  if (array_data)
  {
    delete[] array_data;
    array_data=0;
    array_max_size=0;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Copy an unmanaged C-style string in s into a managed string
void copyString(const char*& s)
{
  unsigned int len=strlen(s);
  char* res=new char[len+1];
  strcpy(res,s);
  s=res;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Ensure unsigned char array is large enough for given size
void allocateArray(unsigned char*& array_data, int& array_max_size, int len)
{
  if (array_max_size<len)
  {
    freeArray(array_data,array_max_size);
    unsigned char* res=new unsigned char[len];
    array_data=res;
    array_max_size=len;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Ensure int array is large enough for given size
void allocateArray(int*& array_data, int& array_max_size, int len)
{
  if (array_max_size<len)
  {
    freeArray(array_data,array_max_size);
    int* res=new int[len];
    array_data=res;
    array_max_size=len;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Assign a string mxArray to managed string structure element e
bool assignElement(const mxArray* mx, const char*& e)
{
  unsigned int len=mxGetNumberOfElements(mx);
  if (!isString(mx) || len>=4096)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badString","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting string with length <=4096");
    return false;
  }

  freeString(e);
  char* res=new char[len+1];
  if (mxGetString(mx,res,len+1)!=0)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badCall","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Unexpected failure of mxGetString");
    return false;
  }

  e=res;
  return true;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Assign a numeric real scalar mxArray to structure element e
bool assignElement(const mxArray* mx, int& e)
{
  if (isRealScalar(mx))
  {
    double x=mxGetScalar(mx);
    e=static_cast<int>(x);
    return true;
  }
  else if (mxIsLogicalScalar(mx))
  {
    //Convert logical to 0 or 1
    e=(mxIsLogicalScalarTrue(mx) ? 1 : 0);
    return true;
  }

  mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting real numeric or logical scalar");
  return false;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Assign a numeric real scalar mxArray to structure element e
bool assignElement(const mxArray* mx, double& e)
{
  if (isRealScalar(mx))
  {
    e=mxGetScalar(mx);
    return true;
  }
  else if (mxIsLogicalScalar(mx))
  {
    //Convert logical to 0 or 1
    e=(mxIsLogicalScalarTrue(mx) ? 1.0 : 0.0);
    return true;
  }

  mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting real numeric or logical scalar");
  return false;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Assign a numeric real vector mxArray to structure element e and e_size
bool assignElement(const mxArray* mx, const int*& e, int& e_size)
{
  if (!isRealVector(mx) || !mxIsInt32(mx) || !mxGetData(mx))
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting real numeric vector of int32");
    return false;
  }

  e=static_cast<int*>(mxGetData(mx));
  e_size=mxGetNumberOfElements(mx);
  return true;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Create an empty scalar structure
mxArray* createEmptyStructure()
{
  const mwSize SCALAR_DIMS[]={1,1};
  const char* FIELDNAMES[]={""};
  mxArray* res=mxCreateStructArray(sizeof(SCALAR_DIMS)/sizeof(*SCALAR_DIMS),SCALAR_DIMS,0,FIELDNAMES);
  if (res==NULL) mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStruct","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not create empty structure");
  return res;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Create an real numeric scalar with the given value
mxArray* createScalar(double value)
{
  mxArray* res=mxCreateDoubleScalar(value);
  if (res==NULL) mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not create numeric scalar");
  return res;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Add a string field to a structure
bool addField(mxArray* mx, const char* fieldname, const char* value)
{
  unsigned int ix=mxAddField(mx,fieldname);
  if (ix==-1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badField","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not add field %s",fieldname);
    return false;
  }

  mxArray* mx_value=mxCreateString(value);
  if (mx_value==NULL)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badString","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not create string array for %s",value);
    return false;
  }

  mxSetFieldByNumber(mx,0,ix,mx_value);
  return true;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Add a double field to a structure
bool addField(mxArray* mx, const char* fieldname, double value)
{
  const mwSize SCALAR_DIMS[]={1,1};

  unsigned int ix=mxAddField(mx,fieldname);
  if (ix==-1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badField","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not add field %s",fieldname);
    return false;
  }

  mxArray* mx_value=mxCreateNumericArray(sizeof(SCALAR_DIMS)/sizeof(*SCALAR_DIMS),SCALAR_DIMS,mxDOUBLE_CLASS,mxREAL);
  if (mx_value==NULL || mxGetPr(mx_value)==NULL)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not create numeric scalar");
    return false;
  }

  *mxGetPr(mx_value)=value;
  mxSetFieldByNumber(mx,0,ix,mx_value);
  return true;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Add an unsigned char array field to a structure
bool addField(mxArray* mx, const char* fieldname, unsigned char* array_data, int array_size)
{
  const mwSize EMPTY_DIMS[] ={0,0};
  const mwSize VECTOR_DIMS[]={array_size,1};

  unsigned int ix=mxAddField(mx,fieldname);
  if (ix==-1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badField","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not add field %s",fieldname);
    return false;
  }

  mxArray* mx_value=mxCreateNumericArray(sizeof(VECTOR_DIMS)/sizeof(*VECTOR_DIMS),(array_size ? VECTOR_DIMS : EMPTY_DIMS),mxUINT8_CLASS,mxREAL);
  if (mx_value==NULL)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badVector","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not create numeric vector");
    return false;
  }

  memcpy(mxGetData(mx_value),static_cast<const void*>(array_data),sizeof(unsigned char)*array_size);
  mxSetFieldByNumber(mx,0,ix,mx_value);
  return true;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Add an int array field to a structure
bool addField(mxArray* mx, const char* fieldname, int* array_data, int array_size)
{
  const mwSize EMPTY_DIMS[] ={0,0};
  const mwSize VECTOR_DIMS[]={array_size,1};

  unsigned int ix=mxAddField(mx,fieldname);
  if (ix==-1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badField","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not add field %s",fieldname);
    return false;
  }

  mxArray* mx_value=mxCreateNumericArray(sizeof(VECTOR_DIMS)/sizeof(*VECTOR_DIMS),(array_size ? VECTOR_DIMS : EMPTY_DIMS),mxINT32_CLASS,mxREAL);
  if (mx_value==NULL)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badVector","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not create numeric vector");
    return false;
  }

  memcpy(mxGetData(mx_value),static_cast<const void*>(array_data),sizeof(int)*array_size);
  mxSetFieldByNumber(mx,0,ix,mx_value);
  return true;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Callback to report any messages/errors from the DLL

void msg_print(void* dummy, int error, const char* msg)
{
  mexPrintf("%s\n",msg);
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Configuration structure wrapper
class ConfigStructureWrapper
{
private:

  xip_ducddc_v1_0_config itsConfig;

public:

  ConfigStructureWrapper()
  {
    clear();
  }

  ~ConfigStructureWrapper()
  {
    freeString(itsConfig.name);
  }

  void clear()
  {
    xip_ducddc_v1_0_default_config(&itsConfig);

    //The C-style strings in itsConfig are not currently in managed memory, so need to copy
    copyString(itsConfig.name);
  }

  const xip_ducddc_v1_0_config* get() const { return &itsConfig; }

  //Assign a structure mxArray to wrapped configuration
  bool assign(const mxArray* mx)
  {
    if (!mxIsStruct(mx) || mxGetNumberOfElements(mx)!=1)
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting scalar structure of configuration parameters");
      return false;
    }

    //Loop through all parameters
    clear();
    for (unsigned int i=0; i<mxGetNumberOfFields(mx); i++)
    {
      const char* fieldname=mxGetFieldNameByNumber(mx,i);
           if (strcmp(fieldname,"name")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.name)) return false;
      }
      else if (strcmp(fieldname,"core_type")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.core_type)) return false;
      }
      else if (strcmp(fieldname,"ch_bandwidth")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.ch_bandwidth)) return false;
      }
      else if (strcmp(fieldname,"if_passband")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.if_passband)) return false;
      }
      else if (strcmp(fieldname,"digital_if")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.digital_if)) return false;
      }
      else if (strcmp(fieldname,"rf_rate")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.rf_rate)) return false;
      }
      else if (strcmp(fieldname,"clock_rate")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.clock_rate)) return false;
      }
      else if (strcmp(fieldname,"n_carriers")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.n_carriers)) return false;
      }
      else if (strcmp(fieldname,"n_antennas")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.n_antennas)) return false;
      }
      else if (strcmp(fieldname,"din_width")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.din_width)) return false;
      }
      else if (strcmp(fieldname,"dout_width")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.dout_width)) return false;
      }
      else if (strcmp(fieldname,"rounding_mode")==0)
      {
        if (!assignElement(mxGetFieldByNumber(mx,0,i),itsConfig.rounding_mode)) return false;
      }
      else
      {
        mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badFieldname","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Unexpected fieldname %s in configuration structure",fieldname);
        return false;
      }
    }

    return true;
  }

  //Convert into an mxArray structure
  mxArray* to_mxArray()
  {
    //Create empty structure
    mxArray* s=createEmptyStructure();
    if (s==NULL) return NULL;

    //Populate from default generics
    bool ok=true;
    if (!addField(s,"name",          itsConfig.name          )) ok=false;
    if (!addField(s,"core_type",     itsConfig.core_type     )) ok=false;
    if (!addField(s,"ch_bandwidth",  itsConfig.ch_bandwidth  )) ok=false;
    if (!addField(s,"if_passband",   itsConfig.if_passband   )) ok=false;
    if (!addField(s,"digital_if",    itsConfig.digital_if    )) ok=false;
    if (!addField(s,"rf_rate",       itsConfig.rf_rate       )) ok=false;
    if (!addField(s,"clock_rate",    itsConfig.clock_rate    )) ok=false;
    if (!addField(s,"n_carriers",    itsConfig.n_carriers    )) ok=false;
    if (!addField(s,"n_antennas",    itsConfig.n_antennas    )) ok=false;
    if (!addField(s,"din_width",     itsConfig.din_width     )) ok=false;
    if (!addField(s,"dout_width",    itsConfig.dout_width    )) ok=false;
    if (!addField(s,"rounding_mode", itsConfig.rounding_mode )) ok=false;

    if (!ok)
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Error converting configuration structure to Matlab format");
      mxDestroyArray(s);
      s=NULL;
    }

    return s;
  }
};

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Input structure wrapper
class DataRequestWrapper
{
private:

  xip_ducddc_v1_0_data_req itsRequest;

public:

  DataRequestWrapper()
  {
    clear();
  }

  ~DataRequestWrapper()
  {
  }

  void clear()
  {
    memset(static_cast<void*>(&itsRequest),sizeof(itsRequest),0);
  }

  xip_ducddc_v1_0_data_req* get() { return &itsRequest; }

  //Assign a structure mxArray to wrapped structure
  bool assign(const mxArray* mx)
  {
    if (!mxIsStruct(mx) || mxGetNumberOfElements(mx)!=1)
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting scalar structure for request");
      return false;
    }

    clear();
    for (unsigned int i=0; i<mxGetNumberOfFields(mx); i++)
    {
      const char* fieldname=mxGetFieldNameByNumber(mx,i);
      if (strcmp(fieldname,"din")==0)
      {
        mxArray *data = mxGetFieldByNumber(mx,0,i);

        if (!(mxIsDouble(data)))
        { mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting double-precision array for din field of request");
          return false;
        }

        mwSize total_dims = mxGetNumberOfDimensions(data);

        if (total_dims > 3 || total_dims < 1)
        { mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting three or fewer dimensions in request array");
          return false;
        }

        const mwSize *dims = mxGetDimensions(data);

        itsRequest.din_size = dims[0];
        itsRequest.din_dim0 = (total_dims > 1 ? dims[1] : 1);
        itsRequest.din_dim1 = (total_dims > 2 ? dims[2] : 1);

        if (itsRequest.din_dim0 > XIP_DUCDDC_MAX_ANTENNAS)
        { mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Too many antennas in request array");
          return false;
        }
        if (itsRequest.din_dim1 > XIP_DUCDDC_MAX_CARRIERS)
        { mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Too many carriers in request array");
          return false;
        }

        double *pi = mxGetPi(data);
        double *pr = mxGetPr(data);

        if (!pr)
        { mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Missing real data in request array!");
          return false;
        }

        for (int i = 0; i < itsRequest.din_dim1; i++)
        { for (int j = 0; j < itsRequest.din_dim0; j++)
          {
            itsRequest.din_i[j][i] = pr;
            itsRequest.din_q[j][i] = pi;

            pr += itsRequest.din_size;
            if (pi) pi += itsRequest.din_size;
          }
        }

      }
      else
      {
        mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badFieldname","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Unexpected fieldname %s in request structure",fieldname);
        return false;
      }
    }

    return true;
  }

};

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Output structure wrapper
class DataResponseWrapper
{
private:

  xip_ducddc_v1_0_data_resp itsResponse;
  mxArray *outArray;

public:

  DataResponseWrapper()
   : outArray(0)
  {
    clear();
  }

  ~DataResponseWrapper()
  {
    // Nothing to do, because all the memory belongs to MATLAB
  }

  void clear()
  {
    memset(static_cast<void*>(&itsResponse),sizeof(itsResponse),0);
  }

  xip_ducddc_v1_0_data_resp* get() { return &itsResponse; }

  //Allocate arrays based on result from calculate_output_sizes
  void allocateArrays()
  {
    mwSize dims[3];

    if (outArray) mxDestroyArray(outArray);

    dims[0] = itsResponse.dout_size;
    dims[1] = itsResponse.dout_dim0;
    dims[2] = itsResponse.dout_dim1;

    outArray = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxCOMPLEX);
    if (!outArray) return;

    double *pr = mxGetPr(outArray);
    double *pi = mxGetPi(outArray);

    for (int i = 0; i < itsResponse.dout_dim1; i++)
    { for (int j = 0; j < itsResponse.dout_dim0; j++)
      {
        itsResponse.dout_i[j][i] = pr;
        itsResponse.dout_q[j][i] = pi;

        pr += itsResponse.dout_size;
        pi += itsResponse.dout_size;
      }
    }
    
    itsResponse.dout_max_size = itsResponse.dout_size;
  }

  //Convert into an mxArray structure
  mxArray* to_mxArray()
  {
    //Create empty structure
    mxArray* s=createEmptyStructure();
    if (s==NULL) return NULL;

    //Populate from C structure
    bool ok=true;

    unsigned int ix=mxAddField(s,"dout");
    if (ix==-1)
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badField","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Could not add field 'dout'");
      ok = false;
    }

    mxSetFieldByNumber(s,0,ix,outArray);

    if (!ok)
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Error converting response structure to Matlab format");
      mxDestroyArray(s);
      s=NULL;
    }

    return s;
  }
};

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Called at MEX exit
void atMexExit()
{
  //mexPrintf("duc_ddc_compiler_v1_0_bitacc_mex:atMexExit:%d to delete\n",stateMap.size());

  //Release all state objects registered in stateMap
  for (StateMap::iterator i=stateMap.begin(); i!=stateMap.end(); i++)
  {
    xip_ducddc_v1_0_destroy(i->second);
  }
  stateMap.clear();
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Convert a state handle into a state structure pointer (or zero if state handle is invalid)
xip_ducddc_v1_0* get_state(StateHandle shandle)
{
  StateMap::const_iterator i=stateMap.find(shandle);
  if (i==stateMap.end()) return 0;
  return i->second;
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//Get a state handle from the numeric scalar array mx (or zero if error or invalid)
StateHandle get_state_handle(const mxArray* mx)
{
  if (!isRealScalar(mx))
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStateHandle","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:State handle must be a real numeric scalar");
    return 0;
  }

  //Get handle as an integer
  double x=mxGetScalar(mx);
  return static_cast<StateHandle>(x);
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_get_version(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_version:Expecting one output argument");
    return;
  }

  if (nrhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_version:Expecting one input argument");
    return;
  }

  plhs[0]=mxCreateString(xip_ducddc_v1_0_get_version());
  if (prhs[0]==NULL)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badString","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_version:Could not create string array");
    return;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_default_config(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:default_config:Expecting one output argument");
    return;
  }

  if (nrhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:default_config:Expecting one input argument");
    return;
  }

  //Convert default generics to mxArray structure
  ConfigStructureWrapper generics;
  plhs[0]=generics.to_mxArray();
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_create(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:create:Expecting one output argument");
    return;
  }

  if (nrhs!=2)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:create:Expecting two input arguments");
    return;
  }

  //Read second argument into generics structure
  ConfigStructureWrapper config;
  if (!config.assign(prhs[1])) return;

  //Now create the state object
  xip_ducddc_v1_0* state=xip_ducddc_v1_0_create(config.get(), &msg_print, 0);
  if (state)
  {
    //Register in state map
    static StateHandle nextStateHandle=0xDA000000;
    mxAssert(!get_state(nextStateHandle),"ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Expecting state handle to be unique");
    stateMap[nextStateHandle]=state;

    plhs[0]=createScalar(static_cast<double>(nextStateHandle));
    nextStateHandle++;
    if (!nextStateHandle) nextStateHandle++;  //A zero state handle is not valid
  }

}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_destroy(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=0)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:destroy:Expecting no output arguments");
    return;
  }

  if (nrhs!=2)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:destroy:Expecting two input arguments");
    return;
  }

  //Get state handle
  StateHandle shandle=get_state_handle(prhs[1]);
  xip_ducddc_v1_0* state=get_state(shandle);

  //Destroy object if it still exists
  if (state)
  {
    xip_ducddc_v1_0_destroy(state);
  }

  //Removed from state map
  stateMap.erase(shandle);
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_simulate(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:simulate:Expecting one output argument");
    return;
  }

  if (nrhs!=3)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:simulate:Expecting three input arguments");
    return;
  }

  //Get state handle
  StateHandle shandle=get_state_handle(prhs[1]);
  xip_ducddc_v1_0* state=get_state(shandle);
  if (!state)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStateHandle","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:simulate:Invalid state handle:%d",shandle);
    return;
  }

  //Get request structure
  DataRequestWrapper inputs;
  if (!inputs.assign(prhs[2]))  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:simulate:Could not assign inputs from DataRequestWrapper");
    return;
  }

  //Set up response structure
  DataResponseWrapper outputs;

  // Allocate empty response
  xip_ducddc_v1_0_alloc_data_resp(state, outputs.get(), 0);

  //Determine the size of output results for this input
  if (xip_ducddc_v1_0_data_calc_size(state,inputs.get(),outputs.get())==0)
  {
    //Calculate successful, so ensure allocated memory is sufficient
    outputs.allocateArrays();

    //Now call the model
    if (opcode==OP_CALCULATE_OUTPUT_SIZES || xip_ducddc_v1_0_data_do(state,inputs.get(),outputs.get())==0)
    {
      //Simulate successful
      plhs[0]=outputs.to_mxArray();
    } else {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:SimFail","INFO:duc_ddc_compiler_v1_0_bitacc_mex: ERROR: Simulation Failed!'");
      return;
    }
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_get_raster(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_raster:Expecting one output argument");
    return;
  }

  if (nrhs!=2)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_raster:Expecting two input arguments");
    return;
  }

  //Get state handle
  StateHandle shandle=get_state_handle(prhs[1]);
  xip_ducddc_v1_0* state=get_state(shandle);
  if (!state)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStateHandle","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_raster:Invalid state handle:%d",shandle);
    return;
  }

  plhs[0] = createEmptyStructure();
  if (plhs[0]==NULL) return;

  double freq_raster, phase_raster, gain_step;

  if (xip_ducddc_v1_0_ctrl_get_raster(state, &freq_raster, &phase_raster, &gain_step) != XIP_DUCDDC_STATUS_OK)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badCall","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_raster:Unexpected failure of ctrl_get_raster()");
    return;
  }

  bool ok=true;

  if (!addField(plhs[0],"freq_raster",  freq_raster  )) ok=false;
  if (!addField(plhs[0],"phase_raster", phase_raster )) ok=false;
  if (!addField(plhs[0],"gain_step",    gain_step    )) ok=false;

  if (!ok)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_raster:Error converting data to Matlab structure");
    mxDestroyArray(plhs[0]);
    plhs[0]=NULL;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_get_carrier(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Expecting one output argument");
    return;
  }

  if (nrhs!=3)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Expecting three input arguments");
    return;
  }

  //Get state handle
  StateHandle shandle=get_state_handle(prhs[1]);
  xip_ducddc_v1_0* state=get_state(shandle);
  if (!state)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStateHandle","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Invalid state handle:%d",shandle);
    return;
  }

  if (mxIsEmpty(prhs[2]) || !mxIsNumeric(prhs[2]))
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Could not determine carrier index");
    return;
  }

  int carrier = static_cast<int>(mxGetScalar(prhs[2]));

  if (carrier < 0 || carrier > XIP_DUCDDC_MAX_CARRIERS)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Carrier out of range");
    return;
  }

  plhs[0] = createEmptyStructure();
  if (plhs[0]==NULL) return;

  double f, phi, beta;

  if (xip_ducddc_v1_0_ctrl_get_carrier(state, carrier, &f, &phi, &beta) != XIP_DUCDDC_STATUS_OK)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badCall","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Unexpected failure of ctrl_get_carrier()");
    return;
  }

  bool ok=true;

  if (!addField(plhs[0],"f",    f    )) ok=false;
  if (!addField(plhs[0],"phi",  phi  )) ok=false;
  if (!addField(plhs[0],"beta", beta )) ok=false;

  if (!ok)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:get_carrier:Error converting data to Matlab structure");
    mxDestroyArray(plhs[0]);
    plhs[0]=NULL;
  }

}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void do_set_carrier(MEXOpcode opcode, int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  if (nlhs!=0)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOutput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Expecting no output arguments");
    return;
  }

  if (nrhs!=4)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badInput","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Expecting four input arguments");
    return;
  }

  //Get state handle
  StateHandle shandle=get_state_handle(prhs[1]);
  xip_ducddc_v1_0* state=get_state(shandle);
  if (!state)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStateHandle","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Invalid state handle:%d",shandle);
    return;
  }

  if (mxIsEmpty(prhs[2]) || !mxIsNumeric(prhs[2]))
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Could not determine carrier index");
    return;
  }

  int carrier = static_cast<int>(mxGetScalar(prhs[2]));

  if (carrier < 0 || carrier > XIP_DUCDDC_MAX_CARRIERS)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badScalar","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Carrier out of range");
    return;
  }

  if (!mxIsStruct(prhs[3]) || mxGetNumberOfElements(prhs[3])!=1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badStructure","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Expecting scalar structure of carrier parameters");
    return;
  }

  double f, phi, beta;

  // Get default values, in case not all details have been specified
  if (xip_ducddc_v1_0_ctrl_get_carrier(state, carrier, &f, &phi, &beta) != XIP_DUCDDC_STATUS_OK)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badCall","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Unexpected failure of ctrl_get_carrier()");
    return;
  }

  for (int i = 0; i < mxGetNumberOfFields(prhs[3]); i++)
  {
    const char* fieldname = mxGetFieldNameByNumber(prhs[3],i);

         if (strcmp(fieldname,"f")==0)
    {
      if (!assignElement(mxGetFieldByNumber(prhs[3],0,i),f)) return;
    }
    else if (strcmp(fieldname,"phi")==0)
    {
      if (!assignElement(mxGetFieldByNumber(prhs[3],0,i),phi)) return;
    }
    else if (strcmp(fieldname,"beta")==0)
    {
      if (!assignElement(mxGetFieldByNumber(prhs[3],0,i),beta)) return;
    }
    else
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badFieldname","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Unexpected fieldname %s in carrier parameters",fieldname);
      return;
    }
  }

  if (xip_ducddc_v1_0_ctrl_set_carrier(state, carrier, f, phi, beta) != XIP_DUCDDC_STATUS_OK)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badCall","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:set_carrier:Unexpected failure of ctrl_set_carrier()");
    return;
  }
}

//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
  //Register our exit functions (should be cheap enough to call repeatedly...)
  mexAtExit(atMexExit);

  //Check we have a valid opcode
  if (nrhs<1)
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOpcode","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Missing opcode");
    return;
  }
  if (!isRealScalar(prhs[0]))
  {
    mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOpcode","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:opcode must be a real numeric scalar");
    return;
  }

  //Get opcode as an integer
  double x=mxGetScalar(prhs[0]);
  MEXOpcode opcode=static_cast<MEXOpcode>(static_cast<int>(x));
  switch (opcode)
  {
    //version=get_version()
    case OP_GET_VERSION:
    {
      do_get_version(opcode,nlhs,plhs,nrhs,prhs);
    } break;

    //generics=get_default_generics()
    case OP_GET_DEFAULT_CONFIG:
    {
      do_default_config(opcode,nlhs,plhs,nrhs,prhs);
    } break;

    //state=create(generics)
    case OP_CREATE:
    {
      do_create(opcode,nlhs,plhs,nrhs,prhs);
    } break;

    //destroy(state)
    case OP_DESTROY:
    {
      do_destroy(opcode,nlhs,plhs,nrhs,prhs);
    } break;

    //outputs=simulate(state,inputs)
    //outputs=calculate_output_sizes(state,inputs)
    case OP_SIMULATE:
    case OP_CALCULATE_OUTPUT_SIZES:
    {
      do_simulate(opcode,nlhs,plhs,nrhs,prhs);
    } break;

    case OP_GET_RASTER:
    {
      do_get_raster(opcode,nlhs,plhs,nrhs,prhs);
      break;
    }

    case OP_GET_CARRIER:
    {
      do_get_carrier(opcode,nlhs,plhs,nrhs,prhs);
      break;
    }

    case OP_SET_CARRIER:
    {
      do_set_carrier(opcode,nlhs,plhs,nrhs,prhs);
      break;
    }

    default:
    {
      mexErrMsgIdAndTxt("duc_ddc_compiler_v1_0_bitacc_mex:badOpcode","ERROR:duc_ddc_compiler_v1_0_bitacc_mex:Invalid opcode:%d",static_cast<int>(opcode));
      return;
    } break;
  }

}
