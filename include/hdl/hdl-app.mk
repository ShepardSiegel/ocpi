# Makefile for an hdl assembly, which is a lot like a worker...
include $(OCPI_DIR)/include/util.mk
AppName=$(CwdName)
Worker=$(AppName)
# To get at the stubs from the component library
XmlIncludeDirs+=$(foreach l,$(OcpiLibraries),$(l)/lib $(l)/lib/hdl)
Application=yes
GeneratedSourceFiles+=$(GeneratedDir)/$(Worker)$(SourceSuffix)
include $(OCPI_DIR)/include/hdl/hdl-worker.mk
CompiledSourceFiles+=$(GeneratedDir)/$(Worker)$(SourceSuffix)

# The worker's source code is in fact generated, so this is overriding an earlier assignment

$(GeneratedSourceFiles): $(ImplXmlFiles) $(ImplDefsFiles) $(GeneratedDir)
	$(AT)echo Generating the application source file: $@
	$(AT)$(OcpiGen) -a  $<
	$(AT)mv $(GeneratedDir)/$(Worker)_assy.v $@