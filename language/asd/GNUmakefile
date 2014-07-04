# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

SHELL := /bin/bash
DEPTH = ../..
diff = diff -uw -I '^ *$$' -I '^ *//'
sed = sed -e 's/^-gen/gen/' -re 's/((cppbase.cpp|.hh.scm|.cc.scm):[0-9]*):/\1:warning:/'
BUILD = build
asdgen = ASD_PREFIX=$(DEPTH) $(DEPTH)/$(BUILD)/asdgenerator

default: all

all: compile wfc ast pretty c++ csp simulate check

tags:
	etags $(shell git ls-files)

compile:
	guile -L ../.. spec.scm

clean:
	rm -rf ~/.cache/guile out baseline

dummy:

baseline: dummy
	rm -rf baseline && mkdir -p baseline
	cp examples/*asd baseline
	sed -rie 's/^(import .*);/\1.asd;/' baseline/*.asd
	$(asdgen) -l cpp baseline/alarm-component-pretty.asd && mv Alarm* baseline
	$(asdgen) -l cpp baseline/CommImpl.asd && mv CommImpl* baseline
	$(asdgen) -l cpp baseline/Aap.asd && mv AapInt* NootComp* baseline
	$(asdgen) -l cpp baseline/Alarm.asd && mv Alarm* baseline
	$(asdgen) -l cpp baseline/Console.asd && mv Console* baseline
	$(asdgen) -l cpp baseline/Sensor.asd && mv Sensor* baseline
	$(asdgen) -l cpp baseline/Siren.asd && mv Siren* baseline
	$(asdgen) -l csp baseline/Alarm.asd && mv Alarm.csp baseline

test: check
check: compile
	./test.sh </dev/null

ast: compile
	./gaiag examples/interface-enums.asd
	./gaiag examples/interface-events.asd
	./gaiag examples/interface-reply-events.asd
	./gaiag examples/interface-behaviour.asd
	./gaiag examples/interface-imports.asd
	./gaiag examples/alarm-component.asd

pretty: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	guile -L ../.. --language=asd -s examples/interface-enums.asd | indent
	./gaiag -l asd examples/interface-enums.asd | indent
	-./gaiag -l asd examples/alarm-component-pretty.asd | indent | tee out/pretty.asd && $(diff) examples/alarm-component-pretty.asd out/pretty.asd

c++: compile baseline
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ../gaiag -l c++ examples/Alarm.asd
	-$(diff) baseline/AlarmComponent.h out
	-$(diff) baseline/AlarmComponent.cpp out
	cd out && ../gaiag examples/Aap.asd
	cd out && ../gaiag -l c++ examples/Aap.asd
	[ -f baseline/NootComponent.h ] && $(diff) baseline/NootComponent.h out
	-[ -f baseline/NootComponent.cpp ] && $(diff) baseline/NootComponent.cpp out | $(sed)
#	cd out && ../gaiag -l c++ examples/CommImpl.asd
#	[ -f baseline/CommImplComponent.h ] && $(diff) baseline/CommImplComponent.h out
#	-[ -f baseline/CommImplComponent.cpp ] && $(diff) baseline/CommImplComponent.cpp out
	cd out && ../gaiag -l c++ examples/Console.asd
	$(diff) baseline/ConsoleInterface.h out
	cd out && ../gaiag -l c++ examples/Sensor.asd
	$(diff) baseline/SensorInterface.h out
	cd out && ../gaiag -l c++ examples/Siren.asd
	$(diff) baseline/SirenInterface.h out
	cd out && ../gaiag -l c++ examples/Alarm.asd
	$(diff) baseline/AlarmComponent.h out
	$(diff) baseline/AlarmComponent.cpp out | $(sed)
	cd out && g++ -I ../../../examples/codegen/asd_cpp_runtime --std=c++11 -c AlarmComponent.cpp

wfc: compile
	-./gaiag -l wfc examples/double-on.asd
	#-./gaiag -l wfc examples/double-on-compound.asd #TODO
	-./gaiag -l wfc examples/mixing.asd

csp: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ../gaiag -l csp examples/Alarm.asd
	$(diff) examples/Alarm.csp out
	@$(diff) examples/Alarm.csp out | diffstat || true
	cd out && ../gaiag -l csp examples/imperative.asd
	$(diff) examples/imperative.csp out || true
	@$(diff) examples/imperative.csp out | diffstat || true
	cd out && ../gaiag -l csp examples/reply.asd
	$(diff) examples/C.csp out || true
	@$(diff) examples/C.csp out | diffstat || true
#	cd out && ../gaiag -l csp examples/if.asd
#	$(diff) examples/if.csp out/C.csp

if: compile
	./gaiag examples/if.asd
	./gaiag -l pretty examples/if.asd | indent
	cd out && ../gaiag -l c++ examples/if.asd

simulate: compile
#	./gaiag -l simulate examples/if.asd
	./gaiag -l simulate -t '(a a a)' examples/simulate.asd
	./gaiag -l simulate -t '(a a a a a)' examples/if.asd
#	./gaiag -l simulate examples/Alarm.asd |& grep '^\*\*' | wc -l
#	./gaiag -l simulate -t '$(shell cat examples/Alarm-trail.scm)' examples/Console.asd | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '$(shell cat examples/Alarm-trail.scm)' examples/alarm-component.asd
	./gaiag -l simulate -t '$(shell cat examples/Alarm-trail.scm)' examples/alarm-component.asd | ./scm2json | sed -e 's/, /,\n /g'

log:
	make simulate | sed s'/, /,\n/g' > simulate$$$$.log
