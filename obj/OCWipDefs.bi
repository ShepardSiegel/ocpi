signature OCWipDefs where {
import ¶FIFOF_®¶;
		
import ¶FIFOF®¶;
	       
import ¶FIFO®¶;
	      
import ¶Inout®¶;
	       
import ¶List®¶;
	      
import ¶Clocks®¶;
		
import ¶ListN®¶;
	       
import ¶PrimArray®¶;
		   
import ¶Vector®¶;
		
import ¶Connectable®¶;
		     
import ¶GetPut®¶;
		
data (OCWipDefs.OCP_CMD :: *) =
    OCWipDefs.IDLE () |
    OCWipDefs.WR () |
    OCWipDefs.RD () |
    OCWipDefs.RDEX () |
    OCWipDefs.RDL () |
    OCWipDefs.WRNP () |
    OCWipDefs.WRC () |
    OCWipDefs.BCST ();
		     
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.OCP_CMD;
								    
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.OCP_CMD;
								  
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.OCP_CMD;
									
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.OCP_CMD 3;
							 
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.OCP_CMD;
						     
data (OCWipDefs.OCP_RESP :: *) =
    OCWipDefs.NULL () | OCWipDefs.DVA () | OCWipDefs.FAIL () | OCWipDefs.ERR ();
									       
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.OCP_RESP;
								     
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.OCP_RESP;
								   
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.OCP_RESP;
									 
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.OCP_RESP 2;
							  
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.OCP_RESP;
						      
data (OCWipDefs.OCP_BURST :: *) = OCWipDefs.None () | OCWipDefs.Precise () | OCWipDefs.Imprecise ();
												   
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.OCP_BURST;
								      
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.OCP_BURST;
								    
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.OCP_BURST;
									  
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.OCP_BURST 2;
							   
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.OCP_BURST;
						       
struct (OCWipDefs.MesgMeta :: *) = {
    OCWipDefs.length :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.opcode :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.nowMS :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.nowLS :: ¶Prelude®¶.¶Bit®¶ 32
};
 
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.MesgMeta;
								     
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.MesgMeta;
								   
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.MesgMeta;
									 
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.MesgMeta 128;
							    
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.MesgMeta;
						      
struct (OCWipDefs.MesgMetaDW :: *) = {
    OCWipDefs.tag :: ¶Prelude®¶.¶Bit®¶ 8;
    OCWipDefs.opcode :: ¶Prelude®¶.¶Bit®¶ 8;
    OCWipDefs.length :: ¶Prelude®¶.¶Bit®¶ 16
};
 
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.MesgMetaDW;
								       
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.MesgMetaDW;
								     
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.MesgMetaDW;
									   
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.MesgMetaDW 32;
							     
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.MesgMetaDW;
							
struct (OCWipDefs.MesgMetaFlag :: *) = {
    OCWipDefs.opcode :: ¶Prelude®¶.¶Bit®¶ 8;
    OCWipDefs.length :: ¶Prelude®¶.¶Bit®¶ 24
};
 
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.MesgMetaFlag;
									 
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.MesgMetaFlag;
								       
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.MesgMetaFlag;
									     
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.MesgMetaFlag 32;
							       
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.MesgMetaFlag;
							  
data (OCWipDefs.SampOpcode :: *) =
    OCWipDefs.Sample () | OCWipDefs.Sync () | OCWipDefs.Timestamp () | OCWipDefs.Rsvd ();
											
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.SampOpcode;
								       
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.SampOpcode;
								     
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.SampOpcode;
									   
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.SampOpcode 2;
							    
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.SampOpcode;
							
struct (OCWipDefs.SampMesg :: *) = {
    OCWipDefs.opcode :: OCWipDefs.SampOpcode;
    OCWipDefs.last :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.be :: ¶Prelude®¶.¶Bit®¶ 4;
    OCWipDefs.¡data¡ :: ¶Prelude®¶.¶Bit®¶ 32
};
 
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.SampMesg;
								     
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.SampMesg;
								   
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.SampMesg;
									 
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.SampMesg 39;
							   
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.SampMesg;
						      
struct (OCWipDefs.WipDataPortStatus :: *) = {
    OCWipDefs.localReset :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.partnerReset :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.notOperatonal :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.observedError :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.inProgress :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.sThreadBusy :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.sDataThreadBusy :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.observedTraffic :: ¶Prelude®¶.¶Bool®¶
};
 
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.WipDataPortStatus;
									      
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.WipDataPortStatus;
									    
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.WipDataPortStatus;
										  
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.WipDataPortStatus 8;
								   
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.WipDataPortStatus;
							       
struct (OCWipDefs.WipDataPortExtendedStatus :: *) = {
    OCWipDefs.pMesgCount :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.iMesgCount :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.tBusyCount :: ¶Prelude®¶.¶Bit®¶ 32
};
 
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUndefined®¶ OCWipDefs.WipDataPortExtendedStatus;
										      
instance OCWipDefs ¶Prelude®¶.¶PrimDeepSeqCond®¶ OCWipDefs.WipDataPortExtendedStatus;
										    
instance OCWipDefs ¶Prelude®¶.¶PrimMakeUninitialized®¶ OCWipDefs.WipDataPortExtendedStatus;
											  
instance OCWipDefs ¶Prelude®¶.¶Bits®¶ OCWipDefs.WipDataPortExtendedStatus 96;
									    
instance OCWipDefs ¶Prelude®¶.¶Eq®¶ OCWipDefs.WipDataPortExtendedStatus;
								       
OCWipDefs.fifofToGet :: ¶FIFOF®¶.¶FIFOF®¶ a -> ¶GetPut®¶.¶Get®¶ a
}
