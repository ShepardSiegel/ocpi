# A component library, consisting of different models built for different targets
# The expectation is that a library has spec XML in the top level, and subdirectories for each implementation.
# Active implementations are lists in the Implementations variable
# This this makefile just names the library and lists implementations to be built.
# The name of an implementation subdirectory includes its authoring model as the file extension.
# This specification of model is redundant with the "include" line in the makefile inside the directory
# We also list the targets per model.
# A component library, consisting of different models built for different targets
include $(OCPI_DIR)/include/util.mk
RccImplementations=$(filter %.rcc,$(Implementations))
HdlImplementations=$(filter %.hdl,$(Implementations))
LibDir=lib
Models=rcc hdl
CapModels=$(foreach m,$(Models),$(call Capitalize,$(m)))
LibDirs=$(foreach m,$(CapModels),$(foreach ht,$($(m)Targets),$(LibDir)/$(call UnCapitalize,$(m))/$(ht)))
XmlIncludeDirs=.
# default is what we are running on
RccTargets=$(shell echo `uname -s`-`uname -p`)
# function to build the targets for an implemention.
#  First arg is model
#  second is implementation directory
ifdef OCPI_OUT_DIR
PassOutDir=OCPI_OUT_DIR=$(call AdjustRelative,$(OutDir:%/=%))
endif
BuildImplementation=\
    set -e; for t in $($(call Capitalize,$(1))Targets); do \
	if ! test -d $(OutDir)lib/$(1)/$$t; then \
            mkdir $(OutDir)lib/$(1)/$$t; \
	fi; \
        $(ECHO) Building $(call ToUpper,$(1)) implementation $(2) for target $$t; \
	$(MAKE) -C $(2) OCPI_DIR=$(call AdjustRelative,$(OCPI_DIR)) Target=$$t \
	       LibDir=$(call AdjustRelative,$(OutDir)lib/$(1)) \
	       $(PassOutDir) \
               VerilogIncludeDirs=$(call AdjustRelative,$(VerilogIncludeDirs)) \
               XmlIncludeDirs=$(call AdjustRelative,$(XmlIncludeDirs));\
    done; \

BuildModel=\
	$(AT)set -e;if test "$($(call Capitalize,$(1))Implementations)"; then \
	  for i in $($(call Capitalize,$(1))Implementations); do \
		if test ! -d $$i; then \
			echo Implementation \"$$i\" has no directory here.; \
			exit 1; \
		else \
			$(call BuildImplementation,$(1),$$i) \
		fi;\
	  done; \
        fi

CleanModel=\
	$(AT)if test "$($(call Capitalize,$(1))Implementations)"; then \
	  for i in $($(call Capitalize,$(1))Implementations); do \
		if test -d $$i; then \
			for t in $($(call Capitalize,$(1))Targets); do \
				$(ECHO) Cleaning $(call ToUpper,$(1)) implementation $$i for target $$t; \
				$(MAKE) -C $$i $(PassOutDir) OCPI_DIR=$(call AdjustRelative,$(OCPI_DIR)) Target=$$t clean; \
			done; \
		fi;\
	  done; \
        fi

all: rcc hdl specs

specs: | $(OutDir)lib
	$(AT)$(foreach f,$(wildcard *_spec.xml) $(wildcard *_protocol.xml),$(call MakeSymLink,$(f),$(OutDir)lib);)

$(OutDir)lib: |$(OutDir)
	mkdir $@

$(Models:%=$(OutDir)lib/%): | $(OutDir)lib
	mkdir $@

rcc: | $(OutDir)lib/rcc
	$(call BuildModel,rcc)

# The submake below is to create the library of stubs that allow the application assembly
# to find the black box empty modue definitions for the synthesized cores in this component library
hdl: | $(OutDir)lib/hdl
	$(call BuildModel,hdl)
	$(MAKE) -C $(OutDir)lib/hdl -L -f $(abspath $(OCPI_DIR))/include/hdl/hdl-lib.mk OCPI_DIR=$(call AdjustRelative2,$(OCPI_DIR))

$(OutDir)lib/hdl/Makefile:
	$(AT)echo 

cleanrcc:
	$(call CleanModel,rcc)

cleanhdl:
	$(call CleanModel,hdl)

clean: cleanrcc cleanhdl
	$(AT)echo Cleaning library directory for all targets.
	$(AT)rm -fr $(OutDir)lib $(OutDir)

$(HdlImplementations): | $(OutDir)lib/hdl
	$(AT)$(call BuildImplementation,hdl,$@)

$(RccImplementations): | $(OutDir)lib/rcc
	$(AT)$(call BuildImplementation,rcc,$@)

.PHONY: $(RccImplementations) $(HdlImplementations) specs
