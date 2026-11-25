/* Quartus Prime Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(5CSEMA5F31) MfrSpec(OpMask(0) FullPath("//VSRV1/B.Homes$/leungva7/Downloads/Audio/Audio/output_files/audio_demo.sof"));
	P ActionCode(Cfg)
		Device PartName(5CSEMA5F31) Path("//VSRV1/B.Homes$/leungva7/Downloads/Audio/Audio/output_files/") File("audio_demo.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
