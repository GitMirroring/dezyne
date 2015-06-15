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

CFLAGS:=
LOCAL_SOURCE_EXT:=.c
LOCAL_HEADER_EXT:=.h
LOCAL_C_FILES+=$(wildcard $(CDIR)*.c)
LOCAL_SOURCE_FILES+=$(LOCAL_C_FILES)
LOCAL_O_FILES+=$(patsubst %.c,$(LOCAL_OUT)/%.o,$(notdir $(LOCAL_C_FILES)))

#$(LOCAL_OUT)/%.o: LOCAL_CFLAGS:=$(LOCAL_CFLAGS)
#$(LOCAL_OUT)/%.o: LOCAL_CPPFLAGS:=$(LOCAL_CPPFLAGS)
$(LOCAL_OUT)/%.o: CPPFLAGS:=$(CPPFLAGS)
$(LOCAL_OUT)/%.o: CFLAGS:=$(CFLAGS)
$(LOCAL_OUT)/%.o: CDIR:=$(CDIR)
$(LOCAL_OUT)/%.o: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/%.o: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.o: $(CDIR)%.c
	$(CCACHE) $(COMPILE.c) $(LOCAL_CPPFLAGS) $(LOCAL_CFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) $<

$(LOCAL_OUT)/%.o: LOCAL_O_FILES:=$(LOCAL_O_FILES)
$(LOCAL_OUT)/%.o: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.o: LOCAL_RUNTIME:=$(LOCAL_RUNTIME)
$(LOCAL_OUT)/%.o: $(LOCAL_OUT)/%.c
	$(CCACHE) $(COMPILE.c) $(LOCAL_CPPFLAGS) $(LOCAL_CFLAGS) $(DEPFLAGS) $(OUTPUT_OPTION) $<

include make/code.make
