signature SMAdapter where {
import Alias;
	    
import ¶ConfigReg®¶;
		   
import ¶Counter®¶;
		 
import ¶DReg®¶;
	      
import Accum;
	    
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
		
import OCWci;
	    
import OCWmemi;
	      
import OCWmi;
	    
import OCWsi;
	    
import OCWti;
	    
import OCWip;
	    
interface (SMAdapter.SMAdapterIfc :: # -> *) ndw = {
    SMAdapter.wciS0 :: OCWci.Wci_Es 20;
    SMAdapter.wmiM :: OCWmi.Wmi_Em 14 12 (¶Prelude®¶.¶TMul®¶ ndw 32) 0 (¶Prelude®¶.¶TMul®¶ ndw 4) 32;
    SMAdapter.wsiM1 :: OCWsi.Wsi_Em 12 (¶Prelude®¶.¶TMul®¶ ndw 32) (¶Prelude®¶.¶TMul®¶ ndw 4) 8 0;
    SMAdapter.wsiS1 :: OCWsi.Wsi_Es 12 (¶Prelude®¶.¶TMul®¶ ndw 32) (¶Prelude®¶.¶TMul®¶ ndw 4) 8 0
};
 
instance SMAdapter ¶Prelude®¶.¶PrimMakeUndefined®¶ (SMAdapter.SMAdapterIfc ndw);
									       
instance SMAdapter ¶Prelude®¶.¶PrimDeepSeqCond®¶ (SMAdapter.SMAdapterIfc ndw);
									     
instance SMAdapter ¶Prelude®¶.¶PrimMakeUninitialized®¶ (SMAdapter.SMAdapterIfc ndw);
										   
SMAdapter.mkSMAdapter :: (¶Prelude®¶.¶Add®¶ a_ 32 (¶Prelude®¶.¶TMul®¶ ndw 32),
			  OCWmi.DWordWidth ndw,
			  ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			 ¶Prelude®¶.¶Bit®¶ 32 -> _m__ (SMAdapter.SMAdapterIfc ndw);
										  
type (SMAdapter.SMAdapter4BIfc :: *) = SMAdapter.SMAdapterIfc 1;
							       
SMAdapter.mkSMAdapter4B :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			   ¶Prelude®¶.¶Bit®¶ 32 -> _m__ SMAdapter.SMAdapter4BIfc;
										
type (SMAdapter.SMAdapter8BIfc :: *) = SMAdapter.SMAdapterIfc 2;
							       
SMAdapter.mkSMAdapter8B :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			   ¶Prelude®¶.¶Bit®¶ 32 -> _m__ SMAdapter.SMAdapter8BIfc;
										
type (SMAdapter.SMAdapter16BIfc :: *) = SMAdapter.SMAdapterIfc 4;
								
SMAdapter.mkSMAdapter16B :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			    ¶Prelude®¶.¶Bit®¶ 32 -> _m__ SMAdapter.SMAdapter16BIfc;
										  
type (SMAdapter.SMAdapter32BIfc :: *) = SMAdapter.SMAdapterIfc 8;
								
SMAdapter.mkSMAdapter32B :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			    ¶Prelude®¶.¶Bit®¶ 32 -> _m__ SMAdapter.SMAdapter32BIfc
}
