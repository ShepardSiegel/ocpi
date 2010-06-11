# This file is for building a core, which will also build the library for it...
# The core must 

ifndef Core
Core=$(CwdName)
endif

ifdef CoreBlackBoxFile
ifeq ($(realpath $(CoreBlackBoxFile)),)
$(error CoreBlackBoxFile "$(CoreBlackBoxFile)" doesn't exist)
endif
else
$(error Variable "CoreBlackBoxFile" for $(Core) must be defined)
endif
ifndef Target
$(errr Variable \"Target\" for $(Core) must be defined)
endif

LibName=$(CwdName)
include $(OCPI_DIR)/include/hdl/hdl.mk
# Avoid compiling the black box file.
SourceFiles:=$(filter-out $(CoreBlackBoxFile),$(SourceFiles))
AuthoredSourceFiles=$(sort $(SourceFiles))

# More explicitly build the obj file, not as a side effect of the library

define DoCoreTarget

# The stub library
LibResults+=$(OutDir)$(call LibraryAccessTarget,$(1))/$(call LibraryFileTarget,$(1))
$(OutDir)$(call LibraryAccessTarget,$(1))/$(call LibraryFileTarget,$(1)): TargetDir=$(call LibraryAccessTarget,$(1))
$(OutDir)$(call LibraryAccessTarget,$(1))/$(call LibraryFileTarget,$(1)): Target=$(call LibraryAccessTarget,$(1))
$(OutDir)$(call LibraryAccessTarget,$(1))/$(call LibraryFileTarget,$(1)): SourceFiles=$(CoreBlackBoxFile) 
$(OutDir)$(call LibraryAccessTarget,$(1))/$(call LibraryFileTarget,$(1)): | $(OutDir)$(call LibraryAccessTarget,$(1))
$(OutDir)$(call LibraryAccessTarget,$(1)): | $(OutDir)
	$(AT)mkdir $$@


CoreResults+=$(OutDir)$(1)/$(Core)$(OBJ)
$(OutDir)$(1)/$(Core)$(SourceSuffix): Target=$(1)
$(OutDir)$(1)/$(Core)$(OBJ): Target=$(1)
$(OutDir)$(1)/$(Core)$(OBJ): TargetDir=$(1)
$(OutDir)$(1)/$(Core)$(OBJ): $(SourceFiles) | $(OutDir)$(1)
$(OutDir)$(1): | $(OutDir)
	$(AT)mkdir $$@
endef

$(foreach t,$(Targets),$(eval $(call DoCoreTarget,$(t))))

$(CoreResults):
	$(AT)echo Building core \"$(Core)\" for target \"$(Target)\"
	$(Compile)

#	$(MAKE) -f $(OCPI_DIR)/include/hdl/hdl-lib.mk \
#		CompiledSourceFiles="$(CoreBlackBoxFile) $(OCPI_DIR)/lib/hdl/onewire.v"\
#		OCPI_DIR=$(OCPI_DIR)

$(LibResults): $(CoreBlackBoxFile)
	$(AT)echo Building core \"$(Core)\" stub/blackbox library for target \"$(Target)\" from \"$(CoreBlackBoxFile)\"
	$(Compile)

#$(CoreBBs): $(CoreResults)
#	$(AT)echo Creating link to $(CoreBlackBoxFile) to expose the black box file for core "$(Core)".
#	$(AT)$(call MakeSymLink2,$(CoreBlackBoxFile),$(Target),$(Core)$(SourceSuffix))

# Create stub library after core is built
#$(LibBBs): $(CoreResults)
#	$(AT)echo Building core $(Core) for $(Target)
#	$(Compile)

all: $(CoreResults) $(LibResults)

clean:
	rm -r -f $(foreach f,$(Targets),$(OutDir)$(f) $(call LibraryAccessTarget,$(f)))

