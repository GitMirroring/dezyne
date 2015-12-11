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

ifneq ($(filter c++,$(LANGUAGES)),)
LOCAL_SUT:=alarm
LOCAL_LANGUAGE:=c++

#FIXME test framework expects Ialarm.dzn, convert produces Iconsole.dzn...
#LOCAL_IM_FILES:=$(wildcard $(CDIR)*.im)
LOCAL_IM_FILES:=$(filter-out $(CDIR)alarm.im, $(wildcard $(CDIR)*.im))
LOCAL_DM_FILES:=$(wildcard $(CDIR)*.dm)
LOCAL_INTERFACES:=$(LOCAL_IM_FILES:$(CDIR)%.im=I%) $(patsubst $(CDIR)%.dzn,%,$(wildcard $(CDIR)ITimer.dzn))
LOCAL_COMPONENTS:=$(LOCAL_DM_FILES:$(CDIR)%.dm=%) $(patsubst $(CDIR)%.dzn,%,$(wildcard $(CDIR)*System.dzn))

# LOCAL_DZN_FILES:=$(CDIR)GlobalTypes.dzn
include make/common.make

$(LOCAL_OUT)/main.o: $(LOCAL_OUT)/alarm.o
$(LOCAL_OUT)/alarm.o: $(LOCAL_OUT)/Iconsole.hh

$(LOCAL_OUT)/Iconsole.hh: $(LOCAL_OUT)/Iconsole.dzn
	$(DZN) code -l c++ -o $(LOCAL_OUT) $^

$(LOCAL_TARGET): CXXFLAGS:=$(CXXFLAGS) -pthread

# traces: TODO
# $(CDIR)baseline/convert.project/triangle/convert.project.trace.0: $(CDIR)baseline/convert.project/triangle/alarm.trace.0
# 	mkdir -p $(@D)
# 	mv $^ $@

include make/convert.make
include make/c++.make
DZN_OUT_FILES:=$(LOCAL_DZN_OUT_FILES)
include make/reset.make

code run table verify parse: $(DZN_OUT_FILES)

$(foreach DZN_FILE,$(DZN_OUT_FILES),\
	$(eval LOCAL_DZN_FILES:=$(DZN_FILE))\
	$(eval LOCAL_LANGUAGE:=parse)\
	$(eval include make/check.make))

$(foreach DZN_FILE,$(DZN_OUT_FILES),\
	$(eval LOCAL_DZN_FILES:=$(DZN_FILE))\
	$(eval LOCAL_LANGUAGE:=verify)\
	$(eval include make/check.make))

ifeq (0,1) # traces: TODO
$(foreach DZN_FILE,$(DZN_OUT_FILES),\
	$(eval LOCAL_DZN_FILES:=$(DZN_FILE))\
	$(eval LOCAL_LANGUAGE:=run)\
	$(eval include make/check.make))
endif

DZN_FILES:=
LANGUAGES:=
endif
