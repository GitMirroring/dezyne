# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

LOCAL_D_FILES:=$(patsubst %.dzn,$(LOCAL_OUT)/%.d,$(notdir $(LOCAL_DZN_FILES)))
LOCAL_D_FILES+=$(LOCAL_DZN_OUT_FILES:%.dzn=%.d)

ifeq ($(VERBOSE),debug)
$(info D_FILES: $(LOCAL_D_FILES))
endif

# I will say hello only once
ifeq ($(strip $(DZN_HELLO)),)
DZN_HELLO:=$(shell timeout 2 $(DZN) hello || { echo "timeout running: dzn hello" 1>&2; kill -9 $$PPID; })
endif

ifeq ($(DEVELOPMENT),)
DEVELOPMENT_DZN:=$(filter %/webapp/client/dzn,$(DZN))
DEVELOPMENT:=$(DEVELOPMENT_DZN:/webapp/client/dzn=)
DEVELOPMENT:=$(shell cd $(DEVELOPMENT) && pwd)
ifeq ($(VERBOSE),debug)
$(info Using dzn shortcut $(DEVELOPMENT))
endif
endif

# only attempt runtime if we got hello
ifeq ($(strip $(DZN_HELLO)),hello)
# list runtime only once for each language
LOCAL_RUNTIME:=$($(LOCAL_LANGUAGE)_RUNTIME)
LOCAL_RUNTIME_DEZYNE:=$($(LOCAL_LANGUAGE)_RUNTIME_DEZYNE)
ifeq ($($(LOCAL_LANGUAGE)_RUNTIME),)
ifeq ($(wildcard $(DEVELOPMENT)/gaiag),)
$(LOCAL_LANGUAGE)_RUNTIME:=$(filter-out makefile $(notdir $(LOCAL_SOURCE_FILES)),$(shell $(DZN) ls /share/runtime/$(LOCAL_LANGUAGE)))
else
$(LOCAL_LANGUAGE)_RUNTIME:=$(filter-out makefile $(notdir $(LOCAL_SOURCE_FILES)),$(shell ls -1F $(DEVELOPMENT)/gaiag/runtime/$(LOCAL_LANGUAGE)))
endif
LOCAL_RUNTIME:=$($(LOCAL_LANGUAGE)_RUNTIME)
ifeq ($(filter dezyne/,$(LOCAL_RUNTIME)),dezyne/)
ifeq ($(wildcard $(DEVELOPMENT)/gaiag),)
$(LOCAL_LANGUAGE)_RUNTIME_DEZYNE:=$(shell $(DZN) ls /share/runtime/$(LOCAL_LANGUAGE)/dezyne)
else
$(LOCAL_LANGUAGE)_RUNTIME_DEZYNE:=$(shell ls -1F $(DEVELOPMENT)/gaiag/runtime/$(LOCAL_LANGUAGE)/dezyne)
endif
LOCAL_RUNTIME_DEZYNE:=$($(LOCAL_LANGUAGE)_RUNTIME_DEZYNE)
endif
endif
endif

LOCAL_RUNTIME_HEADERS:=$(filter %$(LOCAL_HEADER_EXT),$(LOCAL_RUNTIME))
LOCAL_RUNTIME_SOURCES:=$(filter %$(LOCAL_SOURCE_EXT),$(LOCAL_RUNTIME))

ifeq ($(LOCAL_LANGUAGE),c)
LOCAL_O_FILES+=$(patsubst %,$(LOCAL_OUT)/%.o,$(LOCAL_INTERFACES))
endif

ifeq ($(filter $(LOCAL_LANGUAGE),c c++ c++03),$(LOCAL_LANGUAGE))

LOCAL_O_FILES+=$(LOCAL_OUT)/main.o
LOCAL_O_FILES+=$(patsubst %,$(LOCAL_OUT)/%.o,$(LOCAL_COMPONENTS))
LOCAL_O_FILES+=$(patsubst %$(LOCAL_SOURCE_EXT),$(LOCAL_OUT)/%.o,$(LOCAL_RUNTIME_SOURCES))
else # !c,c++,c++03
LOCAL_DEZYNE_FILES+=$(patsubst %,$(LOCAL_OUT)/dezyne/%$(LOCAL_SOURCE_EXT),$(LOCAL_INTERFACES) $(LOCAL_COMPONENTS))
endif # !c,c++,c++03

$(LOCAL_OUT)/%.d: LOCAL_SOURCE_EXT:=$(LOCAL_SOURCE_EXT)
$(LOCAL_OUT)/%.d: CDIR:=$(CDIR)
$(LOCAL_OUT)/%.d: LOCAL_NAME:=$(LOCAL_NAME)
$(LOCAL_OUT)/%.d: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/%.d: LOCAL_MAP_FILES:=$(LOCAL_MAP_FILES)
$(LOCAL_OUT)/%.d: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.d: LOCAL_SUT:=$(LOCAL_SUT)
ifeq ($(LOCAL_DZN_OUT_FILES),)
$(LOCAL_OUT)/%.d: $(CDIR)%.dzn
else
$(LOCAL_OUT)/%.d: $(LOCAL_OUT)/%.dzn
endif
	@mkdir -p $(LOCAL_OUT)
	@echo -e '.PRECIOUS: $(LOCAL_OUT)/%$(SOURCE_EXT) $(LOCAL_OUT)/%$(LOCAL_HEADER_EXT)' > $@
	$(DZN) depends -l $(LOCAL_LANGUAGE) -m $(LOCAL_SUT) -g $(*F) -o $(LOCAL_OUT) $< | sed 's,[*]global[*]_,,' >> $@
	@echo -e '\t$(DZN) code -l $(LOCAL_LANGUAGE) -m $(LOCAL_SUT) -o $(LOCAL_OUT) $< $(LOCAL_MAP_FILES) |& sed -e s,^,$(dir $<),' >> $@

depend: $(LOCAL_D_FILES)
ifeq ($(strip $(filter-out clean depend help run verify,$(MAKECMDGOALS))),$(MAKECMDGOALS))
-include $(LOCAL_D_FILES)
endif

define RUNTIME.rule
$(LOCAL_OUT)/$(1): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/$(1): LOCAL_OUT:=$$(LOCAL_OUT)
$(LOCAL_OUT)/$(1): LOCAL_RUNTIME:=$$(LOCAL_RUNTIME)
$(LOCAL_OUT)/$(1):
	mkdir -p $(LOCAL_OUT)
	@rm -f $$@
ifeq ($(wildcard $(DEVELOPMENT)/gaiag),)
	$(DZN) cat /share/runtime/$(LOCAL_LANGUAGE)/$$(notdir $$@) > $$@
else
	ln -sf $(DEVELOPMENT)/gaiag/runtime/$(LOCAL_LANGUAGE)/$$(notdir $$@) $$@
endif
endef

define RUNTIME_DEZYNE.rule
$(LOCAL_OUT)/dezyne/$(1): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/dezyne/$(1): LOCAL_OUT:=$$(LOCAL_OUT)
$(LOCAL_OUT)/dezyne/$(1): LOCAL_RUNTIME:=$$(LOCAL_RUNTIME)
$(LOCAL_OUT)/dezyne/$(1):
	mkdir -p $(LOCAL_OUT)/dezyne
	@rm -f $$@
ifeq ($(wildcard $(DEVELOPMENT)/gaiag),)
	$(DZN) cat /share/runtime/$(LOCAL_LANGUAGE)/dezyne/$$(notdir $$@) > $$@
else
	cat $(DEVELOPMENT)/gaiag/runtime/$(LOCAL_LANGUAGE)/dezyne/$$(notdir $$@) > $$@
endif
endef

define RUNTIME_SOURCE.dep
$(1).o: LOCAL_OUT:=$$(LOCAL_OUT)
$(1).o: LOCAL_RUNTIME_HEADERS:=$$(LOCAL_RUNTIME_HEADERS)
$(1).o: $$(LOCAL_RUNTIME_HEADERS:%=$$(LOCAL_OUT)/%)
endef

$(foreach i,$(LOCAL_RUNTIME),$(eval $(call RUNTIME.rule,$(i))))
$(foreach i,$(LOCAL_RUNTIME_DEZYNE),$(eval $(call RUNTIME_DEZYNE.rule,$(i))))
$(foreach i,$(LOCAL_RUNTIME_SOURCES:%=$(LOCAL_OUT)/%),$(eval $(call RUNTIME_SOURCE.dep,$(basename $(i)))))
$(foreach i,$(LOCAL_O_FILES),$(eval $(call RUNTIME_SOURCE.dep,$(basename $(i)))))

$(LOCAL_OUT)/main.o: LOCAL_O_FILES:=$(LOCAL_O_FILES)
$(LOCAL_OUT)/main.o: LOCAL_SUT:=$(LOCAL_SUT)
$(LOCAL_OUT)/main.o: LOCAL_NAME:=$(LOCAL_NAME)
$(LOCAL_OUT)/main.o: $(filter-out $(LOCAL_OUT)/main.o,$(LOCAL_O_FILES))

ifeq ($(HELP_DEZYNE),)
help: help-dezyne
define HELP_DEZYNE
  depend         create $(OUT)/<component|project>/<language>/*.d dependency-files for Dezyne
  clean-runtime  remove Dezyne runtime
endef
export HELP_DEZYNE
help-dezyne:
	@echo "$$HELP_DEZYNE"
endif

clean-runtime-$(LOCAL_TARGET): LOCAL_OUT:=$(LOCAL_OUT)
clean-runtime-$(LOCAL_TARGET): LOCAL_RUNTIME:=$(LOCAL_RUNTIME)
clean-runtime-$(LOCAL_TARGET): LOCAL_RUNTIME_DEZYNE:=$(LOCAL_RUNTIME_DEZYNE)
clean-runtime-$(LOCAL_TARGET):
	echo cleaning runtime $(LOCAL_OUT)
	rm -f $(LOCAL_RUNTIME:%=$(LOCAL_OUT)/%) $(LOCAL_RUNTIME_DEZYNE:%=$(LOCAL_OUT)/dezyne/%)

clean-runtime: clean-runtime-$(LOCAL_TARGET)

$(LOCAL_TARGET): LOCAL_DZN_FILES:=$(LOCAL_DZN_FILES)
$(LOCAL_TARGET): LOCAL_RUNTIME_HEADERS:=$(LOCAL_RUNTIME_HEADERS)
$(LOCAL_TARGET): LOCAL_RUNTIME_DEZYNE:=$(LOCAL_RUNTIME_DEZYNE)
all: LOCAL_DZN_FILES:=$(LOCAL_DZN_FILES)
all: LOCAL_RUNTIME:=$(LOCAL_RUNTIME)
all: LOCAL_RUNTIME_DEZYNE:=$(LOCAL_RUNTIME_DEZYNE)
