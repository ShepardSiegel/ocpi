signature OCWti where {
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
		
struct (OCWti.WtiAttributes :: *) = {
    OCWti.secondsWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWti.fractionWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWti.allowUnavailable :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWti ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWti.WtiAttributes;
								  
instance OCWti ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWti.WtiAttributes;
								
instance OCWti ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWti.WtiAttributes;
								      
instance OCWti ¶Prelude®¶.¶Bits®¶ OCWti.WtiAttributes 65;
							
instance OCWti ¶Prelude®¶.¶Eq®¶ OCWti.WtiAttributes;
						   
instance OCWti ¶DefaultValue®¶.¶DefaultValue®¶ OCWti.WtiAttributes;
								  
struct (OCWti.WtiReq :: # -> *) nd = {
    OCWti.cmd :: OCWipDefs.OCP_CMD;
    OCWti.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd
};
 
instance OCWti ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWti.WtiReq nd);
								
instance OCWti ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWti.WtiReq nd);
							      
instance OCWti ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWti.WtiReq nd);
								    
instance OCWti (¶Prelude®¶.¶Add®¶ 3 _v104 _v100) => ¶Prelude®¶.¶Bits®¶ (OCWti.WtiReq _v104) _v100;
												 
instance OCWti ¶Prelude®¶.¶Eq®¶ (OCWti.WtiReq nd);
						 
OCWti.wtiIdleRequest :: OCWti.WtiReq nd;
				       
interface (OCWti.Wti_m :: # -> *) nd {-# always_ready  #-} = {
    OCWti.get :: OCWti.WtiReq nd {-# arg_names = [], result = "req" #-};
    OCWti.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-}
};
 
instance OCWti ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWti.Wti_m nd);
							       
instance OCWti ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWti.Wti_m nd);
							     
instance OCWti ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWti.Wti_m nd);
								   
interface (OCWti.Wti_s :: # -> *) nd {-# always_ready  #-} = {
    OCWti.put :: OCWti.WtiReq nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [req],
							     always_enabled ,
							     prefixs = "" #-};
    OCWti.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SThreadBusy", prefixs = "" #-}
};
 
instance OCWti ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWti.Wti_s nd);
							       
instance OCWti ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWti.Wti_s nd);
							     
instance OCWti ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWti.Wti_s nd);
								   
instance OCWti ¶Connectable®¶.¶Connectable®¶ (OCWti.Wti_m nd) (OCWti.Wti_s nd);
									      
interface (OCWti.WtiMasterIfc :: # -> *) nd = {
    OCWti.reqPut :: ¶GetPut®¶.¶Put®¶ (OCWti.WtiReq nd);
    OCWti.mas :: OCWti.Wti_m nd
};
 
instance OCWti ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWti.WtiMasterIfc nd);
								      
instance OCWti ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWti.WtiMasterIfc nd);
								    
instance OCWti ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWti.WtiMasterIfc nd);
									  
OCWti.mkWtiMaster :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWti.WtiMasterIfc nd);
										       
interface (OCWti.WtiSlaveIfc :: # -> *) nd = {
    OCWti.slv :: OCWti.Wti_s nd;
    OCWti.reqGet :: ¶GetPut®¶.¶Get®¶ (OCWti.WtiReq nd);
    OCWti.now :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [] #-}
};
 
instance OCWti ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCWti.WtiSlaveIfc nd);
								     
instance OCWti ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCWti.WtiSlaveIfc nd);
								   
instance OCWti ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCWti.WtiSlaveIfc nd);
									 
OCWti.mkWtiSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWti.WtiSlaveIfc nd)
}
