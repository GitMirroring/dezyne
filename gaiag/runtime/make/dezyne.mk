# Dezyne --- Dezyne command line tools
#
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

DZN:=dzn
DZN_FILES:=$(wildcard *.dzn)
D_FILES:=$(patsubst %.dzn,$(OUT)/%.d,$(DZN_FILES))

ifneq ($(strip $(wildcard *.dzn)),)
INTERFACES:=$(shell grep -hEo '^interface [_a-zA-Z0-9]+' $(DZN_FILES) | sed 's/^interface //')
COMPONENTS:=$(shell grep -hEo '^component [_a-zA-Z0-9]+' $(DZN_FILES) | sed 's/^component //')
endif

HELLO:=$(shell dzn hello)
ifeq ($(strip $(HELLO)),hello)
RUNTIME := $(filter-out makefile,$(shell dzn ls /runtime/$(LANGUAGE)))
endif

RUNTIME_HEADERS := $(filter %$(HEADER_EXT),$(RUNTIME))

all: $(RUNTIME_HEADERS:%=$(OUT)/%) $(RUNTIME:%=$(OUT)/%)

O_FILES += $(patsubst %,$(OUT)/%.o,$(COMPONENTS))
O_FILES += $(patsubst %.c,$(OUT)/%.o,$(filter %.c,$(RUNTIME)))
O_FILES += $(patsubst %.cc,$(OUT)/%.o,$(filter %.cc,$(RUNTIME)))

$(OUT)/%.d: %.dzn
	@mkdir -p $(OUT)
	echo -e '.PRECIOUS: $(OUT)/%$(SOURCE_EXT) $(OUT)/%$(HEADER_EXT)' > $@
	$(DZN) depends -l $(LANGUAGE) -o $(OUT) $< >> $@
	echo -e '\t$(DZN) code -l $(LANGUAGE) -o $(OUT) $<' >> $@

depend: $(D_FILES)
ifeq ($(strip $(filter-out clean depend,$(MAKECMDGOALS))),$(MAKECMDGOALS))
-include $(D_FILES)
endif

define RUNTIME.rule
$(OUT)/$(1):
	@mkdir -p $(OUT)
	@rm -f $$@
	#dzn cat /runtime/$(LANGUAGE)/$$(notdir $$@) > $$@
	#ln -s ~/development.git/gaiag/runtime/$(LANGUAGE)/$$(notdir $$@) $$@
	ln -s ~/development.git/webapp/server/commands/runtime/$(LANGUAGE)/$$(notdir $$@) $$@
endef

$(foreach i,$(RUNTIME),$(eval $(call RUNTIME.rule,$(i))))

clean-runtime:
	rm -f $(RUNTIME:%=$(OUT)/%)

help: help-dezyne
help-dezyne:
	@echo '  depend         create $(OUT)/*.d dependency-files for Dezyne'
	@echo '  clean-runtime  remove Dezyne runtime'
