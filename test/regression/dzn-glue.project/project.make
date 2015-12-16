# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
LOCAL_MAP_FILES:=$(wildcard $(CDIR)*.map)
include make/common.make
include make/cpp.make

$(LOCAL_OUT)/AlarmSystemComponent.cpp: CDIR:=$(CDIR)
$(LOCAL_OUT)/AlarmSystemComponent.cpp: LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(LOCAL_OUT)/AlarmSystemComponent.cpp: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_OUT)/AlarmSystemComponent.cpp: LOCAL_MAP_FILES:=$(LOCAL_MAP_FILES)
$(LOCAL_OUT)/AlarmSystemComponent.cpp: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/AlarmSystemComponent.cpp: $(LOCAL_DZN_TOP)
	$(DZN) code -l $(LOCAL_LANGUAGE) -o $(LOCAL_OUT) $(CDIR)AlarmSystem.dzn $(LOCAL_MAP_FILES) |& sed -e s,^,$(dir $<),

GLUE_O_FILES:=\
  $(LOCAL_OUT)/AlarmSystemComponent.o\
  $(LOCAL_OUT)/glue-Sensor.o\
  $(LOCAL_OUT)/glue-Siren.o\

LOCAL_O_FILES+=$(GLUE_O_FILES)
LOCAL_O_FILES:=$(filter-out $(LOCAL_OUT)/Sensor.o $(LOCAL_OUT)/Siren.o, $(LOCAL_O_FILES))
LOCAL_COMPONENTS:=$(filter-out Sensor Siren, $(LOCAL_COMPONENTS))

$(LOCAL_OUT)/AlarmSystemComponent.o: $(LOCAL_OUT)/AlarmSystem.o

include make/$(LOCAL_LANGUAGE).make

include make/reset.make
