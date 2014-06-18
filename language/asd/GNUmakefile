# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Gaiag.
#
# Gaiag is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Gaiag is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

DEPTH = ../..
diff = diff -uw -I '^ *$$' -I '^ *//'
sed = sed -e 's/^-gen/gen/' -re 's/((cppbase.cpp|.hh.scm|.cc.scm):[0-9]*):/\1:warning:/'
BUILD = build
asdgen = ASD_PREFIX=$(DEPTH) $(DEPTH)/$(BUILD)/asdgenerator
baseline = baseline

default: all

all: compile check test match wfc

compile:
	guile -L ../.. spec.scm 

dummy:

baseline: dummy
	$(asdgen) -l cpp examples/alarm-component-pretty.asd && mv Alarm* $(baseline)
	$(asdgen) -l cpp examples/CommImpl.asd && mv CommImpl* $(baseline)
	$(asdgen) -l cpp examples/Aap.asd && mv AapInt* NootComp* $(baseline)
	$(asdgen) -l cpp examples/Alarm.asd && mv Alarm* $(baseline)
	$(asdgen) -l cpp examples/Console.asd && mv Console* $(baseline)
	$(asdgen) -l cpp examples/Sensor.asd && mv Sensor* $(baseline)
	$(asdgen) -l cpp examples/Siren.asd && mv Siren* $(baseline)
	$(asdgen) -l csp examples/Alarm.asd && mv Alarm.csp $(baseline)

check: ast pretty c++

ast:
	./gaiag examples/interface-enums.asd
	./gaiag examples/interface-events.asd
	./gaiag examples/interface-reply-events.asd
	./gaiag examples/interface-behaviour.asd
	./gaiag examples/interface-imports.asd
	./gaiag examples/alarm-component.asd

pretty:
	guile -L ../.. --language=asd -s examples/interface-enums.asd | indent
	./gaiag -l asd examples/interface-enums.asd | indent
	./gaiag -l asd examples/alarm-component-pretty.asd | indent | tee pretty.asd && $(diff) examples/alarm-component-pretty.asd pretty.asd

c++: baseline
	./gaiag -l c++ examples/Alarm.asd
	-$(diff) $(baseline)/AlarmComponent.h .
	-$(diff) $(baseline)/AlarmComponent.cpp .
	./gaiag examples/Aap.asd
	./gaiag -l c++ examples/Aap.asd
	[ -f $(baseline)/NootComponent.h ] && $(diff) $(baseline)/NootComponent.h .
	-[ -f $(baseline)/NootComponent.cpp ] && $(diff) $(baseline)/NootComponent.cpp .  | $(sed)
#	./gaiag -l c++ examples/CommImpl.asd
#	[ -f $(baseline)/CommImplComponent.h ] && $(diff) $(baseline)/CommImplComponent.h .
#	-[ -f $(baseline)/CommImplComponent.cpp ] && $(diff) $(baseline)/CommImplComponent.cpp .

test:
	./gaiag -l c++ examples/Console.asd
	$(diff) $(baseline)/ConsoleInterface.h .
	./gaiag -l c++ examples/Sensor.asd
	$(diff) $(baseline)/SensorInterface.h .
	./gaiag -l c++ examples/Siren.asd
	$(diff) $(baseline)/SirenInterface.h .
	./gaiag -l c++ examples/Alarm.asd
	$(diff) $(baseline)/AlarmComponent.h .
	$(diff) $(baseline)/AlarmComponent.cpp . | $(sed)
	g++ -I ../../examples/codegen/asd_cpp_runtime --std=c++11 -c AlarmComponent.cpp

match:
	guile -L ../.. ./match.scm

wfc: compile
	-./gaiag -l wfc examples/double-on.asd
	#-./gaiag -l wfc examples/double-on-compound.asd #TODO
	-./gaiag -l wfc examples/mixing.asd 

csp: compile
	./gaiag -l csp examples/Alarm.asd && cat Alarm.csp
	$(diff) $(baseline)/Alarm.csp .
