# Makefile fragment for all workers 
# TODO:  implement a library search path so only library names can be used.
include $(OCPI_DIR)/include/util.mk
# Default is that you are building in a subdirectory of all implementations
ifneq ($(Worker),)
ifneq ($(Workers),)
$(error Cannot set both Worker and Workers variables in Makefile)
else
Workers=$(Worker)
endif
else
ifeq ($(Workers),)
Worker=$(basename $(CwdName))
$(info Worker name is $(Worker) from its directory name $(CwdName))
Workers=$(Worker)
endif
endif
GeneratedDir=$(OutDir)gen
TargetDir=$(OutDir)target-$(Target)
ImplXmlFiles=$(Workers:%=%.xml)
ifndef Application
ImplHeaderFiles=$(foreach w,$(Workers),$(GeneratedDir)/$(w)$(ImplSuffix))
SkelFiles=$(foreach w,$(Workers),$(GeneratedDir)/$(w)$(SkelSuffix))
WorkerSourceFiles=$(foreach w,$(Workers),$(w)$(SourceSuffix))
AuthoredSourceFiles=$(sort $(SourceFiles) $(WorkerSourceFiles))
endif
BinaryFile=$(TargetDir)/$(word 1,$(Workers))$(BF)
ObjectFiles= $(patsubst %$(SourceSuffix),$(TargetDir)/$(notdir %)$(OBJ),$(AuthoredSourceFiles)) \
             $(patsubst $(GeneratedDir)/%$(SourceSuffix),$(TargetDir)/%$(OBJ),$(GeneratedSourceFiles))
AEPLibraries=
OtherLibraries=

ToolsTarget=$(shell echo `uname -s`-`uname -p`)
ToolsDir=$(OCPI_DIR)/bin/$(ToolsTarget)
IncludeDirs:=$(OCPI_DIR)/include/$(Model) $(GeneratedDir) $(IncludeDirs)
CleanFiles += $(GeneratedSourceFiles)
override XmlIncludeDirs:=. $(XmlIncludeDirs)
# We assume all outputs are in the generated directory, so -M goes in that directory
OcpiGen=$(ToolsDir)/ocpigen -M $@.deps -D $(GeneratedDir) $(XmlIncludeDirs:%=-I%)

.SUFFIXES:

# If we are supposed to deposit a link into a library directory, then it should be the first/default target
ifdef LibDir
all: $(LibDir)/$(Target)/$(notdir $(BinaryFile))

$(LibDir)/$(Target)/$(notdir $(BinaryFile)): $(BinaryFile)
	$(AT)echo Creating link from $(LibDir)/$(Target) to $(BinaryFile) to expose the component binary.
	$(AT)$(call MakeSymLink,$(BinaryFile),$(LibDir)/$(Target))
else
all: $(BinaryFile)
endif

ifeq ($(filter $(BinaryFile),$(ObjectFiles)),)
$(BinaryFile): $(filter-out $(BinaryFile),$(ObjectFiles)) $(OtherLibraries) $(AEPLibraries) $(ArtifactXmlFile)
	$(LinkBinary)
	$(AT)if test "$(ArtifactXmlFile)"; then \
		(cat $(ArtifactXmlFile); sh -c 'echo X$$4' `ls -l $(ArtifactXmlFile)`) >> $@; \
	fi
endif

# all objects from non-generated source files need the source
$(patsubst %$(SourceSuffix),$(TargetDir)/$(notdir %)$(OBJ),$(AuthoredSourceFiles)): $(TargetDir)/%$(OBJ) : %$(SourceSuffix) 
	$(Compile) 

# objects from generated source need their source
$(patsubst $(GeneratedDir)/%$(SourceSuffix),$(TargetDir)/%$(OBJ),$(GeneratedSourceFiles)): $(TargetDir)/%$(OBJ) : $(GeneratedDir)/%$(SourceSuffix)
	$(Compile)

ifndef Application
# worker object files need impl headers
$(foreach w,$(Workers),$(TargetDir)/$(w)$(OBJ)): $(TargetDir)/%$(OBJ): $(GeneratedDir)/%$(ImplSuffix)

$(ImplHeaderFiles): $(GeneratedDir)/%$(ImplSuffix) : %.xml
	$(AT)echo Generating the implementation header file: $@
	$(AT)$(OcpiGen) -i  $<

$(SkelFiles): $(GeneratedDir)/%$(SkelSuffix) : %.xml
	$(AT)echo Generating the implementation skeleton file: $@
	$(AT)$(OcpiGen) -s $<
endif

$(ObjectFiles) $(BinaryFile): | $(TargetDir)

$(SkelFiles) $(ImplHeaderFiles): | $(GeneratedDir)

$(TargetDir) $(GeneratedDir): | $(OutDir)

$(TargetDir): | $(GeneratedDir)
	$(AT)echo Target directory \($@\) does not exist -- creating it.
	$(AT)mkdir $@

$(GeneratedDir):
	$(AT)echo Generated directory \($@\) does not exist -- creating it.
	$(AT)mkdir $@

# only when source file does not exist
ifndef Application
$(WorkerSourceFiles): %$(SourceSuffix) : $(GeneratedDir)/%$(SkelSuffix)
	$(AT)if test ! -e $@; then \
		echo No source file exists. Copying skeleton \($<\) to $@. ; \
		cp $< $@;\
	fi
endif

clean:
	$(AT)for s in $(AuthoredSourceFiles); do \
	    sk=$(GeneratedDir)/`echo $$s | sed s~$(SourceSuffix)$$~$(SkelSuffix)~`; \
	    if test -e $$s -a -e $$sk; then \
	        sed 's/GENERATED ON.*$$//' < $$s > $(GeneratedDir)/$$s; \
	        if (sed 's/GENERATED ON.*$$//' < $$sk | cmp -s - $(GeneratedDir)/$$s); then \
		    echo Source file \($$s\) identical to skeleton file \($$sk\).  Removing it.; \
	            rm $$s; \
		fi; \
	    fi; \
	done
	$(AT)rm -r -f $(ObjectFiles) $(ImplHeaderFiles) $(SkelFiles) $(GeneratedDir) $(TargetDir) $(CleanFiles)
	$(AT)for t in $(OutDir)target-*-*; do \
	  if test -d $$t; then \
	    rm -r -f $$t; \
	  fi; \
	done
	$(AT)rm -r -f $(OutDir)

-include $(GeneratedDir)/*.deps
