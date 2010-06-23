signature OCWmemi where {
import ¶ConfigReg®¶;
		   
import ¶Counter®¶;
		 
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
		
import ¶BRAMCore®¶;
		  
import ¶Connectable®¶;
		     
import ¶DefaultValue®¶;
		      
import ¶FShow®¶;
	       
import ¶GetPut®¶;
		
import ¶ClientServer®¶;
		      
import ¶BRAM®¶;
	      
import ¶FIFOLevel®¶;
		   
import OCWipDefs;
		
import ¶SpecialFIFOs®¶;
		      
import ¶TieOff®¶;
		
struct (OCWmemi.WmemiAttributes :: *) = {
    OCWmemi.dataWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmemi.byteWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmemi.impreciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.preciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.memoryWords :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmemi.maxBurstLength :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmemi.writeDataFlowControl :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.readDataFlowControl :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWmemi.WmemiAttributes;
									
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWmemi.WmemiAttributes;
								      
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWmemi.WmemiAttributes;
									    
instance OCWmemi ¶Prelude®¶.¶Bits®¶ OCWmemi.WmemiAttributes 132;
							       
instance OCWmemi ¶Prelude®¶.¶Eq®¶ OCWmemi.WmemiAttributes;
							 
instance OCWmemi ¶DefaultValue®¶.¶DefaultValue®¶ OCWmemi.WmemiAttributes;
									
class (OCWmemi.DWordWidth :: # -> *) ndw where {
};
 
instance OCWmemi OCWmemi.DWordWidth 1;
				     
instance OCWmemi OCWmemi.DWordWidth 2;
				     
instance OCWmemi OCWmemi.DWordWidth 4;
				     
instance OCWmemi OCWmemi.DWordWidth 8;
				     
type (OCWmemi.WmemiM4B :: *) = OCWmemi.Wmemi_m 36 12 32 4;
							 
type (OCWmemi.WmemiS4B :: *) = OCWmemi.Wmemi_s 36 12 32 4;
							 
type (OCWmemi.WmemiM8B :: *) = OCWmemi.Wmemi_m 36 12 64 8;
							 
type (OCWmemi.WmemiS8B :: *) = OCWmemi.Wmemi_s 36 12 64 8;
							 
type (OCWmemi.WmemiM16B :: *) = OCWmemi.Wmemi_m 36 12 128 16;
							    
type (OCWmemi.WmemiS16B :: *) = OCWmemi.Wmemi_s 36 12 128 16;
							    
type (OCWmemi.WmemiM32B :: *) = OCWmemi.Wmemi_m 36 12 256 32;
							    
type (OCWmemi.WmemiS32B :: *) = OCWmemi.Wmemi_s 36 12 256 32;
							    
type (OCWmemi.WmemiEM4B :: *) = OCWmemi.Wmemi_Em 36 12 32 4;
							   
type (OCWmemi.WmemiES4B :: *) = OCWmemi.Wmemi_Es 36 12 32 4;
							   
type (OCWmemi.WmemiEM8B :: *) = OCWmemi.Wmemi_Em 36 12 64 8;
							   
type (OCWmemi.WmemiES8B :: *) = OCWmemi.Wmemi_Es 36 12 64 8;
							   
type (OCWmemi.WmemiEM16B :: *) = OCWmemi.Wmemi_Em 36 12 128 16;
							      
type (OCWmemi.WmemiES16B :: *) = OCWmemi.Wmemi_Es 36 12 128 16;
							      
type (OCWmemi.WmemiEM32B :: *) = OCWmemi.Wmemi_Em 36 12 256 32;
							      
type (OCWmemi.WmemiES32B :: *) = OCWmemi.Wmemi_Es 36 12 256 32;
							      
struct (OCWmemi.WmemiReq :: # -> # -> *) na nb = {
    OCWmemi.cmd :: OCWipDefs.OCP_CMD;
    OCWmemi.reqLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.addr :: ¶Prelude®¶.¶Bit®¶ na;
    OCWmemi.burstLength :: ¶Prelude®¶.¶Bit®¶ nb
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.WmemiReq na nb);
									 
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.WmemiReq na nb);
								       
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.WmemiReq na nb);
									     
instance OCWmemi (¶Prelude®¶.¶Add®¶ 3 _v103 _v106,
		  ¶Prelude®¶.¶Add®¶ 1 _v100 _v103,
		  ¶Prelude®¶.¶Add®¶ _v107 _v110 _v100) =>
		 ¶Prelude®¶.¶Bits®¶ (OCWmemi.WmemiReq _v107 _v110) _v106;
									
instance OCWmemi ¶Prelude®¶.¶Eq®¶ (OCWmemi.WmemiReq na nb);
							  
struct (OCWmemi.WmemiDh :: # -> # -> *) nd ne = {
    OCWmemi.dataValid :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.dataLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd;
    OCWmemi.dataByteEn :: ¶Prelude®¶.¶Bit®¶ ne
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.WmemiDh nd ne);
									
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.WmemiDh nd ne);
								      
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.WmemiDh nd ne);
									    
instance OCWmemi (¶Prelude®¶.¶Add®¶ 1 _v100 _v103,
		  ¶Prelude®¶.¶Add®¶ _v107 _v110 _v100,
		  ¶Prelude®¶.¶Add®¶ 1 _v103 _v106) =>
		 ¶Prelude®¶.¶Bits®¶ (OCWmemi.WmemiDh _v107 _v110) _v106;
								       
instance OCWmemi ¶Prelude®¶.¶Eq®¶ (OCWmemi.WmemiDh nd ne);
							 
struct (OCWmemi.WmemiResp :: # -> *) nd = {
    OCWmemi.resp :: OCWipDefs.OCP_RESP;
    OCWmemi.respLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.WmemiResp nd);
								       
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.WmemiResp nd);
								     
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.WmemiResp nd);
									   
instance OCWmemi (¶Prelude®¶.¶Add®¶ 2 _v100 _v103, ¶Prelude®¶.¶Add®¶ 1 _v107 _v100) =>
		 ¶Prelude®¶.¶Bits®¶ (OCWmemi.WmemiResp _v107) _v103;
								   
instance OCWmemi ¶Prelude®¶.¶Eq®¶ (OCWmemi.WmemiResp nd);
							
OCWmemi.wmemiIdleRequest :: OCWmemi.WmemiReq na nb;
						  
OCWmemi.wmemiIdleDh :: OCWmemi.WmemiDh nd ne;
					    
OCWmemi.wmemiIdleResp :: OCWmemi.WmemiResp nd;
					     
interface (OCWmemi.Wmemi_m :: # -> # -> # -> # -> *) na nb nd ne {-# always_ready  #-} = {
    OCWmemi.getReq :: OCWmemi.WmemiReq na nb {-# arg_names = [], result = "req" #-};
    OCWmemi.getDh :: OCWmemi.WmemiDh nd ne {-# arg_names = [], result = "dh" #-};
    OCWmemi.putResp :: OCWmemi.WmemiResp nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [resp],
									prefixs = "",
									always_enabled  #-};
    OCWmemi.sCmdAccept :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						   enable = "SCmdAccept",
						   prefixs = "" #-};
    OCWmemi.sDataAccept :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						    enable = "SDataAccept",
						    prefixs = "" #-};
    OCWmemi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-}
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.Wmemi_m na nb nd ne);
									      
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.Wmemi_m na nb nd ne);
									    
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.Wmemi_m na nb nd ne);
										  
interface (OCWmemi.Wmemi_s :: # -> # -> # -> # -> *) na nb nd ne {-# always_ready  #-} = {
    OCWmemi.putReq :: OCWmemi.WmemiReq na nb -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [req],
									 prefixs = "",
									 always_enabled  #-};
    OCWmemi.putDh :: OCWmemi.WmemiDh nd ne -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [dh],
								       prefixs = "",
								       always_enabled  #-};
    OCWmemi.getResp :: OCWmemi.WmemiResp nd {-# arg_names = [], result = "resp" #-};
    OCWmemi.sCmdAccept :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						 result = "SCmdAccept",
						 prefixs = "" #-};
    OCWmemi.sDataAccept :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						  result = "SDataAccept",
						  prefixs = "" #-};
    OCWmemi.mReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReset_n", prefixs = "" #-}
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.Wmemi_s na nb nd ne);
									      
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.Wmemi_s na nb nd ne);
									    
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.Wmemi_s na nb nd ne);
										  
interface (OCWmemi.Wmemi_Em :: # -> # -> # -> # -> *) na nb nd ne {-# always_ready  #-} = {
    OCWmemi.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 {-# arg_names = [], result = "MCmd", prefixs = "" #-};
    OCWmemi.mReqLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReqLast", prefixs = "" #-};
    OCWmemi.mAddr :: ¶Prelude®¶.¶Bit®¶ na {-# arg_names = [], result = "MAddr", prefixs = "" #-};
    OCWmemi.mBurstLength :: ¶Prelude®¶.¶Bit®¶ nb {-# arg_names = [],
						     result = "MBurstLength",
						     prefixs = "" #-};
    OCWmemi.mDataValid :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						 result = "MDataValid",
						 prefixs = "" #-};
    OCWmemi.mDataLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MDataLast", prefixs = "" #-};
    OCWmemi.mData :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [], result = "MData", prefixs = "" #-};
    OCWmemi.mDataByteEn :: ¶Prelude®¶.¶Bit®¶ ne {-# arg_names = [],
						    result = "MDataByteEn",
						    prefixs = "" #-};
    OCWmemi.sResp :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SResp¡],
								     always_enabled ,
								     prefixs = "" #-};
    OCWmemi.sRespLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SRespLast",
						  prefixs = "" #-};
    OCWmemi.sData :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SData¡],
								      always_enabled ,
								      prefixs = "" #-};
    OCWmemi.sCmdAccept :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						   enable = "SCmdAccept",
						   prefixs = "" #-};
    OCWmemi.sDataAccept :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						    enable = "SDataAccept",
						    prefixs = "" #-};
    OCWmemi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-}
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.Wmemi_Em na nb nd ne);
									       
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.Wmemi_Em na nb nd ne);
									     
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.Wmemi_Em na nb nd ne);
										   
interface (OCWmemi.Wmemi_Es :: # -> # -> # -> # -> *) na nb nd ne {-# always_ready  #-} = {
    OCWmemi.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MCmd¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWmemi.mReqLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReqLast", prefixs = "" #-};
    OCWmemi.mAddr :: ¶Prelude®¶.¶Bit®¶ na -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MAddr¡],
								      always_enabled ,
								      prefixs = "" #-};
    OCWmemi.mBurstLength :: ¶Prelude®¶.¶Bit®¶ nb ->
			    ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MBurstLength¡], always_enabled , prefixs = "" #-};
    OCWmemi.mDataValid :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						   enable = "MDataValid",
						   prefixs = "" #-};
    OCWmemi.mDataLast :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "MDataLast",
						  prefixs = "" #-};
    OCWmemi.mData :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MData¡],
								      always_enabled ,
								      prefixs = "" #-};
    OCWmemi.mDataByteEn :: ¶Prelude®¶.¶Bit®¶ ne -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MDataByteEn¡],
									    always_enabled ,
									    prefixs = "" #-};
    OCWmemi.sResp :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SResp", prefixs = "" #-};
    OCWmemi.sRespLast :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SRespLast", prefixs = "" #-};
    OCWmemi.sData :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [], result = "SData", prefixs = "" #-};
    OCWmemi.sCmdAccept :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						 result = "SCmdAccept",
						 prefixs = "" #-};
    OCWmemi.sDataAccept :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						  result = "SDataAccept",
						  prefixs = "" #-};
    OCWmemi.mReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "MReset_n", prefixs = "" #-}
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.Wmemi_Es na nb nd ne);
									       
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.Wmemi_Es na nb nd ne);
									     
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.Wmemi_Es na nb nd ne);
										   
instance OCWmemi ¶Connectable®¶.¶Connectable®¶ (OCWmemi.Wmemi_Em na nb nd ne)
		 (OCWmemi.Wmemi_Es na nb nd ne);
					       
instance OCWmemi ¶Connectable®¶.¶Connectable®¶ (OCWmemi.Wmemi_m na nb nd ne)
		 (OCWmemi.Wmemi_Es na nb nd ne);
					       
instance OCWmemi ¶Connectable®¶.¶Connectable®¶ (OCWmemi.Wmemi_Em na nb nd ne)
		 (OCWmemi.Wmemi_s na nb nd ne);
					      
instance OCWmemi ¶Connectable®¶.¶Connectable®¶ (OCWmemi.Wmemi_m na nb nd ne)
		 (OCWmemi.Wmemi_s na nb nd ne);
					      
OCWmemi.toWmemiM :: OCWmemi.Wmemi_Em na nb nd ne -> OCWmemi.Wmemi_m na nb nd ne;
									       
OCWmemi.mkWmemiMtoEm :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			OCWmemi.Wmemi_m na nb nd ne -> _m__ (OCWmemi.Wmemi_Em na nb nd ne);
											  
OCWmemi.toWmemiS :: OCWmemi.Wmemi_Es na nb nd ne -> OCWmemi.Wmemi_s na nb nd ne;
									       
OCWmemi.mkWmemiStoES :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			OCWmemi.Wmemi_s na nb nd ne -> _m__ (OCWmemi.Wmemi_Es na nb nd ne);
											  
interface (OCWmemi.WmemiMasterIfc :: # -> # -> # -> # -> *) na nb nd ne = {
    OCWmemi.req :: ¶Prelude®¶.¶Bool®¶ ->
		   ¶Prelude®¶.¶Bit®¶ na -> ¶Prelude®¶.¶Bit®¶ nb -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [write,
													 addr,
													 bl] #-};
    OCWmemi.dh :: ¶Prelude®¶.¶Bit®¶ nd ->
		  ¶Prelude®¶.¶Bit®¶ ne -> ¶Prelude®¶.¶Bool®¶ -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [wdata,
												      be,
												      dataLast] #-};
    OCWmemi.resp :: ¶Prelude®¶.¶ActionValue®¶ (OCWmemi.WmemiResp nd) {-# arg_names = [] #-};
    OCWmemi.anyBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWmemi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWmemi.status :: OCWipDefs.WipDataPortStatus {-# arg_names = [] #-};
    OCWmemi.mas :: OCWmemi.Wmemi_m na nb nd ne
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.WmemiMasterIfc na nb nd ne);
										     
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.WmemiMasterIfc na nb nd ne);
										   
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.WmemiMasterIfc na nb nd ne);
											 
OCWmemi.mkWmemiMaster :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			 _m__ (OCWmemi.WmemiMasterIfc na nb nd ne);
								  
interface (OCWmemi.WmemiSlaveIfc :: # -> # -> # -> # -> *) na nb nd ne = {
    OCWmemi.req :: ¶Prelude®¶.¶ActionValue®¶ (OCWmemi.WmemiReq na nb) {-# arg_names = [] #-};
    OCWmemi.dh :: ¶Prelude®¶.¶ActionValue®¶ (OCWmemi.WmemiDh nd ne) {-# arg_names = [] #-};
    OCWmemi.respd :: ¶Prelude®¶.¶Bit®¶ nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [rdata] #-};
    OCWmemi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWmemi.status :: OCWipDefs.WipDataPortStatus {-# arg_names = [] #-};
    OCWmemi.slv :: OCWmemi.Wmemi_s na nb nd ne
};
 
instance OCWmemi ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWmemi.WmemiSlaveIfc na nb nd ne);
										    
instance OCWmemi ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWmemi.WmemiSlaveIfc na nb nd ne);
										  
instance OCWmemi ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWmemi.WmemiSlaveIfc na nb nd ne);
											
OCWmemi.mkWmemiSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			_m__ (OCWmemi.WmemiSlaveIfc na nb nd ne)
}
