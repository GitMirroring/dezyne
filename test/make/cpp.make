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

LOCAL_CPP_FILES+=$(wildcard $(CDIR)*.cpp)
LOCAL_SOURCE_FILES+=$(LOCAL_CPP_FILES)
LOCAL_O_FILES+=$(patsubst %.cpp,$(LOCAL_OUT)/%.o,$(notdir $(LOCAL_CPP_FILES)))

$(LOCAL_OUT)/%.o: LOCAL_CPPFLAGS:=$(LOCAL_CPPFLAGS)
#$(LOCAL_OUT)/%.o: LOCAL_CXXFLAGS:=$(LOCAL_CXXFLAGS)
$(LOCAL_OUT)/%.o: CDIR:=$(CDIR)
$(LOCAL_OUT)/%.o: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/%.o: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.o: $(CDIR)%.cpp
#$(LOCAL_OUT)/AlarmSystemComponent.o: $(CDIR)AlarmSystemComponent/%.cpp
#$(LOCAL_OUT)/AlarmSystemComponent.o: regression/glue.project/AlarmSystemComponent.cpp
	$(CCACHE) $(COMPILE.cc) $(LOCAL_CPPFLAGS) $(LOCAL_CXXFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) $<

$(LOCAL_OUT)/%.o: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.o: $(LOCAL_OUT)/%.cpp
	$(CCACHE) $(COMPILE.cc) $(LOCAL_CPPFLAGS) $(LOCAL_CXXFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) $<
