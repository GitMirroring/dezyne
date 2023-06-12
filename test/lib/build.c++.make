# Dezyne --- Dezyne command line tools
#
# Copyright © 2016 Rob Wieringa <rma.wieringa@gmail.com>
# Copyright © 2016, 2018, 2020, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
# Copyright © 2016, 2017, 2018, 2019, 2020, 2021, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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

DEVELOPMENT:=$(shell readlink -f $(dir $(filter %/build.c++.make,$(MAKEFILE_LIST)))../../)
define CHECKPARAM
ifeq ($(origin $(1)), undefined)
$$(error $(1) undefined)
endif
endef

$(foreach i,IN OUT,$(eval $(call CHECKPARAM,$(i))))

SHELL:=bash
CCACHE:=$(shell type -p ccache)
CXX:=$(CCACHE) g++
ifndef WARN_FLAGS
WARN_FLAGS=					\
 -Wall						\
 -Wextra					\
 -Werror
endif
NOWARN_FLAGS=					\
 -Wno-unused-variable				\
 -Wno-unused-parameter				\
 -Wno-unused-but-set-variable
CXXFLAGS=-g -std=c++14 -MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@' -pthread $(WARN_FLAGS)
# FIXME: handwritten code, versioned?  $(IN)/../.. or ?
CPPFLAGS=-I$(OUT) -I$(OUT)/..  -I$(OUT)/../.. -I$(OUT)/../../c++ -I$(IN) -I$(IN)/.. -I$(DEVELOPMENT)/runtime/c++ -D DZN_VERSION_ASSERT=1
GLOBALS_H=$(wildcard $(IN)/globals.h)
ifneq ($(GLOBALS_H),)
CPPFLAGS:=$(CPPFLAGS) -include $(GLOBALS_H)
endif
CALLING_CONTEXT_HH=$(wildcard $(IN)/c++/calling_context.hh)
ifneq ($(CALLING_CONTEXT_HH),)
CPPFLAGS:=$(CPPFLAGS) -include $(CALLING_CONTEXT_HH)
endif

$(OUT)/%.o: $(DEVELOPMENT)/runtime/c++/%.cc
	mkdir -p $(dir $@)
	$(COMPILE.cc) -o $@ $<

$(OUT)/%.o: $(IN)/%.cc
	mkdir -p $(dir $@)
	$(COMPILE.cc) -o $@ $<

$(OUT)/%.o: $(IN)/c++/%.cc
	mkdir -p $(dir $@)
	$(COMPILE.cc) -o $@ $<

$(OUT)/%.o: $(OUT)/%.cc
	mkdir -p $(dir $@)
	$(COMPILE.cc) $(NOWARN_FLAGS) -o $@ $<

$(foreach f, $(wildcard $(IN)/c++/*.cc), $(eval $(OUT)/test: $(patsubst $(IN)/c++/%.cc, $(OUT)/%.o, $(f))))

$(OUT)/test: $(patsubst $(IN)/%.cc, $(OUT)/%.o, $(wildcard $(IN)/*.cc))
$(OUT)/test: $(patsubst $(OUT)/%.cc, $(OUT)/%.o, $(wildcard $(OUT)/*.cc))
$(OUT)/test: $(patsubst %.cc, %.o,$(wildcard $(OUT)/*.cc))
$(OUT)/test: $(patsubst %.cpp, %.o,$(wildcard $(OUT)/*.cpp))
$(OUT)/test: $(MAIN_O) $(OUT)/pump.o $(OUT)/runtime.o $(THREAD_POOL_O:%=$(OUT)/%)
	mkdir -p $(dir $@)
	$(LINK.cc) -o $@ $^ $(LDFLAGS)

-include $(patsubst $(IN)/%.cc, $(OUT)/%.d, $(wildcard $(IN)/*.cc))
