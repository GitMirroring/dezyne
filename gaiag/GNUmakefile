# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2014 Jan Nieuwenhuizen <jan@avatar.nl>
# Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
DEPTH = ..
TOPDIR = $(shell cd $(DEPTH) && pwd)
diff = diff -uw -I '^ *$$' -I '^ *//'
sed = sed -e 's/^-gen/gen/' -re 's/((cppbase.cpp|.hh.scm|.cc.scm):[0-9]*):/\1:warning:/'
BUILD = build
asdgen = ASD_PREFIX=$(DEPTH)/.. $(DEPTH)/../$(BUILD)/asdgenerator
FDR3_PREFIX=/usr/local/
GUILE = guile
SCRIPTS = coverage gaiag json2scm scm2json
SCM_SOURCES = $(shell git ls-files module test-suite/*.scm)
CSPMCHECKER = $(FDR3_PREFIX)/bin/cspmchecker
REFINES =  $(FDR3_PREFIX)/bin/refines --brief --quiet --format=plain
PREFIX = $(abspath $(shell pwd))
GUILE_LOAD_PATH = $(PREFIX):$(PREFIX)/module

-include .local.make

default: all

all: compile wfc ast pretty c++ csp simulate check

tags:
	etags $(shell git ls-files)

compile:
	$(GUILE) $(PREFIX)/module/language/asd/spec.scm

compile-all: clean
#	make -C .. PROJECTS=gaiag GUILE='$(GUILE) --debug' BUILD=build-debug VERBOSE=
	$(GUILE) $(PREFIX)/module/language/asd/spec.scm
	for i in $(SCRIPTS); do $(GUILE) $$i; done
	for i in $(SCM_SOURCES); do $(GUILE) $$i; done

clean:
	rm -rf ~/.cache/guile out

test: check
check: compile
	./test.sh </dev/null
	$(MAKE) csp asserts c++ demo pretty

coverage: clean
	@echo GUILE_LOAD_PATH=$(GUILE_LOAD_PATH)
	rm -rf gaiag.lcov && mkdir -p gaiag.lcov
	cd gaiag.lcov && ln -s ../examples ../templates .
	$(MAKE) GUILE='guile --debug' compile-all
	GUILE='guile --debug --no-auto-compile' ./test.sh --coverage </dev/null
	lcov -r gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-test.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/regression/Alarm.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/regression/function.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-function.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/regression/imperative.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-imperative.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/regression/argument2.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-argument2.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/regression/Typedef.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-Typedef.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/regression/Alarm.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-csp.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/regression/if.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-if.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/regression/function.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-function.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/regression/Comp.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-Comp.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/regression/expressions.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-expressions.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/regression/Alarm.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/regression/AlarmSystem.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-AlarmSystem.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/Aap.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-Aap.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/regression/expressions.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-expressions.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/regression/argument2.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-argument2.info | grep -v Removing

	cd gaiag.lcov && ! ../coverage gaiag -l wfc examples/regression/double-on.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-wfc-double-on.info | grep -v Removing

	cd gaiag.lcov && ! ../coverage gaiag -l wfc examples/regression/mixing.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-wfc-mixing.info | grep -v Removing

	rm gaiag.lcov/gaiag.info
	genhtml --output-dir=gaiag.lcov --prefix=$(shell pwd) gaiag.lcov/gaiag*.info
	make clean # junk debug cache

dummy:

ast: compile
	./gaiag examples/regression/interface-enums.asd
	./gaiag examples/regression/interface-events.asd
	./gaiag examples/regression/interface-reply-events.asd
	./gaiag examples/regression/interface-behaviour.asd
	./gaiag examples/regression/interface-imports.asd
	./gaiag examples/regression/alarm-component.asd

pretty: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	./gaiag -l asd examples/regression/interface-enums.asd > out/interface-enums.asd
	$(diff) baseline/interface-enums.asd out
	./gaiag -l asd examples/regression/alarm-component.asd > out/alarm-component.asd
	$(diff) baseline/alarm-component.asd out
	./gaiag -l asd examples/regression/function.asd > out/function.asd
	$(diff) baseline/function.asd out
	./gaiag -l asd examples/regression/argument2.asd > out/argument2.asd
	$(diff) baseline/argument2.asd out
	./gaiag -l asd examples/regression/Typedef.asd > out/Typedef.asd
	$(diff) baseline/Typedef.asd out
	./gaiag -l asd examples/regression/expressions.asd > out/expressions.asd
	$(diff) baseline/expressions.asd out

c++: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ../gaiag -l c++ examples/regression/Alarm.asd
	$(diff) baseline/component-Alarm-c3.hh out
	$(diff) baseline/component-Alarm-c3.cc out
	cd out && ../gaiag examples/Aap.asd
	cd out && ../gaiag -l c++ examples/Aap.asd
	$(diff) baseline/component-Noot-c3.hh out
	$(diff) baseline/component-Noot-c3.cc out

	cd out && ../gaiag -l c++ examples/regression/Console.asd
	$(diff) baseline/interface-Console-c3.hh out
	cd out && ../gaiag -l c++ examples/regression/Sensor.asd
	$(diff) baseline/interface-Sensor-c3.hh out
	cd out && ../gaiag -l c++ examples/regression/Siren.asd
	$(diff) baseline/interface-Siren-c3.hh out
	cd out && ../gaiag -l c++ examples/regression/Alarm.asd
	$(diff) baseline/component-Alarm-c3.hh out
	$(diff) baseline/component-Alarm-c3.cc out
	cd out && g++ -I ../$(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c component-Alarm-c3.cc

	#system
	cd out && ../gaiag -l c++ examples/regression/AlarmSystem.asd
	$(diff) baseline/component-Sensor-c3.hh out
	$(diff) baseline/component-Sensor-c3.cc out
	$(diff) baseline/component-Siren-c3.hh out
	$(diff) baseline/component-Siren-c3.cc out
	$(diff) baseline/component-AlarmSystem-c3.hh out
	$(diff) baseline/component-AlarmSystem-c3.cc out
	-cd out && g++ -I ../$(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c component-AlarmSystem-c3.cc

	cd out && ../gaiag -l c++ examples/regression/argument2.asd
	$(diff) baseline/component-argument2-c3.hh out
	$(diff) baseline/component-argument2-c3.cc out
	$(diff) baseline/component-argument2-c3.hh out
	-$(diff) baseline/component-argument2-c3.cc out

	cd out && ../gaiag -l c++ examples/regression/expressions.asd
	$(diff) baseline/component-expressions-c3.hh out
	-$(diff) baseline/component-expressions-c3.cc out
	cd out && g++ -I ../$(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c component-expressions-c3.cc

wfc: compile
	-./gaiag -l wfc examples/regression/double-on.asd
	#-./gaiag -l wfc examples/regression/double-on-compound.asd #TODO
	-./gaiag -l wfc examples/regression/mixing.asd

csp: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out

	cd out && ../gaiag -l csp examples/regression/Alarm.asd
	$(diff) baseline/Alarm.csp out || true
	@$(diff) baseline/Alarm.csp out | diffstat || true
	$(CSPMCHECKER) out/Alarm.csp
	! $(REFINES) out/Alarm.csp | grep ': Failed'
	@$(diff) baseline/Alarm.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/imperative.asd
	$(diff) baseline/imperative.csp out || true
	@$(diff) baseline/imperative.csp out | diffstat || true
	$(CSPMCHECKER) out/imperative.csp
	! $(REFINES) out/imperative.csp | grep ': Failed'
	@$(diff) baseline/imperative.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/Reply.asd
	$(diff) baseline/Reply.csp out || true
	@$(diff) baseline/Reply.csp out | diffstat || true
	$(CSPMCHECKER) out/Reply.csp
	! $(REFINES) out/Reply.csp | grep ': Failed'
	@$(diff) baseline/Reply.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/function.asd
	$(diff) baseline/function.csp out || true
	@$(diff) baseline/function.csp out | diffstat || true
	$(CSPMCHECKER) out/function.csp
	! $(REFINES) out/function.csp | grep ': Failed'
	@$(diff) baseline/function.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/argument.asd
	$(diff) baseline/argument.csp out || true
	@$(diff) baseline/argument.csp out | diffstat || true
	$(CSPMCHECKER) out/argument.csp
	! $(REFINES) out/argument.csp | grep ': Failed'
	@$(diff) baseline/argument.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/Reply2.asd
	$(diff) baseline/Reply2.csp out || true
	@$(diff) baseline/Reply2.csp out | diffstat || true
	$(CSPMCHECKER) out/Reply2.csp
	! $(REFINES) out/Reply2.csp | grep ': Failed'
	@$(diff) baseline/Reply2.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/sugar.asd
	$(diff) baseline/sugar.csp out || true
	@$(diff) baseline/sugar.csp out | diffstat || true
	$(CSPMCHECKER) out/sugar.csp
	! $(REFINES) out/sugar.csp | grep ': Failed'
	@$(diff) baseline/sugar.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/Comp.asd
	$(diff) baseline/Comp.csp out
	@$(diff) baseline/Comp.csp out | diffstat || true
	$(CSPMCHECKER) out/Comp.csp
	! $(REFINES) out/Comp.csp | grep ': Failed'
	@$(diff) baseline/Comp.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/argument2.asd
	$(diff) baseline/argument2.csp out || true
	@$(diff) baseline/argument2.csp out | diffstat
	$(CSPMCHECKER) out/argument2.csp
	! $(REFINES) out/argument2.csp | grep ': Failed'
	@$(diff) baseline/argument2.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/hide.asd
	$(diff) baseline/hide.csp out || true
	@$(diff) baseline/hide.csp out | diffstat
	$(CSPMCHECKER) out/hide.csp
	! $(REFINES) out/hide.csp | grep ': Failed'
	@$(diff) baseline/hide.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/expressions.asd
	$(diff) baseline/expressions.csp out || true
	@$(diff) baseline/expressions.csp out | diffstat
	$(CSPMCHECKER) out/expressions.csp
	! $(REFINES) out/expressions.csp | grep ': Failed'
	@$(diff) baseline/expressions.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/testBoolean.asd
	$(diff) baseline/testBoolean.csp out || true
	@$(diff) baseline/testBoolean.csp out | diffstat
	$(CSPMCHECKER) out/testBoolean.csp
	! $(REFINES) out/testBoolean.csp | grep ': Failed'
	@$(diff) baseline/testBoolean.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/mangle.asd
	$(diff) baseline/mangle.csp out || true
	@$(diff) baseline/mangle.csp out | diffstat
	$(CSPMCHECKER) out/mangle.csp
	! $(REFINES) out/mangle.csp | grep ': Failed'
	@$(diff) baseline/mangle.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/livelock1.asd
	$(diff) baseline/livelock1.csp out || true
	@$(diff) baseline/livelock1.csp out | diffstat
	$(CSPMCHECKER) out/livelock1.csp
	$(REFINES) out/livelock1.csp |& grep ': Failed'
	@$(diff) baseline/livelock1.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/livelock2.asd
	$(diff) baseline/livelock2.csp out || true
	@$(diff) baseline/livelock2.csp out | diffstat
	$(CSPMCHECKER) out/livelock2.csp
	$(REFINES) out/livelock2.csp |& grep ': Failed'
	@$(diff) baseline/livelock2.csp out >/dev/null

livelock:
	rm -rf out && mkdir out && ln -s ../examples ../templates $(DEPTH)/../webdemo/asd out
	cd out && ../gaiag -l csp examples/regression/livelock1.asd
	$(diff) baseline/livelock1.csp out || true
	@$(diff) baseline/livelock1.csp out | diffstat
	$(CSPMCHECKER) out/livelock1.csp
	$(REFINES) out/livelock1.csp |& grep ': Failed'
	@$(diff) baseline/livelock1.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/livelock2.asd
	$(diff) baseline/livelock2.csp out || true
	@$(diff) baseline/livelock2.csp out | diffstat
	$(CSPMCHECKER) out/livelock2.csp
	$(REFINES) out/livelock2.csp |& grep ': Failed'
	@$(diff) baseline/livelock2.csp out >/dev/null

mangle: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out

	cd out && ../gaiag -l csp examples/regression/mangle.asd
	$(diff) baseline/mangle.csp out || true
	@$(diff) baseline/mangle.csp out | diffstat
	./gaiag -l mangle examples/regression/mangle.asd
	$(CSPMCHECKER) out/mangle.csp
	@$(diff) baseline/mangle.csp out >/dev/null

	cd out && ../gaiag -l csp examples/regression/argument2.asd
	$(diff) baseline/argument2.csp out || true
	@$(diff) baseline/argument2.csp out | diffstat
	./gaiag -l manglex examples/regression/argument2.asd
	$(CSPMCHECKER) out/argument2.csp
	@$(diff) baseline/argument2.csp out >/dev/null

simulate: compile
#	./gaiag -l simulate examples/regression/if.asd
	./gaiag -l simulate -t '(a a a)' examples/regression/simulate.asd
	./gaiag -l simulate -t '(a a a a a)' examples/regression/if.asd
#	./gaiag -l simulate examples/regression/Alarm.asd |& grep '^\*\*' | wc -l
#	./gaiag -l simulate -t "$(shell cat examples/regression/Alarm-trail.scm)" examples/regression/Console.asd | ./scm2json | sed -e "s/, /,\n /g"
	./gaiag -l simulate -t "$(shell cat examples/regression/Alarm-trail.scm)" examples/regression/alarm-component.asd
	./gaiag -l simulate -t "$(shell cat examples/regression/Alarm-trail.scm)" -j examples/regression/alarm-component.asd | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '(i.e i.e i.e)' examples/regression/arguments.asd
	./gaiag -l simulate -t '(client.initialize result_t.OK result_t.OK client.perform_actions result_t.OK result_t.OK client.perform_actions result_t.NOK client.recover result_t.OK client.perform_actions)' examples/regression/Comp.asd


alarm-gen:
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ln -s ../examples/regression/main.cc .
	cd out && for file in examples/regression/AlarmSystem.asd examples/regression/Alarm.asd \
                              examples/regression/Console.asd examples/regression/Sensor.asd examples/regression/Siren.asd; \
                  do ../gaiag -l c++ $$file; done

alarm: alarm-gen
	g++ -Wall -Wextra out/*.cc -o out/test && ./out/test

alarm-legacy: alarm-gen
	rm out/component-Alarm-c3.cc
	cd out && ln -s ../alarm_legacy/* .
	g++ -g -Wall -Wextra out/*.c* -o out/test && ./out/test

BROKEN =\
 asdConcepts_Behaviour.asd\
 asdConcepts_Composition.asd\
 SystemComposition.asd\
 exampleLOPW.asd\
 Aap.asd\

DEMO_SOURCES = $(filter-out $(BROKEN) ,$(shell cd $(DEPTH)/webdemo/asd && ls *.asd))
#EXAMPLE_SOURCES = $(filter-out $(BROKEN) ,$(shell cd examples && ls *.asd))
EXAMPLE_SOURCES =\
 function.asd\
 argument.asd\
 argument2.asd\


out/%.refines: $(DEPTH)/webdemo/asd/%.asd
	rm -rf out && mkdir out && ln -s ../examples ../webdemo ../templates ../$(DEPTH)/webdemo/asd out
	cd out && $(asdgen) -l scm asd/$*.asd
	cd out && ../gaiag -l csp $*.scm
	[ -f out/$*.csp ] || mv out/*.csp out/$*.csp
	$(diff) webdemo/$*.csp out || true
	@$(diff) webdemo/$*.csp out | diffstat
	$(CSPMCHECKER) out/$*.csp
	$(REFINES) out/$*.csp | grep ': Failed' || :
	@$(diff) webdemo/$*.csp out >/dev/null
	touch $@

out/%.refines: examples/regression/%.asd
	rm -rf out && mkdir out && ln -s ../examples ../webdemo ../templates ../$(DEPTH)/webdemo/asd out
	cd out && $(asdgen) -l scm examples/regression/$*.asd
	cd out && ../gaiag -l csp $*.scm
	[ -f out/$*.csp ] || mv out/*.csp out/$*.csp
	$(diff) webdemo/$*.csp out || true
	@$(diff) webdemo/$*.csp out | diffstat
	$(CSPMCHECKER) out/$*.csp
	$(REFINES) out/$*.csp | grep ': Failed' || :
	@$(diff) webdemo/$*.csp out >/dev/null
	touch $@

demo: $(EXAMPLE_SOURCES:%.asd=out/%.refines) $(DEMO_SOURCES:%.asd=out/%.refines)

asserts:
	rm -rf out && mkdir out && ln -s ../examples ../webdemo ../templates ../$(DEPTH)/webdemo/asd out
	./gaiag -l asserts examples/regression/Alarm.asd > out/alarm-asserts.scm
	$(diff) baseline/alarm-asserts.scm out

compare:
	rm -rf out && mkdir out && ln -s ../examples ../webdemo ../templates ../$(DEPTH)/webdemo/asd out
	make -C ../..
	./gaiag -l resolve examples/regression/trip.asd > out/gaiag-trip.scm
	cd out && ../$(DEPTH)/build/asdgenerator -l scm examples/trip.asd
	sed -i 's/i[0-9]\+_//g' out/trip.scm
	./gaiag out/trip.scm > out/om-trip-pretty.scm
#	guile -c '(use-modules (ice-9 pretty-print)) (pretty-print (read))' < out/trip.scm > out/om-trip-pretty.scm
	-@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm
	@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm | diffstat
	@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm > /dev/null
