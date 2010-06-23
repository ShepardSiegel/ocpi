signature OCWip where {
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
	    
data (OCWipDefs.OCP_CMD :: *) =
    OCWipDefs.IDLE () |
    OCWipDefs.WR () |
    OCWipDefs.RD () |
    OCWipDefs.RDEX () |
    OCWipDefs.RDL () |
    OCWipDefs.WRNP () |
    OCWipDefs.WRC () |
    OCWipDefs.BCST ();
		     
data (OCWipDefs.OCP_RESP :: *) =
    OCWipDefs.NULL () | OCWipDefs.DVA () | OCWipDefs.FAIL () | OCWipDefs.ERR ();
									       
data (OCWipDefs.OCP_BURST :: *) = OCWipDefs.None () | OCWipDefs.Precise () | OCWipDefs.Imprecise ();
												   
struct (OCWipDefs.MesgMeta :: *) = {
    OCWipDefs.length :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.opcode :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.nowMS :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.nowLS :: ¶Prelude®¶.¶Bit®¶ 32
};
 
struct (OCWipDefs.MesgMetaDW :: *) = {
    OCWipDefs.tag :: ¶Prelude®¶.¶Bit®¶ 8;
    OCWipDefs.opcode :: ¶Prelude®¶.¶Bit®¶ 8;
    OCWipDefs.length :: ¶Prelude®¶.¶Bit®¶ 16
};
 
struct (OCWipDefs.MesgMetaFlag :: *) = {
    OCWipDefs.opcode :: ¶Prelude®¶.¶Bit®¶ 8;
    OCWipDefs.length :: ¶Prelude®¶.¶Bit®¶ 24
};
 
data (OCWipDefs.SampOpcode :: *) =
    OCWipDefs.Sample () | OCWipDefs.Sync () | OCWipDefs.Timestamp () | OCWipDefs.Rsvd ();
											
struct (OCWipDefs.SampMesg :: *) = {
    OCWipDefs.opcode :: OCWipDefs.SampOpcode;
    OCWipDefs.last :: ¶Prelude®¶.¶Bool®¶;
    OCWipDefs.be :: ¶Prelude®¶.¶Bit®¶ 4;
    OCWipDefs.¡data¡ :: ¶Prelude®¶.¶Bit®¶ 32
};
 
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
 
struct (OCWipDefs.WipDataPortExtendedStatus :: *) = {
    OCWipDefs.pMesgCount :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.iMesgCount :: ¶Prelude®¶.¶Bit®¶ 32;
    OCWipDefs.tBusyCount :: ¶Prelude®¶.¶Bit®¶ 32
};
 
OCWipDefs.fifofToGet :: ¶FIFOF®¶.¶FIFOF®¶ a -> ¶GetPut®¶.¶Get®¶ a;
								 
struct (OCWci.WciAttributes :: *) = {
    OCWci.sizeOfConfigSpace :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWci.writableConfigProperties :: ¶Prelude®¶.¶Bool®¶;
    OCWci.readableConfigProperties :: ¶Prelude®¶.¶Bool®¶;
    OCWci.sub32bitConfigProperties :: ¶Prelude®¶.¶Bool®¶;
    OCWci.resetWhileSuspended :: ¶Prelude®¶.¶Bool®¶
};
 
data (OCWci.WCI_CONTROL_OP :: *) =
    OCWci.Initialize () |
    OCWci.Start () |
    OCWci.Stop () |
    OCWci.Release () |
    OCWci.Test () |
    OCWci.BeforeQuery () |
    OCWci.AfterConfig () |
    OCWci.Rsvd7 ();
		  
data (OCWci.WCI_STATE :: *) =
    OCWci.Exists () |
    OCWci.Initialized () |
    OCWci.Operating () |
    OCWci.Suspended () |
    OCWci.Unusable () |
    OCWci.Rsvd5 () |
    OCWci.Rsvd6 () |
    OCWci.Rsvd7 ();
		  
data (OCWci.WCI_REQ :: *) = OCWci.None () | OCWci.CfgWt () | OCWci.CfgRd () | OCWci.CtlOp ();
											    
data (OCWci.WCI_SPACE :: *) = OCWci.Admin () | OCWci.Control () | OCWci.Config ();
										 
struct (OCWci.ReqTBits :: *) = {
    OCWci.cfgWt :: ¶Prelude®¶.¶Bool®¶;
    OCWci.cfgRd :: ¶Prelude®¶.¶Bool®¶;
    OCWci.ctlOp :: ¶Prelude®¶.¶Bool®¶
};
 
struct (OCWci.WciReq :: # -> *) na = {
    OCWci.cmd :: OCWipDefs.OCP_CMD;
    OCWci.addrSpace :: ¶Prelude®¶.¶Bit®¶ 1;
    OCWci.byteEn :: ¶Prelude®¶.¶Bit®¶ 4;
    OCWci.addr :: ¶Prelude®¶.¶Bit®¶ na;
    OCWci.¡data¡ :: ¶Prelude®¶.¶Bit®¶ 32
};
 
struct (OCWci.WciResp :: *) = {
    OCWci.resp :: OCWipDefs.OCP_RESP;
    OCWci.¡data¡ :: ¶Prelude®¶.¶Bit®¶ 32
};
 
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
 
interface (OCWci.Wci_MasterReq_Ifc :: # -> *) na {-# always_ready  #-} = {
    OCWci.mCmd :: OCWipDefs.OCP_CMD {-# arg_names = [], result = "MCmd" #-};
    OCWci.mAddrSpace :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "MAddrSpace" #-};
    OCWci.mByteEn :: ¶Prelude®¶.¶Bit®¶ 4 {-# arg_names = [], result = "MByteEn" #-};
    OCWci.mAddr :: ¶Prelude®¶.¶Bit®¶ na {-# arg_names = [], result = "MAddr" #-};
    OCWci.mData :: ¶Prelude®¶.¶Bit®¶ 32 {-# arg_names = [], result = "MData" #-};
    OCWci.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SThreadBusy" #-}
};
 
interface (OCWci.Wci_MasterResp_Ifc :: *) {-# always_ready  #-} = {
    OCWci.putResponse :: OCWipDefs.OCP_RESP ->
			 ¶Prelude®¶.¶Bit®¶ 32 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡SResp¡, ¡SData¡],
									  prefixs = "",
									  always_enabled  #-}
};
 
interface (OCWci.Wci_Xs :: # -> *) na = {
    OCWci.slaveReq :: OCWci.Wci_SlaveReq_Ifc na {-# prefixs = "" #-};
    OCWci.slaveResp :: OCWci.Wci_SlaveResp_Ifc {-# prefixs = "" #-};
    OCWci.sFlag :: ¶Prelude®¶.¶Bit®¶ 2 {-# arg_names = [], result = "SFlag", prefixs = "" #-};
    OCWci.mFlag :: ¶Prelude®¶.¶Bit®¶ 2 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡MFlag¡],
								   always_enabled ,
								   prefixs = "" #-}
};
 
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
 
interface (OCWci.Wci_SlaveResp_Ifc :: *) {-# always_ready  #-} = {
    OCWci.sResp :: OCWipDefs.OCP_RESP {-# arg_names = [], result = "SResp" #-};
    OCWci.sData :: ¶Prelude®¶.¶Bit®¶ 32 {-# arg_names = [], result = "SData" #-}
};
 
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
 
OCWci.mkWciSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWci.WciSlaveIfc na);
										     
interface (OCWci.WciSlaveNullIfc :: # -> *) na = {
    OCWci.slv :: OCWci.Wci_s na
};
 
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
 
OCWci.mkWciXSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWci.WciXSlaveIfc na);
										       
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
 
struct (OCWmemi.WmemiDh :: # -> # -> *) nd ne = {
    OCWmemi.dataValid :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.dataLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd;
    OCWmemi.dataByteEn :: ¶Prelude®¶.¶Bit®¶ ne
};
 
struct (OCWmemi.WmemiResp :: # -> *) nd = {
    OCWmemi.resp :: OCWipDefs.OCP_RESP;
    OCWmemi.respLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmemi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd
};
 
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
 
OCWmemi.mkWmemiSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
			_m__ (OCWmemi.WmemiSlaveIfc na nb nd ne);
								
struct (OCWmi.WmiAttributes :: *) = {
    OCWmi.continuous :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.dataWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmi.byteWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWmi.impreciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.preciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.talkBack :: ¶Prelude®¶.¶Bool®¶
};
 
class (OCWmi.DWordWidth :: # -> *) ndw where {
};
 
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
 
struct (OCWmi.WmiDh :: # -> # -> # -> *) nd ni ne = {
    OCWmi.dataValid :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.dataLast :: ¶Prelude®¶.¶Bool®¶;
    OCWmi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd;
    OCWmi.dataInfo :: ¶Prelude®¶.¶Bit®¶ ni;
    OCWmi.dataByteEn :: ¶Prelude®¶.¶Bit®¶ ne
};
 
struct (OCWmi.WmiResp :: # -> *) nd = {
    OCWmi.resp :: OCWipDefs.OCP_RESP;
    OCWmi.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd
};
 
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
 
OCWmi.mkWmiSlave :: (¶Prelude®¶.¶Add®¶ b_ 24 nf,
		     ¶Prelude®¶.¶Add®¶ a_ 8 nf,
		     ¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
		    _m__ (OCWmi.WmiSlaveIfc na nb nd ni ne nf);
							      
struct (OCWsi.WsiAttributes :: *) = {
    OCWsi.continuous :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.dataWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWsi.byteWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWsi.impreciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.preciseBurst :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.abortable :: ¶Prelude®¶.¶Bool®¶;
    OCWsi.earlyRequest :: ¶Prelude®¶.¶Bool®¶
};
 
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
 
OCWsi.wsiIdleRequest :: OCWsi.WsiReq nb nd ng nh ni;
						   
interface (OCWsi.Wsi_m :: # -> # -> # -> # -> # -> *) nb nd ng nh ni {-# always_ready  #-} = {
    OCWsi.get :: OCWsi.WsiReq nb nd ng nh ni {-# arg_names = [], result = "req" #-};
    OCWsi.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-};
    OCWsi.mReset_n :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "MReset_n", prefixs = "" #-};
    OCWsi.sReset_n :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [], enable = "SReset_n", prefixs = "" #-}
};
 
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
 
OCWsi.mkWsiMaster :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWsi.WsiMasterIfc nb nd ng nh ni);
												   
interface (OCWsi.WsiSlaveIfc :: # -> # -> # -> # -> # -> *) nb nd ng nh ni = {
    OCWsi.reqGet :: ¶GetPut®¶.¶Get®¶ (OCWsi.WsiReq nb nd ng nh ni);
    OCWsi.reqPeek :: OCWsi.WsiReq nb nd ng nh ni {-# arg_names = [] #-};
    OCWsi.operate :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [] #-};
    OCWsi.status :: OCWipDefs.WipDataPortStatus {-# arg_names = [] #-};
    OCWsi.extStatus :: OCWipDefs.WipDataPortExtendedStatus {-# arg_names = [] #-};
    OCWsi.slv :: OCWsi.Wsi_s nb nd ng nh ni
};
 
type (OCWsi.SRBsize :: #) = 3;
			     
OCWsi.mkWsiSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWsi.WsiSlaveIfc nb nd ng nh ni);
												 
struct (OCWti.WtiAttributes :: *) = {
    OCWti.secondsWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWti.fractionWidth :: ¶Prelude®¶.¶UInt®¶ 32;
    OCWti.allowUnavailable :: ¶Prelude®¶.¶Bool®¶
};
 
struct (OCWti.WtiReq :: # -> *) nd = {
    OCWti.cmd :: OCWipDefs.OCP_CMD;
    OCWti.¡data¡ :: ¶Prelude®¶.¶Bit®¶ nd
};
 
OCWti.wtiIdleRequest :: OCWti.WtiReq nd;
				       
interface (OCWti.Wti_m :: # -> *) nd {-# always_ready  #-} = {
    OCWti.get :: OCWti.WtiReq nd {-# arg_names = [], result = "req" #-};
    OCWti.sThreadBusy :: ¶Prelude®¶.¶Action®¶ {-# arg_names = [],
						  enable = "SThreadBusy",
						  prefixs = "" #-}
};
 
interface (OCWti.Wti_s :: # -> *) nd {-# always_ready  #-} = {
    OCWti.put :: OCWti.WtiReq nd -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [req],
							     always_enabled ,
							     prefixs = "" #-};
    OCWti.sThreadBusy :: ¶Prelude®¶.¶Bool®¶ {-# arg_names = [], result = "SThreadBusy", prefixs = "" #-}
};
 
interface (OCWti.WtiMasterIfc :: # -> *) nd = {
    OCWti.reqPut :: ¶GetPut®¶.¶Put®¶ (OCWti.WtiReq nd);
    OCWti.mas :: OCWti.Wti_m nd
};
 
OCWti.mkWtiMaster :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWti.WtiMasterIfc nd);
										       
interface (OCWti.WtiSlaveIfc :: # -> *) nd = {
    OCWti.slv :: OCWti.Wti_s nd;
    OCWti.reqGet :: ¶GetPut®¶.¶Get®¶ (OCWti.WtiReq nd);
    OCWti.now :: ¶Prelude®¶.¶Bit®¶ nd {-# arg_names = [] #-}
};
 
OCWti.mkWtiSlave :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ (OCWti.WtiSlaveIfc nd)
}
