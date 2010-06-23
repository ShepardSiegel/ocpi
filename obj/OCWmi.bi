signature OCWmi where {
import ¶ConfigReg®¶;
		   
import ¶DReg®¶;
	      
import ¶FIFOF_®¶;
		
import ¶FIFOF®¶;
	       
import ¶FIFO®¶;
	      
import ¶Inout®¶;
	       
import ¶List®¶;
	      
import ¶Clocks®¶;
		
import ¶ListN®¶;
	       
import ¶PrimArray®¶;
		   
import ¶Probe®¶;
	       
import ¶RevertingVirtualReg®¶;
			     
import ¶Vector®¶;
		
import ¶Connectable®¶;
		     
import ¶DefaultValue®¶;
		      
import ¶FShow®¶;
	       
import ¶GetPut®¶;
		
import ¶FIFOLevel®¶;
		   
import OCWipDefs;
		
import ¶SpecialFIFOs®¶;
		      
import ¶TieOff®¶;
		
struct (OCWmi.WmiAttributes :: *) = {
    OCWmi.continuous :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.dataWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmi.byteWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmi.impreciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.preciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.talkBack :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWmi.WmiAttributes;
								  
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWmi.WmiAttributes;
								
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWmi.WmiAttributes;
								      
instance OCWmi ¶Prelude®¶.¶Bits®¶ OCWmi.WmiAttributes 68;
							
instance OCWmi ¶Prelude®¶.¶Eq®¶ OCWmi.WmiAttributes;
						   
instance OCWmi ¶DefaultValue®¶.¶DefaultValue®¶ OCWmi.WmiAttributes;
								  
class (OCWmi.DWordWidth :: # -> *) ndw where {
};
 
instance OCWmi OCWmi.DWordWidth 1;
				 
instance OCWmi OCWmi.DWordWidth 2;
				 
instance OCWmi OCWmi.DWordWidth 4;
				 
instance OCWmi OCWmi.DWordWidth 8;
				 
type (OCWmi.WmiM4B :: *) = OCWmi.Wmi_m 14 12 32 0 4 32;
						      
type (OCWmi.WmiS4B :: *) = OCWmi.Wmi_s 14 12 32 0 4 32;
						      
type (OCWmi.WmiM8B :: *) = OCWmi.Wmi_m 14 12 64 0 8 32;
						      
type (OCWmi.WmiS8B :: *) = OCWmi.Wmi_s 14 12 64 0 8 32;
						      
type (OCWmi.WmiM16B :: *) = OCWmi.Wmi_m 14 12 128 0 16 32;
							 
type (OCWmi.WmiS16B :: *) = OCWmi.Wmi_s 14 12 128 0 16 32;
							 
type (OCWmi.WmiM32B :: *) = OCWmi.Wmi_m 14 12 256 0 32 32;
							 
type (OCWmi.WmiS32B :: *) = OCWmi.Wmi_s 14 12 256 0 32 32;
							 
type (OCWmi.WmiEM4B :: *) = OCWmi.Wmi_Em 14 12 32 0 4 32;
							
type (OCWmi.WmiES4B :: *) = OCWmi.Wmi_Es 14 12 32 0 4 32;
							
type (OCWmi.WmiEM8B :: *) = OCWmi.Wmi_Em 14 12 64 0 8 32;
							
type (OCWmi.WmiES8B :: *) = OCWmi.Wmi_Es 14 12 64 0 8 32;
							
type (OCWmi.WmiEM16B :: *) = OCWmi.Wmi_Em 14 12 128 0 16 32;
							   
type (OCWmi.WmiES16B :: *) = OCWmi.Wmi_Es 14 12 128 0 16 32;
							   
type (OCWmi.WmiEM32B :: *) = OCWmi.Wmi_Em 14 12 256 0 32 32;
							   
type (OCWmi.WmiES32B :: *) = OCWmi.Wmi_Es 14 12 256 0 32 32;
							   
struct (OCWmi.WmiReq :: # -> # -> *) na nb = {
    OCWmi.cmd :: OCWipDefs.OCP_CMD;
    OCWmi.reqLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.reqInfo :: ¶Prelude®¶.¶Bit®¶ 1;
    OCWmi.addrSpace :: ¶Prelude®¶.¶Bit®¶ 1;
    OCWmi.addr :: ¶Prelude®¶.¶Bit®¶ na;
    OCWmi.burstLength :: ¶Prelude®¶.¶Bit®¶ nb
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.WmiReq na nb);
								   
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.WmiReq na nb);
								 
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.WmiReq na nb);
								       
instance OCWmi (¶Prelude®¶.¶Add®¶ 3 _v109 _v112,
		¶Prelude®¶.¶Add®¶ 1 _v106 _v109,
		¶Prelude®¶.¶Add®¶ 1 _v100 _v103,
		¶Prelude®¶.¶Add®¶ _v113 _v116 _v100,
		¶Prelude®¶.¶Add®¶ 1 _v103 _v106) =>
	       ¶Prelude®¶.¶Bits®¶ (OCWmi.WmiReq _v113 _v116) _v112;
								  
instance OCWmi ¶Prelude®¶.¶Eq®¶ (OCWmi.WmiReq na nb);
						    
struct (OCWmi.WmiDh :: # -> # -> # -> *) nd ni ne = {
    OCWmi.dataValid :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.dataLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd;
    OCWmi.dataInfo :: ¶Prelude®¶.¶Bit®¶ ni;
    OCWmi.dataByteEn :: ¶Prelude®¶.¶Bit®¶ ne
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.WmiDh nd ni ne);
								     
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.WmiDh nd ni ne);
								   
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.WmiDh nd ni ne);
									 
instance OCWmi (¶Prelude®¶.¶Add®¶ 1 _v103 _v106,
		¶Prelude®¶.¶Add®¶ _v107 _v100 _v103,
		¶Prelude®¶.¶Add®¶ _v110 _v113 _v100,
		¶Prelude®¶.¶Add®¶ 1 _v106 _v109) =>
	       ¶Prelude®¶.¶Bits®¶ (OCWmi.WmiDh _v107 _v110 _v113) _v109;
								       
instance OCWmi ¶Prelude®¶.¶Eq®¶ (OCWmi.WmiDh nd ni ne);
						      
struct (OCWmi.WmiResp :: # -> *) nd = {
    OCWmi.resp :: OCWipDefs.OCP_RESP;
    OCWmi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.WmiResp nd);
								 
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.WmiResp nd);
							       
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.WmiResp nd);
								     
instance OCWmi (¶Prelude®¶.¶Add®¶ 2 _v104 _v100) => ¶Prelude®¶.¶Bits®¶ (OCWmi.WmiResp _v104) _v100;
												  
instance OCWmi ¶Prelude®¶.¶Eq®¶ (OCWmi.WmiResp nd);
						  
OCWmi.wmiIdleRequest :: OCWmi.WmiReq na nb;
					  
OCWmi.wmiIdleDh :: OCWmi.WmiDh nd ni ne;
				       
OCWmi.wmiIdleResp :: OCWmi.WmiResp nd;
				     
interface (OCWmi.Wmi_m :: # -> # -> # -> # -> # -> # -> *)
	    na
	    nb
	    nd
	    ni
	    ne
	    nf {-# always_ready  #-} = {
    OCWmi.getReq :: OCWmi.WmiReq na nb {-# arg_names = [], result = "req" #-};
    OCWmi.getDh :: OCWmi.WmiDh nd ni ne {-# arg_names = [], result = "dh" #-};
    OCWmi.putResp :: OCWmi.WmiResp nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [resp],
								  always_enabled ,
								  prefixs = "" #-};
    OCWmi.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWmi.sDataThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						      enable = "SDataThreadBusy",
						      prefixs = "" #-};
    OCWmi.sRespLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SRespLast", prefixs = "" #-};
    OCWmi.sFlag :: ¶Prelude®¶.¶Bit®¶ nf -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SFlag¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.mFlag :: ¶Prelude®¶.¶Bit®¶ nf {-# arg_names = [], result = "MFlag", prefixs = "" #-};
    OCWmi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-};
    OCWmi.sReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SReset_n", prefixs = "" #-}
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.Wmi_m na nb nd ni ne nf);
									      
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.Wmi_m na nb nd ni ne nf);
									    
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.Wmi_m na nb nd ni ne nf);
										  
interface (OCWmi.Wmi_s :: # -> # -> # -> # -> # -> # -> *)
	    na
	    nb
	    nd
	    ni
	    ne
	    nf {-# always_ready  #-} = {
    OCWmi.putReq :: OCWmi.WmiReq na nb -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [req],
								   always_enabled ,
								   prefixs = "" #-};
    OCWmi.putDh :: OCWmi.WmiDh nd ni ne -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [dh],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.getResp :: OCWmi.WmiResp nd {-# arg_names = [], result = "resp" #-};
    OCWmi.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						result = "SThreadBusy",
						prefixs = "" #-};
    OCWmi.sDataThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						    result = "SDataThreadBusy",
						    prefixs = "" #-};
    OCWmi.sRespLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SRespLast", prefixs = "" #-};
    OCWmi.sFlag :: ¶Prelude®¶.¶Bit®¶ nf {-# arg_names = [], result = "SFlag", prefixs = "" #-};
    OCWmi.mFlag :: ¶Prelude®¶.¶Bit®¶ nf -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MFlag¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.sReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SReset_n", prefixs = "" #-};
    OCWmi.mReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReset_n", prefixs = "" #-}
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.Wmi_s na nb nd ni ne nf);
									      
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.Wmi_s na nb nd ni ne nf);
									    
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.Wmi_s na nb nd ni ne nf);
										  
interface (OCWmi.Wmi_Em :: # -> # -> # -> # -> # -> # -> *)
	    na
	    nb
	    nd
	    ni
	    ne
	    nf {-# always_ready  #-} = {
    OCWmi.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 {-# arg_names = [], result = "MCmd", prefixs = "" #-};
    OCWmi.mReqLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReqLast", prefixs = "" #-};
    OCWmi.mReqInfo :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "MReqInfo", prefixs = "" #-};
    OCWmi.mAddrSpace :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "MAddrSpace", prefixs = "" #-};
    OCWmi.mAddr :: ¶Prelude®¶.¶Bit®¶ na {-# arg_names = [], result = "MAddr", prefixs = "" #-};
    OCWmi.mBurstLength :: ¶Prelude®¶.¶Bit®¶ nb {-# arg_names = [],
						   result = "MBurstLength",
						   prefixs = "" #-};
    OCWmi.mDataValid :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MDataValid", prefixs = "" #-};
    OCWmi.mDataLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MDataLast", prefixs = "" #-};
    OCWmi.mData :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [], result = "MData", prefixs = "" #-};
    OCWmi.mDataInfo :: ¶Prelude®¶.¶Bit®¶ ni {-# arg_names = [], result = "MDataInfo", prefixs = "" #-};
    OCWmi.mDataByteEn :: ¶Prelude®¶.¶Bit®¶ ne {-# arg_names = [],
						  result = "MDataByteEn",
						  prefixs = "" #-};
    OCWmi.sResp :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SResp¡],
								   always_enabled ,
								   prefixs = "" #-};
    OCWmi.sData :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SData¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWmi.sDataThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						      enable = "SDataThreadBusy",
						      prefixs = "" #-};
    OCWmi.sRespLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SRespLast", prefixs = "" #-};
    OCWmi.sFlag :: ¶Prelude®¶.¶Bit®¶ nf -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SFlag¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.mFlag :: ¶Prelude®¶.¶Bit®¶ nf {-# arg_names = [], result = "MFlag", prefixs = "" #-};
    OCWmi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-};
    OCWmi.sReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SReset_n", prefixs = "" #-}
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.Wmi_Em na nb nd ni ne nf);
									       
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.Wmi_Em na nb nd ni ne nf);
									     
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.Wmi_Em na nb nd ni ne nf);
										   
interface (OCWmi.Wmi_Es :: # -> # -> # -> # -> # -> # -> *)
	    na
	    nb
	    nd
	    ni
	    ne
	    nf {-# always_ready  #-} = {
    OCWmi.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MCmd¡],
								  always_enabled ,
								  prefixs = "" #-};
    OCWmi.mReqLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReqLast", prefixs = "" #-};
    OCWmi.mReqInfo :: ¶Prelude®¶.¶Bit®¶ 1 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MReqInfo¡],
								      always_enabled ,
								      prefixs = "" #-};
    OCWmi.mAddrSpace :: ¶Prelude®¶.¶Bit®¶ 1 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MAddrSpace¡],
									always_enabled ,
									prefixs = "" #-};
    OCWmi.mAddr :: ¶Prelude®¶.¶Bit®¶ na -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MAddr¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.mBurstLength :: ¶Prelude®¶.¶Bit®¶ nb -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MBurstLength¡],
									   always_enabled ,
									   prefixs = "" #-};
    OCWmi.mDataValid :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						 enable = "MDataValid",
						 prefixs = "" #-};
    OCWmi.mDataLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MDataLast", prefixs = "" #-};
    OCWmi.mData :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MData¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.mDataInfo :: ¶Prelude®¶.¶Bit®¶ ni -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MDataInfo¡],
									always_enabled ,
									prefixs = "" #-};
    OCWmi.mDataByteEn :: ¶Prelude®¶.¶Bit®¶ ne -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MDataByteEn¡],
									  always_enabled ,
									  prefixs = "" #-};
    OCWmi.sResp :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SResp", prefixs = "" #-};
    OCWmi.sData :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [], result = "SData", prefixs = "" #-};
    OCWmi.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						result = "SThreadBusy",
						prefixs = "" #-};
    OCWmi.sDataThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						    result = "SDataThreadBusy",
						    prefixs = "" #-};
    OCWmi.sRespLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SRespLast", prefixs = "" #-};
    OCWmi.sFlag :: ¶Prelude®¶.¶Bit®¶ nf {-# arg_names = [], result = "SFlag", prefixs = "" #-};
    OCWmi.mFlag :: ¶Prelude®¶.¶Bit®¶ nf -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [arg_mFlag],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmi.sReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SReset_n", prefixs = "" #-};
    OCWmi.mReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReset_n", prefixs = "" #-}
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.Wmi_Es na nb nd ni ne nf);
									       
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.Wmi_Es na nb nd ni ne nf);
									     
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.Wmi_Es na nb nd ni ne nf);
										   
instance OCWmi ¶Connectable®¶.¶Connectable®¶ (OCWmi.Wmi_Em na nb nd ni ne nf)
	       (OCWmi.Wmi_Es na nb nd ni ne nf);
					       
instance OCWmi ¶Connectable®¶.¶Connectable®¶ (OCWmi.Wmi_m na nb nd ni ne nf)
	       (OCWmi.Wmi_Es na nb nd ni ne nf);
					       
instance OCWmi ¶Connectable®¶.¶Connectable®¶ (OCWmi.Wmi_Em na nb nd ni ne nf)
	       (OCWmi.Wmi_s na nb nd ni ne nf);
					      
instance OCWmi ¶Connectable®¶.¶Connectable®¶ (OCWmi.Wmi_m na nb nd ni ne nf)
	       (OCWmi.Wmi_s na nb nd ni ne nf);
					      
OCWmi.toWmiM :: OCWmi.Wmi_Em na nb nd ni ne nf -> OCWmi.Wmi_m na nb nd ni ne nf;
									       
OCWmi.mkWmiMtoEm :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		    OCWmi.Wmi_m na nb nd ni ne nf -> _m__ (OCWmi.Wmi_Em na nb nd ni ne nf);
											  
OCWmi.toWmiS :: OCWmi.Wmi_Es na nb nd ni ne nf -> OCWmi.Wmi_s na nb nd ni ne nf;
									       
OCWmi.mkWmiStoES :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		    OCWmi.Wmi_s na nb nd ni ne nf -> _m__ (OCWmi.Wmi_Es na nb nd ni ne nf);
											  
interface (OCWmi.WmiMasterIfc :: # -> # -> # -> # -> # -> # -> *) na nb nd ni ne nf = {
    OCWmi.req :: ¶Prelude®¶.¶Bool®¶ ->
		 ¶Prelude®¶.¶Bit®¶ na ->
		 ¶Prelude®¶.¶Bit®¶ nb ->
		 ¶Prelude®¶.¶Bool®¶ -> ¶Prelude®¶.¶Bit®¶ nf -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [write,
												     addr,
												     bl,
												     doneWithMessage,
												     mf] #-};
    OCWmi.dh :: ¶Prelude®¶.¶Bit®¶ nd ->
		¶Prelude®¶.¶Bit®¶ ne -> ¶Prelude®¶.¶Bool®¶ -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [wdata,
												    be,
												    dataLast] #-};
    OCWmi.resp :: ¶Prelude®¶.¶ActionValue®¶ (OCWmi.WmiResp nd) {-# arg_names = [] #-};
    OCWmi.attn :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWmi.anyBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWmi.peekSFlag :: ¶Prelude®¶.¶Bit®¶ nf {-# arg_names = [] #-};
    OCWmi.reqInfo :: ¶Prelude®¶.¶Bit®¶ 8 {-# arg_names = [] #-};
    OCWmi.mesgLength :: ¶Prelude®¶.¶Bit®¶ 24 {-# arg_names = [] #-};
    OCWmi.zeroLengthMesg :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWmi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWmi.mas :: OCWmi.Wmi_m na nb nd ni ne nf
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.WmiMasterIfc na nb nd ni ne nf);
										     
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.WmiMasterIfc na nb nd ni ne nf);
										   
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.WmiMasterIfc na nb nd ni ne nf);
											 
OCWmi.mkWmiMaster :: (¶Prelude®¶.¶Add®¶ b_ 24 nf,
		      ¶Prelude®¶.¶Add®¶ a_ 8 nf,
		      ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		     _m__ (OCWmi.WmiMasterIfc na nb nd ni ne nf);
								
interface (OCWmi.WmiSlaveIfc :: # -> # -> # -> # -> # -> # -> *) na nb nd ni ne nf = {
    OCWmi.req :: ¶Prelude®¶.¶ActionValue®¶ (OCWmi.WmiReq na nb) {-# arg_names = [] #-};
    OCWmi.dh :: ¶Prelude®¶.¶ActionValue®¶ (OCWmi.WmiDh nd ni ne) {-# arg_names = [] #-};
    OCWmi.respd :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [rdata] #-};
    OCWmi.drvSFlag :: ¶Prelude®¶.¶Bit®¶ nf -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [sf] #-};
    OCWmi.forceSThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWmi.allowReq :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWmi.peekMFlag :: ¶Prelude®¶.¶Bit®¶ nf {-# arg_names = [] #-};
    OCWmi.reqInfo :: ¶Prelude®¶.¶Bit®¶ 8 {-# arg_names = [] #-};
    OCWmi.mesgLength :: ¶Prelude®¶.¶Bit®¶ 24 {-# arg_names = [] #-};
    OCWmi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWmi.slv :: OCWmi.Wmi_s na nb nd ni ne nf
};
 
instance OCWmi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmi.WmiSlaveIfc na nb nd ni ne nf);
										    
instance OCWmi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmi.WmiSlaveIfc na nb nd ni ne nf);
										  
instance OCWmi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmi.WmiSlaveIfc na nb nd ni ne nf);
											
OCWmi.mkWmiSlave :: (¶Prelude®¶.¶Add®¶ b_ 24 nf,
		     ¶Prelude®¶.¶Add®¶ a_ 8 nf,
		     ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		    _m__ (OCWmi.WmiSlaveIfc na nb nd ni ne nf)
}
