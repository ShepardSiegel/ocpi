signature OCWci where {
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
		
struct (OCWci.WciAttributes :: *) = {
    OCWci.sizeOfConfigSpace :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWci.writableConfigProperties :: ¶Prelude®¶.¶Bool®¶;
    OCWci.readableConfigProperties :: ¶Prelude®¶.¶Bool®¶;
    OCWci.sub32bitConfigProperties :: ¶Prelude®¶.¶Bool®¶;
    OCWci.resetWhileSuspended :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.WciAttributes;
								  
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.WciAttributes;
								
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.WciAttributes;
								      
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.WciAttributes 36;
							
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.WciAttributes;
						   
instance OCWci ¶DefaultValue®¶.¶DefaultValue®¶ OCWci.WciAttributes;
								  
data (OCWci.WCI_CONTROL_OP :: *) =
    OCWci.Initialize () |
    OCWci.Start () |
    OCWci.Stop () |
    OCWci.Release () |
    OCWci.Test () |
    OCWci.BeforeQuery () |
    OCWci.AfterConfig () |
    OCWci.Rsvd7 ();
		  
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.WCI_CONTROL_OP;
								   
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.WCI_CONTROL_OP;
								 
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.WCI_CONTROL_OP;
								       
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.WCI_CONTROL_OP 3;
							
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.WCI_CONTROL_OP;
						    
data (OCWci.WCI_STATE :: *) =
    OCWci.Exists () |
    OCWci.Initialized () |
    OCWci.Operating () |
    OCWci.Suspended () |
    OCWci.Unusable () |
    OCWci.Rsvd5 () |
    OCWci.Rsvd6 () |
    OCWci.Rsvd7 ();
		  
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.WCI_STATE;
							      
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.WCI_STATE;
							    
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.WCI_STATE;
								  
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.WCI_STATE 3;
						   
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.WCI_STATE;
					       
data (OCWci.WCI_REQ :: *) = OCWci.None () | OCWci.CfgWt () | OCWci.CfgRd () | OCWci.CtlOp ();
											    
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.WCI_REQ;
							    
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.WCI_REQ;
							  
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.WCI_REQ;
								
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.WCI_REQ 2;
						 
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.WCI_REQ;
					     
data (OCWci.WCI_SPACE :: *) = OCWci.Admin () | OCWci.Control () | OCWci.Config ();
										 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.WCI_SPACE;
							      
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.WCI_SPACE;
							    
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.WCI_SPACE;
								  
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.WCI_SPACE 2;
						   
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.WCI_SPACE;
					       
struct (OCWci.ReqTBits :: *) = {
    OCWci.cfgWt :: ¶Prelude®¶.¶Bool®¶;
    OCWci.cfgRd :: ¶Prelude®¶.¶Bool®¶;
    OCWci.ctlOp :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.ReqTBits;
							     
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.ReqTBits;
							   
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.ReqTBits;
								 
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.ReqTBits 3;
						  
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.ReqTBits;
					      
instance OCWci ¶FShow®¶.¶FShow®¶ OCWci.WCI_CONTROL_OP;
						     
instance OCWci ¶FShow®¶.¶FShow®¶ OCWci.WCI_STATE;
						
struct (OCWci.WciReq :: # -> *) na = {
    OCWci.cmd :: OCWipDefs.OCP_CMD;
    OCWci.addrSpace :: ¶Prelude®¶.¶Bit®¶ 1;
    OCWci.byteEn :: ¶Prelude®¶.¶Bit®¶ 4;
    OCWci.addr :: ¶Prelude®¶.¶Bit®¶ na;
    OCWci.¡data¡ :: ¶Prelude®¶.¶Bit®¶ 32
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.WciReq na);
								
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.WciReq na);
							      
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.WciReq na);
								    
instance OCWci (¶Prelude®¶.¶Add®¶ 3 _v106 _v109,
		¶Prelude®¶.¶Add®¶ 1 _v103 _v106,
		¶Prelude®¶.¶Add®¶ 4 _v100 _v103,
		¶Prelude®¶.¶Add®¶ _v110 32 _v100) =>
	       ¶Prelude®¶.¶Bits®¶ (OCWci.WciReq _v110) _v109;
							    
instance OCWci ¶Prelude®¶.¶Eq®¶ (OCWci.WciReq na);
						 
struct (OCWci.WciResp :: *) = {
    OCWci.resp :: OCWipDefs.OCP_RESP;
    OCWci.¡data¡ :: ¶Prelude®¶.¶Bit®¶ 32
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.WciResp;
							    
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.WciResp;
							  
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.WciResp;
								
instance OCWci ¶Prelude®¶.¶Bits®¶ OCWci.WciResp 34;
						  
instance OCWci ¶Prelude®¶.¶Eq®¶ OCWci.WciResp;
					     
OCWci.wciIdleRequest :: OCWci.WciReq na;
				       
OCWci.wciIdleResponse :: OCWci.WciResp;
				      
OCWci.wciOKResponse :: OCWci.WciResp;
				    
OCWci.wciErrorResponse :: OCWci.WciResp;
				       
OCWci.wciTimeoutResponse :: OCWci.WciResp;
					 
OCWci.wciResetResponse :: OCWci.WciResp;
				       
interface (OCWci.Wci_m :: # -> *) na {-# always_ready  #-} = {
    OCWci.req :: OCWci.WciReq na {-# arg_names = [] #-};
    OCWci.put :: OCWci.WciResp -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [resp],
							   always_enabled ,
							   prefixs = "" #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [sf],
								   enable = "SFlag",
								   prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "MFlag", prefixs = "" #-};
    OCWci.mReset_n :: ¶Prelude®¶.¶Reset®¶
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_m na);
							       
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_m na);
							     
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_m na);
								   
interface (OCWci.Wci_s :: # -> *) na {-# always_ready  #-} = {
    OCWci.putreq :: OCWci.WciReq na -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [req],
								always_enabled ,
								prefixs = "" #-};
    OCWci.resp :: OCWci.WciResp {-# arg_names = [] #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						result = "SThreadBusy",
						prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SFlag", prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MFlag¡],
								   always_enabled ,
								   prefixs = "" #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_s na);
							       
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_s na);
							     
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_s na);
								   
interface (OCWci.Wci_Em :: # -> *) na {-# always_ready  #-} = {
    OCWci.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 {-# arg_names = [], result = "MCmd", prefixs = "" #-};
    OCWci.mAddrSpace :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "MAddrSpace", prefixs = "" #-};
    OCWci.mByteEn :: ¶Prelude®¶.¶Bit®¶ 4 {-# arg_names = [], result = "MByteEn", prefixs = "" #-};
    OCWci.mAddr :: ¶Prelude®¶.¶Bit®¶ na {-# arg_names = [], result = "MAddr", prefixs = "" #-};
    OCWci.mData :: ¶Prelude®¶.¶Bit®¶ 32 {-# arg_names = [], result = "MData", prefixs = "" #-};
    OCWci.sResp :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SResp¡],
								   always_enabled ,
								   prefixs = "" #-};
    OCWci.sData :: ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SData¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SFlag¡],
								   always_enabled ,
								   prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "MFlag", prefixs = "" #-};
    OCWci.mReset_n :: ¶Prelude®¶.¶Reset®¶
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_Em na);
								
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_Em na);
							      
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_Em na);
								    
interface (OCWci.Wci_Es :: # -> *) na {-# always_ready  #-} = {
    OCWci.mCmd :: ¶Prelude®¶.¶Bit®¶ 3 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MCmd¡],
								  always_enabled ,
								  prefixs = "" #-};
    OCWci.mAddrSpace :: ¶Prelude®¶.¶Bit®¶ 1 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MAddrSpace¡],
									always_enabled ,
									prefixs = "" #-};
    OCWci.mByteEn :: ¶Prelude®¶.¶Bit®¶ 4 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MByteEn¡],
								     always_enabled ,
								     prefixs = "" #-};
    OCWci.mAddr :: ¶Prelude®¶.¶Bit®¶ na -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MAddr¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWci.mData :: ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MData¡],
								    always_enabled ,
								    prefixs = "" #-};
    OCWci.sResp :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SResp", prefixs = "" #-};
    OCWci.sData :: ¶Prelude®¶.¶Bit®¶ 32 {-# arg_names = [], result = "SData", prefixs = "" #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [],
						result = "SThreadBusy",
						prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SFlag", prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MFlag¡],
								   always_enabled ,
								   prefixs = "" #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_Es na);
								
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_Es na);
							      
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_Es na);
								    
instance OCWci ¶Connectable®¶.¶Connectable®¶ (OCWci.Wci_Em na) (OCWci.Wci_Es na);
										
instance OCWci ¶Connectable®¶.¶Connectable®¶ (OCWci.Wci_m na) (OCWci.Wci_Es na);
									       
instance OCWci ¶Connectable®¶.¶Connectable®¶ (OCWci.Wci_Em na) (OCWci.Wci_s na);
									       
instance OCWci ¶Connectable®¶.¶Connectable®¶ (OCWci.Wci_m na) (OCWci.Wci_s na);
									      
OCWci.toWciM :: OCWci.Wci_Em na -> OCWci.Wci_m na;
						 
OCWci.mkWciMtoEm :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => OCWci.Wci_m na -> _m__ (OCWci.Wci_Em na);
												  
OCWci.toWciS :: OCWci.Wci_Es na -> OCWci.Wci_s na;
						 
OCWci.mkWciStoES :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => OCWci.Wci_s na -> _m__ (OCWci.Wci_Es na);
												  
interface (OCWci.Wci_Xm :: # -> *) na = {
    OCWci.masterReq :: OCWci.Wci_MasterReq_Ifc na {-# prefixs = "" #-};
    OCWci.masterResp :: OCWci.Wci_MasterResp_Ifc {-# prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SFlag¡],
								   always_enabled ,
								   prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "MFlag", prefixs = "" #-};
    OCWci.mReset_n :: ¶Prelude®¶.¶Reset®¶
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_Xm na);
								
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_Xm na);
							      
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_Xm na);
								    
interface (OCWci.Wci_MasterReq_Ifc :: # -> *) na {-# always_ready  #-} = {
    OCWci.mCmd :: OCWipDefs.OCP_CMD {-# arg_names = [], result = "MCmd" #-};
    OCWci.mAddrSpace :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "MAddrSpace" #-};
    OCWci.mByteEn :: ¶Prelude®¶.¶Bit®¶ 4 {-# arg_names = [], result = "MByteEn" #-};
    OCWci.mAddr :: ¶Prelude®¶.¶Bit®¶ na {-# arg_names = [], result = "MAddr" #-};
    OCWci.mData :: ¶Prelude®¶.¶Bit®¶ 32 {-# arg_names = [], result = "MData" #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SThreadBusy" #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_MasterReq_Ifc na);
									   
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_MasterReq_Ifc na);
									 
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_MasterReq_Ifc na);
									       
interface (OCWci.Wci_MasterResp_Ifc :: *) {-# always_ready  #-} = {
    OCWci.putResponse :: OCWipDefs.OCP_RESP ->
			 ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SResp¡, ¡SData¡],
									  prefixs = "",
									  always_enabled  #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.Wci_MasterResp_Ifc;
								       
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.Wci_MasterResp_Ifc;
								     
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.Wci_MasterResp_Ifc;
									   
interface (OCWci.Wci_Xs :: # -> *) na = {
    OCWci.slaveReq :: OCWci.Wci_SlaveReq_Ifc na {-# prefixs = "" #-};
    OCWci.slaveResp :: OCWci.Wci_SlaveResp_Ifc {-# prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SFlag", prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MFlag¡],
								   always_enabled ,
								   prefixs = "" #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_Xs na);
								
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_Xs na);
							      
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_Xs na);
								    
interface (OCWci.Wci_SlaveReq_Ifc :: # -> *) na {-# always_ready  #-} = {
    OCWci.putRequest :: OCWipDefs.OCP_CMD ->
			¶Prelude®¶.¶Bit®¶ 1 ->
			¶Prelude®¶.¶Bit®¶ 4 ->
			¶Prelude®¶.¶Bit®¶ na -> ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MCmd¡,
													      ¡MAddrSpace¡,
													      ¡MByteEn¡,
													      ¡MAddr¡,
													      ¡MData¡],
												 prefixs = "",
												 always_enabled  #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SThreadBusy" #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.Wci_SlaveReq_Ifc na);
									  
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.Wci_SlaveReq_Ifc na);
									
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.Wci_SlaveReq_Ifc na);
									      
interface (OCWci.Wci_SlaveResp_Ifc :: *) {-# always_ready  #-} = {
    OCWci.sResp :: OCWipDefs.OCP_RESP {-# arg_names = [], result = "SResp" #-};
    OCWci.sData :: ¶Prelude®¶.¶Bit®¶ 32 {-# arg_names = [], result = "SData" #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWci.Wci_SlaveResp_Ifc;
								      
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWci.Wci_SlaveResp_Ifc;
								    
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWci.Wci_SlaveResp_Ifc;
									  
instance OCWci ¶Connectable®¶.¶Connectable®¶ (OCWci.Wci_Xm na) (OCWci.Wci_Xs na);
										
interface (OCWci.WciMasterIfc :: # -> *) na = {
    OCWci.req :: OCWci.WCI_SPACE ->
		 ¶Prelude®¶.¶Bool®¶ ->
		 ¶Prelude®¶.¶Bit®¶ na ->
		 ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Bit®¶ 4 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [sp,
												      write,
												      addr,
												      wdata,
												      be] #-};
    OCWci.resp :: ¶Prelude®¶.¶ActionValue®¶ OCWci.WciResp {-# arg_names = [] #-};
    OCWci.attn :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.present :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.mas :: OCWci.Wci_m na
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.WciMasterIfc na);
								      
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.WciMasterIfc na);
								    
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.WciMasterIfc na);
									  
OCWci.mkWciMaster :: (¶Prelude®¶.¶Add®¶ b_ na 32,
		      ¶Prelude®¶.¶Add®¶ a_ 5 na,
		      ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		     _m__ (OCWci.WciMasterIfc na);
						 
OCWci.mkWciMasterNull :: (¶Prelude®¶.¶Add®¶ a_ 5 na, ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			 _m__ (OCWci.WciMasterIfc na);
						     
interface (OCWci.WciXMasterIfc :: # -> *) na = {
    OCWci.req :: OCWci.WCI_SPACE ->
		 ¶Prelude®¶.¶Bool®¶ ->
		 ¶Prelude®¶.¶Bit®¶ na ->
		 ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Bit®¶ 4 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [sp,
												      write,
												      addr,
												      wdata,
												      be] #-};
    OCWci.resp :: ¶Prelude®¶.¶ActionValue®¶ OCWci.WciResp {-# arg_names = [] #-};
    OCWci.attn :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.present :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.mas :: OCWci.Wci_Xm na
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.WciXMasterIfc na);
								       
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.WciXMasterIfc na);
								     
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.WciXMasterIfc na);
									   
OCWci.mkWciXMaster :: (¶Prelude®¶.¶Add®¶ b_ na 32,
		       ¶Prelude®¶.¶Add®¶ a_ 5 na,
		       ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		      _m__ (OCWci.WciXMasterIfc na);
						   
interface (OCWci.WciSlaveIfc :: # -> *) na = {
    OCWci.slv :: OCWci.Wci_s na;
    OCWci.reqGet :: ¶GetPut®¶.¶Get®¶ (OCWci.WciReq na);
    OCWci.respPut :: ¶GetPut®¶.¶Put®¶ OCWci.WciResp;
    OCWci.reqPeek :: OCWci.WciReq na {-# arg_names = [] #-};
    OCWci.configWrite :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.configRead :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.controlOp :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.wrkReset :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.drvSFlag :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWci.ctlState :: OCWci.WCI_STATE {-# arg_names = [] #-};
    OCWci.isOperating :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.ctlOp :: OCWci.WCI_CONTROL_OP {-# arg_names = [] #-};
    OCWci.ctlAck :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.WciSlaveIfc na);
								     
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.WciSlaveIfc na);
								   
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.WciSlaveIfc na);
									 
OCWci.mkWciSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWci.WciSlaveIfc na);
										     
interface (OCWci.WciSlaveNullIfc :: # -> *) na = {
    OCWci.slv :: OCWci.Wci_s na
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.WciSlaveNullIfc na);
									 
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.WciSlaveNullIfc na);
								       
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.WciSlaveNullIfc na);
									     
OCWci.mkWciSlaveNull :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWci.WciSlaveNullIfc na);
											     
OCWci.mkWciSlaveENull :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWci.Wci_Es na);
										     
interface (OCWci.WciXSlaveIfc :: # -> *) na = {
    OCWci.slv :: OCWci.Wci_Xs na;
    OCWci.reqGet :: ¶GetPut®¶.¶Get®¶ (OCWci.WciReq na);
    OCWci.respPut :: ¶GetPut®¶.¶Put®¶ OCWci.WciResp;
    OCWci.reqPeek :: OCWci.WciReq na {-# arg_names = [] #-};
    OCWci.configWrite :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.configRead :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.controlOp :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.wrkReset :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.drvSFlag :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWci.ctlState :: OCWci.WCI_STATE {-# arg_names = [] #-};
    OCWci.isOperating :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [] #-};
    OCWci.ctlOp :: OCWci.WCI_CONTROL_OP {-# arg_names = [] #-};
    OCWci.ctlAck :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-}
};
 
instance OCWci ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWci.WciXSlaveIfc na);
								      
instance OCWci ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWci.WciXSlaveIfc na);
								    
instance OCWci ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWci.WciXSlaveIfc na);
									  
OCWci.mkWciXSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWci.WciXSlaveIfc na)
}
