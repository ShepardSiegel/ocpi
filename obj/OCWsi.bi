signature OCWsi where {
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
		
struct (OCWsi.WsiAttributes :: *) = {
    OCWsi.continuous :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.dataWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWsi.byteWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWsi.impreciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.preciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.abortable :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.earlyRequest :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWsi.WsiAttributes;
								  
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWsi.WsiAttributes;
								
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWsi.WsiAttributes;
								      
instance OCWsi ¶Prelude®¶.¶Bits®¶ OCWsi.WsiAttributes 69;
							
instance OCWsi ¶Prelude®¶.¶Eq®¶ OCWsi.WsiAttributes;
						   
instance OCWsi ¶DefaultValue®¶.¶DefaultValue®¶ OCWsi.WsiAttributes;
								  
type (OCWsi.WsiM4B :: *) = OCWsi.Wsi_m 12 32 4 8 0;
						  
type (OCWsi.WsiS4B :: *) = OCWsi.Wsi_s 12 32 4 8 0;
						  
type (OCWsi.WsiM8B :: *) = OCWsi.Wsi_m 12 64 8 8 0;
						  
type (OCWsi.WsiS8B :: *) = OCWsi.Wsi_s 12 64 8 8 0;
						  
type (OCWsi.WsiM16B :: *) = OCWsi.Wsi_m 12 128 16 8 0;
						     
type (OCWsi.WsiS16B :: *) = OCWsi.Wsi_s 12 128 16 8 0;
						     
type (OCWsi.WsiM32B :: *) = OCWsi.Wsi_m 12 256 32 8 0;
						     
type (OCWsi.WsiS32B :: *) = OCWsi.Wsi_s 12 256 32 8 0;
						     
type (OCWsi.WsiEM4B :: *) = OCWsi.Wsi_Em 12 32 4 8 0;
						    
type (OCWsi.WsiES4B :: *) = OCWsi.Wsi_Es 12 32 4 8 0;
						    
type (OCWsi.WsiEM8B :: *) = OCWsi.Wsi_Em 12 64 8 8 0;
						    
type (OCWsi.WsiES8B :: *) = OCWsi.Wsi_Es 12 64 8 8 0;
						    
type (OCWsi.WsiEM16B :: *) = OCWsi.Wsi_Em 12 128 16 8 0;
						       
type (OCWsi.WsiES16B :: *) = OCWsi.Wsi_Es 12 128 16 8 0;
						       
type (OCWsi.WsiEM32B :: *) = OCWsi.Wsi_Em 12 256 32 8 0;
						       
type (OCWsi.WsiES32B :: *) = OCWsi.Wsi_Es 12 256 32 8 0;
						       
struct (OCWsi.WsiReq :: # -> # -> # -> # -> # -> *) nb nd ng nh ni = {
    OCWsi.cmd :: OCWipDefs.OCP_CMD;
    OCWsi.reqLast :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.burstPrecise :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.burstLength :: ¶Prelude®¶.¶Bit®¶ nb;
    OCWsi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd;
    OCWsi.byteEn :: ¶Prelude®¶.¶Bit®¶ ng;
    OCWsi.reqInfo :: ¶Prelude®¶.¶Bit®¶ nh;
    OCWsi.dataInfo :: ¶Prelude®¶.¶Bit®¶ ni
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.WsiReq nb nd ng nh ni);
									    
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.WsiReq nb nd ng nh ni);
									  
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.WsiReq nb nd ng nh ni);
										
instance OCWsi (¶Prelude®¶.¶Add®¶ 3 _v115 _v118,
		¶Prelude®¶.¶Add®¶ 1 _v109 _v112,
		¶Prelude®¶.¶Add®¶ _v110 _v106 _v109,
		¶Prelude®¶.¶Add®¶ _v113 _v103 _v106,
		¶Prelude®¶.¶Add®¶ _v116 _v100 _v103,
		¶Prelude®¶.¶Add®¶ _v119 _v122 _v100,
		¶Prelude®¶.¶Add®¶ 1 _v112 _v115) =>
	       ¶Prelude®¶.¶Bits®¶ (OCWsi.WsiReq _v110 _v113 _v116 _v119 _v122) _v118;
										    
instance OCWsi ¶Prelude®¶.¶Eq®¶ (OCWsi.WsiReq nb nd ng nh ni);
							     
OCWsi.wsiIdleRequest :: OCWsi.WsiReq nb nd ng nh ni;
						   
interface (OCWsi.Wsi_m :: # -> # -> # -> # -> # -> *) nb nd ng nh ni {-# always_ready  #-} = {
    OCWsi.get :: OCWsi.WsiReq nb nd ng nh ni {-# arg_names = [], result = "req" #-};
    OCWsi.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWsi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-};
    OCWsi.sReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SReset_n", prefixs = "" #-}
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.Wsi_m nb nd ng nh ni);
									   
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.Wsi_m nb nd ng nh ni);
									 
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.Wsi_m nb nd ng nh ni);
									       
interface (OCWsi.Wsi_s :: # -> # -> # -> # -> # -> *) nb nd ng nh ni {-# always_ready  #-} = {
    OCWsi.put :: OCWsi.WsiReq nb nd ng nh ni -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [req],
									 always_enabled ,
									 prefixs = "" #-};
    OCWsi.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						result = "SThreadBusy",
						prefixs = "" #-};
    OCWsi.sReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SReset_n", prefixs = "" #-};
    OCWsi.mReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReset_n", prefixs = "" #-}
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.Wsi_s nb nd ng nh ni);
									   
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.Wsi_s nb nd ng nh ni);
									 
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.Wsi_s nb nd ng nh ni);
									       
interface (OCWsi.Wsi_Em :: # -> # -> # -> # -> # -> *) nb nd ng nh ni {-# always_ready  #-} = {
    OCWsi.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 {-# arg_names = [], result = "MCmd", prefixs = "" #-};
    OCWsi.mReqLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReqLast", prefixs = "" #-};
    OCWsi.mBurstPrecise :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						  result = "MBurstPrecise",
						  prefixs = "" #-};
    OCWsi.mBurstLength :: ¶Prelude®¶.¶Bit®¶ nb {-# arg_names = [],
						   result = "MBurstLength",
						   prefixs = "" #-};
    OCWsi.mData :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [], result = "MData", prefixs = "" #-};
    OCWsi.mByteEn :: ¶Prelude®¶.¶Bit®¶ ng {-# arg_names = [], result = "MByteEn", prefixs = "" #-};
    OCWsi.mReqInfo :: ¶Prelude®¶.¶Bit®¶ nh {-# arg_names = [], result = "MReqInfo", prefixs = "" #-};
    OCWsi.mDataInfo :: ¶Prelude®¶.¶Bit®¶ ni {-# arg_names = [], result = "MDataInfo", prefixs = "" #-};
    OCWsi.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWsi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-};
    OCWsi.sReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SReset_n", prefixs = "" #-}
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.Wsi_Em nb nd ng nh ni);
									    
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.Wsi_Em nb nd ng nh ni);
									  
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.Wsi_Em nb nd ng nh ni);
										
interface (OCWsi.Wsi_Es :: # -> # -> # -> # -> # -> *) nb nd ng nh ni {-# always_ready  #-} = {
    OCWsi.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MCmd¡],
								  always_enabled ,
								  prefixs = "" #-};
    OCWsi.mReqLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReqLast", prefixs = "" #-};
    OCWsi.mBurstPrecise :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						    enable = "MBurstPrecise",
						    prefixs = "" #-};
    OCWsi.mBurstLength :: ¶Prelude®¶.¶Bit®¶ nb -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MBurstLength¡],
									   always_enabled ,
									   prefixs = "" #-};
    OCWsi.mData :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MData¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWsi.mByteEn :: ¶Prelude®¶.¶Bit®¶ ng -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MByteEn¡],
								      always_enabled ,
								      prefixs = "" #-};
    OCWsi.mReqInfo :: ¶Prelude®¶.¶Bit®¶ nh -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MReqInfo¡],
								       always_enabled ,
								       prefixs = "" #-};
    OCWsi.mDataInfo :: ¶Prelude®¶.¶Bit®¶ ni -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MDataInfo¡],
									always_enabled ,
									prefixs = "" #-};
    OCWsi.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						result = "SThreadBusy",
						prefixs = "" #-};
    OCWsi.sReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SReset_n", prefixs = "" #-};
    OCWsi.mReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReset_n", prefixs = "" #-}
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.Wsi_Es nb nd ng nh ni);
									    
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.Wsi_Es nb nd ng nh ni);
									  
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.Wsi_Es nb nd ng nh ni);
										
instance OCWsi ¶Connectable®¶.¶Connectable®¶ (OCWsi.Wsi_Em nb nd ng nh ni)
	       (OCWsi.Wsi_Es nb nd ng nh ni);
					    
instance OCWsi ¶Connectable®¶.¶Connectable®¶ (OCWsi.Wsi_m nb nd ng nh ni)
	       (OCWsi.Wsi_Es nb nd ng nh ni);
					    
instance OCWsi ¶Connectable®¶.¶Connectable®¶ (OCWsi.Wsi_Em nb nd ng nh ni)
	       (OCWsi.Wsi_s nb nd ng nh ni);
					   
instance OCWsi ¶Connectable®¶.¶Connectable®¶ (OCWsi.Wsi_m nb nd ng nh ni)
	       (OCWsi.Wsi_s nb nd ng nh ni);
					   
OCWsi.toWsiM :: OCWsi.Wsi_Em nb nd ng nh ni -> OCWsi.Wsi_m nb nd ng nh ni;
									 
OCWsi.toWsiEM :: OCWsi.Wsi_m nb nd ng nh ni -> OCWsi.Wsi_Em nb nd ng nh ni;
									  
OCWsi.toWsiS :: OCWsi.Wsi_Es nb nd ng nh ni -> OCWsi.Wsi_s nb nd ng nh ni;
									 
OCWsi.mkWsiStoES :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		    OCWsi.Wsi_s nb nd ng nh ni -> _m__ (OCWsi.Wsi_Es nb nd ng nh ni);
										    
OCWsi.isAborted :: OCWsi.WsiReq nb nd ng nh ni -> ¶Prelude®¶.¶Bool®¶;
								    
interface (OCWsi.WsiMasterIfc :: # -> # -> # -> # -> # -> *) nb nd ng nh ni = {
    OCWsi.reqPut :: ¶GetPut®¶.¶Put®¶ (OCWsi.WsiReq nb nd ng nh ni);
    OCWsi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWsi.status :: OCWipDefs.WipDataPortStatus {-# arg_names = [] #-};
    OCWsi.extStatus :: OCWipDefs.WipDataPortExtendedStatus {-# arg_names = [] #-};
    OCWsi.mas :: OCWsi.Wsi_m nb nd ng nh ni
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.WsiMasterIfc nb nd ng nh ni);
										  
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.WsiMasterIfc nb nd ng nh ni);
										
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.WsiMasterIfc nb nd ng nh ni);
										      
OCWsi.mkWsiMaster :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWsi.WsiMasterIfc nb nd ng nh ni);
												   
interface (OCWsi.WsiSlaveIfc :: # -> # -> # -> # -> # -> *) nb nd ng nh ni = {
    OCWsi.reqGet :: ¶GetPut®¶.¶Get®¶ (OCWsi.WsiReq nb nd ng nh ni);
    OCWsi.reqPeek :: OCWsi.WsiReq nb nd ng nh ni {-# arg_names = [] #-};
    OCWsi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWsi.status :: OCWipDefs.WipDataPortStatus {-# arg_names = [] #-};
    OCWsi.extStatus :: OCWipDefs.WipDataPortExtendedStatus {-# arg_names = [] #-};
    OCWsi.slv :: OCWsi.Wsi_s nb nd ng nh ni
};
 
instance OCWsi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWsi.WsiSlaveIfc nb nd ng nh ni);
										 
instance OCWsi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWsi.WsiSlaveIfc nb nd ng nh ni);
									       
instance OCWsi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWsi.WsiSlaveIfc nb nd ng nh ni);
										     
type (OCWsi.SRBsize :: #) = 3;
			     
OCWsi.mkWsiSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWsi.WsiSlaveIfc nb nd ng nh ni)
}
