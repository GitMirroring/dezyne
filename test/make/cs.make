# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

LOCAL_SOURCE_EXT:=.cs
LOCAL_HEADER_EXT:=
LOCAL_CS_FILES+=$(wildcard $(CDIR)*.cs)
LOCAL_SOURCE_FILES+=$(LOCAL_CS_FILES)
LOCAL_HEADER:=$(LOCAL_OUT)/header.cs
LOCAL_FOOTER:=$(wildcard $(LOCAL_DIR)/main.cs)
ifeq ($(LOCAL_FOOTER),)
LOCAL_FOOTER:=$(LOCAL_OUT)/main.cs
endif

LOCAL_DEZYNE_FILES+=$(patsubst %,$(LOCAL_OUT)/dzn/%$(LOCAL_SOURCE_EXT),$(LOCAL_INTERFACES) $(LOCAL_COMPONENTS))
$(LOCAL_TARGET).exe: CDIR:=$(CDIR)
$(LOCAL_TARGET).exe: LOCAL_DEZYNE_FILES:=$(LOCAL_DEZYNE_FILES)
$(LOCAL_TARGET).exe: LOCAL_FOOTER:=$(LOCAL_FOOTER)
$(LOCAL_TARGET).exe: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_TARGET).exe: $(LOCAL_HEADER) $(LOCAL_DEZYNE_FILES) $(LOCAL_FOOTER) $(LOCAL_OUT)/main.cs
#	-cp $(CDIR)*.cs $(LOCAL_OUT)
	cp --force --backup $(LOCAL_FOOTER) $(LOCAL_OUT)/$(notdir $(LOCAL_FOOTER))
	mcs -debug -out:$@ $(LOCAL_OUT)/*.cs $(LOCAL_OUT)/dzn/*.cs

define MONO_SCRIPT
#! /bin/bash
mono $$(dirname $$0)/test.exe
endef
export MONO_SCRIPT

$(LOCAL_TARGET): $(LOCAL_HEADER) $(LOCAL_DEZYNE_FILES) $(LOCAL_FOOTER) $(LOCAL_TARGET).exe
	echo "$$MONO_SCRIPT" > $@
	chmod +x $@

include make/code.make
