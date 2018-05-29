# Dezyne --- Dezyne command line tools
#
# Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

MAIN_DZN:=asdMeasureSequenceActionsArmourComp.dzn
SKIP_DZN:=asdDriverStatus.dzn
GLOBALS_H:=c++ControlModelsDataTypes.h

SHELL:=bash
xCCACHE:=$(shell type -p ccache)
CXX:=$(CCACHE) g++
MAIN_DZN:=alarmComp.dzn
SKIP_DZN:=foobar
LANGUAGE:=c++

GLOBALS_H:=globals.h

DM := $(wildcard *.dm)
IM := $(wildcard *.im)
COMP := $(patsubst %.dm, %.dzn, $(DM)) $(MAIN_DZN)
STUB := $(filter-out $(SKIP_DZN), $(patsubst %.im, %.dzn, $(IM)))
IDZN := $(patsubst %.im, I%.dzn, $(IM))
IDZN := $(patsubst Ialarm.dzn,Iconsole.dzn, $(IDZN))
SRC := $(patsubst I%.dzn, I%.hh, $(IDZN)) $(patsubst %.dzn, glue_%.cc, $(COMP) $(STUB))
DZN := $(COMP) $(IDZN) $(STUB)

TOP:= ../../../
DZN := $(TOP)/dzn/bin/dzn

CONVERT = $(DZN) -v convert -g -s -m $(1) $(2)
GENERATE = $(DZN) code -l $(LANGUAGE) -g dzn $(1) *.map

default: generate

convert: $(DZN)

generate: convert $(SRC)

%.dzn: %.dm
	$(call CONVERT,,$<)
	sed -i -e 's,interface ,interface glue.,' -e 's,component ,component glue.,' $@
	if [ -e $(basename $@)Comp.dzn ]; then sed -i -e 's,interface ,interface glue.,' -e 's,component ,component glue.,' $(basename $@)Comp.dzn; fi

%.dzn I%.dzn: %.im
	rm -rf tmp
	mkdir tmp
	$(call CONVERT,-o tmp,$<)
#	mv tmp/$@ . || sed -e 's@Iconsole@Ialarm@g' tmp/Iconsole.dzn > $@
	set -x; mv tmp/*dzn .
	if [ $< = alarm.im ]; then\
	    sed -i -e 's,interface ,interface glue.,' -e 's,component ,component glue.,' Iconsole.dzn;\
	else\
	    sed -i -e 's,interface ,interface glue.,' -e 's,component ,component glue.,' $@;\
	fi
	mv tmp/*.map .
	if [ ! -e $(basename $<).dzn ]; then mv tmp/$(basename $<).dzn .; sed -i -e 's,interface ,interface glue.,' -e 's,component ,component glue.,' $(basename $<).dzn; fi
	if [ $@ = siren.dzn ]; then \
	    sed -i \
		-e 's, on on$$, on on1,'\
		Isiren.map;\
	fi
	rm -rf tmp

%.hh: %.dzn
	$(call GENERATE,$<)

glue_%.hh: %.dzn
	$(call GENERATE,$<)

%.cc: %.dzn
	$(call GENERATE,$<)

glue_%.cc: %.dzn
	$(call GENERATE,$<)

glue_skel_sensor.cc: sensor.dzn
	$(call GENERATE,$<)
	sed -i 's,<ensor_cb>,< ::sensor::sensor_cb>,' $@

clean:
	rm -rf test *.o c++/*.o *.c* *.h* *.dzn *.map dzn

CPPFLAGS = --std=c++11 --include $(GLOBALS_H) -Ic++ -I../../../externals/asd_cpp_runtime -I.
CXXFLAGS = -O2

pump.cc runtime.cc:
	mkdir -p dzn
ifeq ($(LANGUAGE),c++)
	$(DZN) cat /share/runtime/$(LANGUAGE)/dzn/context.hh > dzn/context.hh
endif
	$(DZN) cat /share/runtime/$(LANGUAGE)/dzn/coroutine.hh > dzn/coroutine.hh
	$(DZN) cat /share/runtime/$(LANGUAGE)/dzn/pump.hh > dzn/pump.hh
	$(DZN) cat /share/runtime/$(LANGUAGE)/dzn/locator.hh > dzn/locator.hh
	$(DZN) cat /share/runtime/$(LANGUAGE)/dzn/meta.hh > dzn/meta.hh
	$(DZN) cat /share/runtime/$(LANGUAGE)/dzn/runtime.hh > dzn/runtime.hh
	$(DZN) cat /share/runtime/$(LANGUAGE)/pump.cc > pump.cc
	$(DZN) cat /share/runtime/$(LANGUAGE)/runtime.cc > runtime.cc

runtime.o: runtime.cc
pump.o: pump.cc

compile: pump.o runtime.o $(patsubst %.cc, %.o, $(wildcard *.cc)) $(patsubst %.cc, %.o, $(wildcard c++/*.cc)) $(patsubst %.cpp, %.o, $(wildcard c++/*.cpp)) $(patsubst %.cpp, %.o, $(wildcard *.cpp))
	$(CXX) -pthread -o test $^ -lboost_coroutine -lboost_thread -lboost_system  -lboost_chrono

test: compile
	./test
