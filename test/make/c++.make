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

include make/compile.make

CXXFLAGS:=-Wall -std=c++1y
LOCAL_SOURCE_EXT:=.cc
LOCAL_HEADER_EXT:=.hh
LOCAL_CC_FILES+=$(wildcard $(CDIR)*.cc)
LOCAL_CPP_FILES+=$(wildcard $(CDIR)*.cpp)
LOCAL_SOURCE_FILES+=$(LOCAL_CC_FILES)
LOCAL_SOURCE_FILES+=$(LOCAL_CPP_FILES)
LOCAL_O_FILES+=$(patsubst %.cc,$(LOCAL_OUT)/%.o,$(notdir $(LOCAL_CC_FILES)))
LOCAL_O_FILES+=$(patsubst %.cpp,$(LOCAL_OUT)/%.o,$(notdir $(LOCAL_CPP_FILES)))

#$(LOCAL_OUT)/%.o: LOCAL_CPPFLAGS:=$(LOCAL_CPPFLAGS)
#$(LOCAL_OUT)/%.o: LOCAL_CXXFLAGS:=$(LOCAL_CXXFLAGS)
$(LOCAL_OUT)/%.o: CPPFLAGS:=$(CPPFLAGS)
$(LOCAL_OUT)/%.o: CXXFLAGS:=$(CXXFLAGS)
$(LOCAL_OUT)/%.o: CDIR:=$(CDIR)
$(LOCAL_OUT)/%.o: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/%.o: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.o: $(CDIR)%.cc
	$(CCACHE) $(COMPILE.cc) $(LOCAL_CPPFLAGS) $(LOCAL_CXXFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) $<

$(LOCAL_OUT)/%.o: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.o: $(LOCAL_OUT)/%.cc
	$(CCACHE) $(COMPILE.cc) $(LOCAL_CPPFLAGS) $(LOCAL_CXXFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) $<

include make/code.make
