# Dezyne --- Dezyne command line tools
#
# Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
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

.PHONY: default test

default: $(OUT)/test

define CHECKPARAM
ifeq ($(origin $(1)), undefined)
$$(error $(1) undefined)
endif
endef

$(foreach i,IN OUT,$(eval $(call CHECKPARAM,$(i))))

CXX:=ccache g++
CXXFLAGS=-g -std=c++03 -MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@' -pthread
CPPFLAGS=-I$(IN)
GLOBALS_H=$(wildcard $(DIR)/globals.h)
ifneq ($(GLOBALS_H),)
CPPFLAGS:=$(CPPFLAGS) -include $(GLOBALS_H)
endif

$(OUT)/%.o: $(IN)/%.cc
	mkdir -p $(dir $@)
	$(COMPILE.cc) -o $@ $<

$(OUT)/pump.o: CXXFLAGS=-g -std=c++11 -MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@' -pthread
$(OUT)/main.o: CXXFLAGS=-g -std=c++11 -MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@' -pthread

ifneq ($(MAIN),)
MAIN_O:=$(OUT)/$(patsubst %.cc,%.o,$(notdir $(MAIN)))
$(MAIN_O): $(MAIN)
	mkdir -p $(dir $@)
	$(COMPILE.cc) -o $@ $<
endif

$(OUT)/test: $(patsubst $(IN)/%.cc, $(OUT)/%.o, $(wildcard $(IN)/*.cc)) $(MAIN_O)
	mkdir -p $(dir $@)
	$(LINK.cc) -o $@ $^ $(LDFLAGS)

-include $(patsubst $(IN)/%.cc, $(OUT)/%.d, $(wildcard $(IN)/*.cc))
