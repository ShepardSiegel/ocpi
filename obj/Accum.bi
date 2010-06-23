signature Accum where {
import ¶DReg®¶;
	      
interface (Accum.AccumulatorIfc :: * -> *) accT = {
    Accum._read :: accT {-# arg_names = [] #-};
    Accum.load :: accT -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [ldval] #-};
    Accum.acc :: accT -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [inc] #-}
};
 
instance Accum (¶Prelude®¶.¶PrimMakeUndefined®¶ accT) =>
	       ¶Prelude®¶.¶PrimMakeUndefined®¶ (Accum.AccumulatorIfc accT);
									  
instance Accum (¶Prelude®¶.¶PrimDeepSeqCond®¶ accT) =>
	       ¶Prelude®¶.¶PrimDeepSeqCond®¶ (Accum.AccumulatorIfc accT);
									
instance Accum (¶Prelude®¶.¶PrimMakeUninitialized®¶ accT) =>
	       ¶Prelude®¶.¶PrimMakeUninitialized®¶ (Accum.AccumulatorIfc accT);
									      
Accum.mkAccumulator :: (¶Prelude®¶.¶Bounded®¶ accT,
			¶Prelude®¶.¶Eq®¶ accT,
			¶Prelude®¶.¶Ord®¶ accT,
			¶Prelude®¶.¶Bits®¶ accT accT_sz,
			¶Prelude®¶.¶Arith®¶ accT,
			¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		       _m__ (Accum.AccumulatorIfc accT);
						       
interface (Accum.Accumulator2Ifc :: * -> *) accT = {
    Accum._read :: accT {-# arg_names = [] #-};
    Accum.load :: accT -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [ldval] #-};
    Accum.acc1 :: accT -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [inc] #-};
    Accum.acc2 :: accT -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [inc] #-}
};
 
instance Accum (¶Prelude®¶.¶PrimMakeUndefined®¶ accT) =>
	       ¶Prelude®¶.¶PrimMakeUndefined®¶ (Accum.Accumulator2Ifc accT);
									   
instance Accum (¶Prelude®¶.¶PrimDeepSeqCond®¶ accT) =>
	       ¶Prelude®¶.¶PrimDeepSeqCond®¶ (Accum.Accumulator2Ifc accT);
									 
instance Accum (¶Prelude®¶.¶PrimMakeUninitialized®¶ accT) =>
	       ¶Prelude®¶.¶PrimMakeUninitialized®¶ (Accum.Accumulator2Ifc accT);
									       
Accum.mkAccumulator2 :: (¶Prelude®¶.¶Bounded®¶ accT,
			 ¶Prelude®¶.¶Eq®¶ accT,
			 ¶Prelude®¶.¶Ord®¶ accT,
			 ¶Prelude®¶.¶Bits®¶ accT accT_sz,
			 ¶Prelude®¶.¶Arith®¶ accT,
			 ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			_m__ (Accum.Accumulator2Ifc accT);
							 
Accum.mkAccumulatorReg2 :: (¶Prelude®¶.¶Bounded®¶ accT,
			    ¶Prelude®¶.¶Eq®¶ accT,
			    ¶Prelude®¶.¶Ord®¶ accT,
			    ¶Prelude®¶.¶Bits®¶ accT accT_sz,
			    ¶Prelude®¶.¶Arith®¶ accT,
			    ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			   _m__ (Accum.Accumulator2Ifc accT)
}
