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

$(LOCAL_TARGET).o: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_TARGET).o: LOCAL_OUT:=$(LOCAL_OUT)

$(LOCAL_TARGET): CDIR:=$(CDIR)
$(LOCAL_TARGET): CPPFLAGS:=$(CPPFLAGS)
$(LOCAL_TARGET): LOCAL_DEZYNE_FILES:=$(LOCAL_DEZYNE_FILES)
$(LOCAL_TARGET): LOCAL_FOOTER:=$(LOCAL_FOOTER)
$(LOCAL_TARGET): LOCAL_HEADER:=$(LOCAL_HEADER)
$(LOCAL_TARGET): LOCAL_JS_FILES:=$(LOCAL_JS_FILES)
$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_TARGET): LOCAL_LDLIBS:=$(LOCAL_LDLIBS)
$(LOCAL_TARGET): LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_TARGET): LOCAL_O_FILES:=$(LOCAL_O_FILES)
$(LOCAL_TARGET): LOCAL_RUNTIME_SOURCES:=$(LOCAL_RUNTIME_SOURCES)
$(LOCAL_TARGET): LOCAL_SUT:=$(LOCAL_SUT)
$(LOCAL_TARGET): LOCAL_TARGET:=$(LOCAL_TARGET)


ifeq ($(filter $(LOCAL_LANGUAGE),c c++ c++03),$(LOCAL_LANGUAGE))
$(LOCAL_TARGET): $(LOCAL_O_FILES)
	$(LINK.cc) $^ $(LOCAL_LOADLIBES) $(LOCAL_LDLIBS) -o $@
else

$(LOCAL_TARGET): $(LOCAL_RUNTIME_SOURCES:%=$(LOCAL_OUT)/%)
$(LOCAL_TARGET): $(LOCAL_RUNTIME_DEZYNE:%=$(LOCAL_OUT)/dezyne/%)

ifeq ($(filter $(LOCAL_LANGUAGE),cs java),)
$(LOCAL_TARGET): $(LOCAL_HEADER) $(LOCAL_DEZYNE_FILES) $(LOCAL_FOOTER)
ifneq ($(LOCAL_HEADER),)
	cat $(LOCAL_HEADER) $(LOCAL_DEZYNE_FILES) $(LOCAL_FOOTER) > $@
else
	cat $(LOCAL_FOOTER) > $@
endif
	chmod +x $@
endif
endif
