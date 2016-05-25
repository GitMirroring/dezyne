# Dezyne --- Dezyne command line tools
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
# Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

CXX:=ccache g++
CXXFLAGS=-g -std=c++11 -MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@' -pthread
CPPFLAGS=-I$(IN)
GLOBALS_H=$(wildcard $(DIR)/globals.h)
ifneq ($(GLOBALS_H),)
CPPFLAGS:=$(CPPFLAGS) -include $(GLOBALS_H)
endif

$(OUT)/%.o: $(IN)/%.cc
	mkdir -p $(dir $@)
	$(COMPILE.cc) -o $@ $<

$(OUT)/test: $(patsubst $(IN)/%.cc, $(OUT)/%.o, $(wildcard $(IN)/*.cc))
	mkdir -p $(dir $@)
	$(LINK.cc) -o $@ $^ $(LDFLAGS)

-include $(patsubst $(IN)/%.cc, $(OUT)/%.d, $(wildcard $(IN)/*.cc))
