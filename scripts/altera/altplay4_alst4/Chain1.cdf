/* Quartus II Version 11.0 Build 208 07/03/2011 Service Pack 1.10 SJ Full Version */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(EP4SGX230KF40) Path("/home/shep/projects/ocpi/scripts/altera/altplay4_alst4/") File("fpgaTop_alst4.sof") MfrSpec(OpMask(1));
	P ActionCode(Ign)
		Device PartName(EPM2210) MfrSpec(OpMask(0));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
