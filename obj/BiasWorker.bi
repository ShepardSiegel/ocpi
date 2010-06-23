signature BiasWorker where {
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
		
import OCWci;
	    
import OCWmemi;
	      
import OCWmi;
	    
import OCWsi;
	    
import OCWti;
	    
import OCWip;
	    
interface (BiasWorker.BiasWorker4BIfc :: *) = {
    BiasWorker.wciS0 :: OCWci.Wci_Es 20;
    BiasWorker.wsiS1 :: OCWsi.Wsi_Es 12 32 4 8 0;
    BiasWorker.wsiM1 :: OCWsi.Wsi_Em 12 32 4 8 0
};
 
instance BiasWorker ¶Prelude®¶.¶PrimMakeUndefined®¶ BiasWorker.BiasWorker4BIfc;
									      
instance BiasWorker ¶Prelude®¶.¶PrimDeepSeqCond®¶ BiasWorker.BiasWorker4BIfc;
									    
instance BiasWorker ¶Prelude®¶.¶PrimMakeUninitialized®¶ BiasWorker.BiasWorker4BIfc;
										  
BiasWorker.mkBiasWorker :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ BiasWorker.BiasWorker4BIfc
}
