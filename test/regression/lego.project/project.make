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

LOCAL_DZN_FILES:=$(wildcard $(CDIR)*.dzn)

# ifeq ($(LOCAL_LANGUAGE),c++)
# LOCAL_TRACE_LANGUAGE:=$(LOCAL_LANGUAGE)
# endif

ifeq ($(LOCAL_LANGUAGE),goops)
LOCAL_HEADER:=$(CDIR)config.scm
endif

include make/common.make

LOCAL_FILTER_O_FILES:=$(LOCAL_OUT)/gui.o $(LOCAL_OUT)/lego-main.o $(LOCAL_OUT)/pump.o

include make/$(LOCAL_LANGUAGE).make

$(LOCAL_OUT)/%.o: CDIR:=$(CDIR)
$(LOCAL_OUT)/%.o: LOCAL_HEADER_EXT:=$(LOCAL_HEADER_EXT)
$(LOCAL_OUT)/%.o: LOCAL_CFLAGS:=-I$(CDIR) -include MachineConstants$(LOCAL_HEADER_EXT)
$(LOCAL_OUT)/%.o: LOCAL_CXXFLAGS:=-I$(CDIR) -include MachineConstants$(LOCAL_HEADER_EXT)
$(LOCAL_OUT)/gui.o: LOCAL_CXXFLAGS+=$(shell pkg-config gtkmm-3.0 --cflags)
$(LOCAL_OUT)/gui.o: LOCAL_CFLAGS+=$(shell pkg-config gtk+-3.0 --cflags)
$(LOCAL_OUT)/main.o: LOCAL_CXXFLAGS:=$(shell pkg-config gtkmm-3.0 --cflags)
$(LOCAL_OUT)/main.o: LOCAL_CFLAGS:=$(shell pkg-config gtk+-3.0 --cflags)
$(LOCAL_TARGET): LOCAL_LDLIBS:=$(shell pkg-config gtkmm-3.0 --libs)

$(LOCAL_OUT)/main.o: $(LOCAL_OUT)/LegoBallSorter.o
$(LOCAL_OUT)/lego-main.o: $(LOCAL_OUT)/LegoBallSorter.o
$(LOCAL_OUT)/gui.o: $(LOCAL_OUT)/LegoBallSorter.o

include make/reset.make
