signature OCApp where {
import Alias;
	    
import Config;
	     
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
	    
import BiasWorker;
		 
import SMAdapter;
		
interface (OCApp.OCAppIfc :: # -> # -> # -> *) nWci nWmi nWmemi = {
    OCApp.wci_s :: ¶Vector®¶.¶Vector®¶ nWci (OCWci.Wci_Es 20);
    OCApp.wmiM0 :: OCWmi.WmiEM4B;
    OCApp.wmiM1 :: OCWmi.WmiEM4B;
    OCApp.wmemiM :: OCWmemi.WmemiEM16B;
    OCApp.wsi_s_adc :: OCWsi.WsiES4B;
    OCApp.wsi_m_dac :: OCWsi.WsiEM4B
};
 
instance OCApp ¶Prelude®¶.¶PrimMakeUndefined®¶ (OCApp.OCAppIfc nWci nWmi nWmemi);
										
instance OCApp ¶Prelude®¶.¶PrimDeepSeqCond®¶ (OCApp.OCAppIfc nWci nWmi nWmemi);
									      
instance OCApp ¶Prelude®¶.¶PrimMakeUninitialized®¶ (OCApp.OCAppIfc nWci nWmi nWmemi);
										    
OCApp.mkOCApp_poly :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		      ¶Vector®¶.¶Vector®¶ nWci ¶Prelude®¶.¶Reset®¶ -> _m__ (OCApp.OCAppIfc nWci nWmi nWmemi);
													    
OCApp.mkOCApp :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		 ¶Vector®¶.¶Vector®¶ Config.Nwci_app ¶Prelude®¶.¶Reset®¶ ->
		 _m__ (OCApp.OCAppIfc Config.Nwci_app Config.Nwmi Config.Nwmemi)
}
