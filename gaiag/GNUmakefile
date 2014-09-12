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
#asdgen = ASD_PREFIX=$(DEPTH)/.. $(DEPTH)/../$(BUILD)/asdgenerator
GUILE = guile
SCRIPTS = coverage gaiag json2scm scm2json
SCM_SOURCES = $(shell git ls-files module test-suite/*.scm)
CSPMCHECKER = cspmchecker
REFINES =  fdr2 batch
PREFIX = $(abspath $(shell pwd))
GUILE_LOAD_PATH = $(PREFIX):$(PREFIX)/module
GUILE_FLAGS := $(patsubst %,-L %, $(subst :, ,$(GUILE_LOAD_PATH)))

default: all

all: compile wfc ast pretty c++ csp simulate check

tags:
	etags $(shell git ls-files)

compile:
	$(GUILE) $(GUILE_FLAGS) module/language/asd/spec.scm

compile-all: clean
#	make -C .. PROJECTS=gaiag GUILE='$(GUILE) --debug' BUILD=build-debug VERBOSE=
	$(GUILE) $(GUILE_FLAGS) module/language/asd/spec.scm
	for i in $(SCRIPTS); do $(GUILE) $(GUILE_FLAGS) $$i; done
	for i in $(SCM_SOURCES); do $(GUILE) $(GUILE_FLAGS) $$i; done

clean:
	rm -rf ~/.cache/guile out

test: check
check: compile
	./test.sh </dev/null
	$(MAKE) csp asserts c++ demo mangle pretty

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
	./gaiag examples/interface-enums.asd
	./gaiag examples/interface-events.asd
	./gaiag examples/interface-reply-events.asd
	./gaiag examples/interface-behaviour.asd
	./gaiag examples/interface-imports.asd
	./gaiag examples/alarm-component.asd

pretty: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	./gaiag -l asd examples/interface-enums.asd > out/interface-enums.asd
	$(diff) examples/interface-enums.asd out
	./gaiag -l asd examples/alarm-component.asd > out/alarm-component.asd
	$(diff) examples/alarm-component.asd out
	./gaiag -l asd examples/Typedef.asd > out/Typedef.asd
	$(diff) examples/Typedef.asd out

	./gaiag -l asd examples/regression/function.asd > out/function.asd
	$(diff) examples/regression/function.asd out
	./gaiag -l asd examples/regression/argument2.asd > out/argument2.asd
	$(diff) examples/regression/argument2.asd out
	./gaiag -l asd examples/regression/expressions.asd > out/expressions.asd
	$(diff) examples/regression/expressions.asd out

c++: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && $(PWD)/gaiag -l c++ examples/regression/Alarm.asd
	$(diff) baseline/component-Alarm-c3.hh out
	$(diff) baseline/component-Alarm-c3.cc out
	cd out && $(PWD)/gaiag examples/Aap.asd
	cd out && $(PWD)/gaiag -l c++ examples/Aap.asd
	$(diff) baseline/component-Noot-c3.hh out
	$(diff) baseline/component-Noot-c3.cc out

	cd out && $(PWD)/gaiag -l c++ examples/Console.asd
	$(diff) baseline/interface-Console-c3.hh out
	cd out && $(PWD)/gaiag -l c++ examples/Sensor.asd
	$(diff) baseline/interface-Sensor-c3.hh out
	cd out && $(PWD)/gaiag -l c++ examples/Siren.asd
	$(diff) baseline/interface-Siren-c3.hh out
	cd out && $(PWD)/gaiag -l c++ examples/regression/Alarm.asd
	$(diff) baseline/component-Alarm-c3.hh out
	$(diff) baseline/component-Alarm-c3.cc out
	cd out && g++ -I ../$(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c component-Alarm-c3.cc

	#system
	cd out && $(PWD)/gaiag -l c++ examples/AlarmSystem.asd
	$(diff) baseline/component-Sensor-c3.hh out
	$(diff) baseline/component-Sensor-c3.cc out
	$(diff) baseline/component-Siren-c3.hh out
	$(diff) baseline/component-Siren-c3.cc out
	$(diff) baseline/component-AlarmSystem-c3.hh out
	$(diff) baseline/component-AlarmSystem-c3.cc out
	-cd out && g++ -I ../$(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c component-AlarmSystem-c3.cc

	cd out && $(PWD)/gaiag -l c++ examples/regression/argument2.asd
	$(diff) baseline/component-argument2-c3.hh out
	$(diff) baseline/component-argument2-c3.cc out
	$(diff) baseline/component-argument2-c3.hh out
	-$(diff) baseline/component-argument2-c3.cc out

	cd out && $(PWD)/gaiag -l c++ examples/regression/expressions.asd
	$(diff) baseline/component-expressions-c3.hh out
	-$(diff) baseline/component-expressions-c3.cc out
	cd out && g++ -I ../$(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c component-expressions-c3.cc

wfc: compile
	-./gaiag -l wfc examples/double-on.asd
	#-./gaiag -l wfc examples/double-on-compound.asd #TODO
	-./gaiag -l wfc examples/mixing.asd

REGRESSION_SOURCES = $(shell cd examples/regression && grep -l ^component *.asd)

out/%.refines: examples/regression/%.asd
	rm -rf out && mkdir -p out && ln -s ../examples ../webdemo ../templates ../$(DEPTH)/webdemo/asd out
	cd out && $(PWD)/gaiag -l csp $^
	$(diff) baseline/$*.csp out || true
	@$(diff) baseline/$*.csp out | diffstat || true
	$(CSPMCHECKER) out/$*.csp
	$(REFINES) out/$*.csp 2>/dev/null | grep -E '^x?false' || :
	@$(diff) baseline/$*.csp out >/dev/null
	touch $@

reply3: compile out/Reply3.refines

csp: compile $(REGRESSION_SOURCES:%.asd=out/%.refines)

livelock:
	rm -rf out && mkdir out && ln -s ../examples ../templates $(DEPTH)/../webdemo/asd out
	cd out && $(PWD)/gaiag -l csp examples/regression/livelock1.asd
	$(diff) baseline/livelock1.csp out || true
	@$(diff) baseline/livelock1.csp out | diffstat || true
	$(CSPMCHECKER) out/livelock1.csp
	$(REFINES) out/livelock1.csp |& grep -E '^x?false'
	@$(diff) baseline/livelock1.csp out >/dev/null

	cd out && $(PWD)/gaiag -l csp examples/regression/livelock2.asd
	$(diff) baseline/livelock2.csp out || true
	@$(diff) baseline/livelock2.csp out | diffstat || true
	$(CSPMCHECKER) out/livelock2.csp
	$(REFINES) out/livelock2.csp |& grep -E '^x?false'
	@$(diff) baseline/livelock2.csp out >/dev/null

mangle: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out

	cd out && $(PWD)/gaiag -l csp examples/regression/mangle.asd
	$(diff) baseline/mangle.csp out || true
	@$(diff) baseline/mangle.csp out | diffstat || true
	./gaiag -l mangle examples/regression/mangle.asd
	$(CSPMCHECKER) out/mangle.csp
	@$(diff) baseline/mangle.csp out >/dev/null

	cd out && $(PWD)/gaiag -l csp examples/regression/argument2.asd
	$(diff) baseline/argument2.csp out || true
	@$(diff) baseline/argument2.csp out | diffstat || true
	./gaiag -l mangle examples/regression/argument2.asd
	$(CSPMCHECKER) out/argument2.csp
	@$(diff) baseline/argument2.csp out >/dev/null

simulate: compile
#	./gaiag -l simulate examples/regression/if.asd
	./gaiag -l simulate -t '(a a a)' examples/simulate.asd
	./gaiag -l simulate -t '(a a a a a)' examples/regression/if.asd
#	./gaiag -l simulate examples/regression/Alarm.asd |& grep '^\*\*' | wc -l
#	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/regression/Console.asd | ./scm2json | sed -e "s/, /,\n /g"
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/alarm-component.asd
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" -j examples/alarm-component.asd | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '(i.e i.e i.e)' examples/arguments.asd
	./gaiag -l simulate -t '(client.initialize result_t.OK result_t.OK client.perform_actions result_t.OK result_t.OK client.perform_actions result_t.NOK client.recover result_t.OK client.perform_actions)' examples/regression/Comp.asd


alarm-gen:
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ln -s ../examples/regression/main.cc .
	cd out && for file in examples/regression/AlarmSystem.asd examples/regression/Alarm.asd \
                              examples/regression/Console.asd examples/regression/Sensor.asd examples/regression/Siren.asd; \
                  do $(PWD)/gaiag -l c++ $$file; done

alarm: alarm-gen
	g++ -Wall -Wextra out/*.cc -o out/test && ./out/test

alarm-legacy: alarm-gen
	rm out/component-Alarm-c3.cc
	cd out && ln -s ../alarm_legacy/* .
	g++ -g -Wall -Wextra out/*.c* -o out/test && ./out/test

BROKEN =\
 asdConcepts_Behaviour.asd\
 asdConcepts_Composition.asd\
 exampleLOPW.asd\
 Aap.asd\
 LOPW.asd\

DEMO_SOURCES = $(filter-out $(BROKEN) ,$(shell cd $(DEPTH)/webdemo/asd && ls *.asd))
#EXAMPLE_SOURCES = $(filter-out $(BROKEN) ,$(shell cd examples && ls *.asd))
EXAMPLE_SOURCES =\
 function.asd\
 argument.asd\
 argument2.asd\


out/webdemo/%.refines: $(DEPTH)/webdemo/asd/%.asd
	rm -rf out && mkdir -p out/webdemo && ln -s ../../examples ../../webdemo ../../templates ../../$(DEPTH)/webdemo/asd out/webdemo
	cd out/webdemo && $(TOPDIR)/$(BUILD)/asdgenerator -l scm asd/$*.asd
	cd out/webdemo && $(PWD)/gaiag -l csp $*.scm
	[ -f out/webdemo/$*.csp ] || mv out/webdemo/*.csp out/webdemo/$*.csp
	$(diff) baseline/webdemo/$*.csp out/webdemo || true
	@$(diff) baseline/webdemo/$*.csp out/webdemo | diffstat || true
	$(CSPMCHECKER) out/webdemo/$*.csp
	$(REFINES) out/webdemo/$*.csp 2>/dev/null | grep -E '^x?false' || :
	@$(diff) baseline/webdemo/$*.csp out/webdemo >/dev/null
	touch $@

out/webdemo/%.refines: examples/regression/%.asd
	rm -rf out && mkdir -p out/webdemo && ln -s ../../examples ../../webdemo ../../templates ../../$(DEPTH)/webdemo/asd out/webdemo
	cd out/webdemo && $(TOPDIR)/$(BUILD)/asdgenerator -l scm examples/regression/$*.asd
	cd out/webdemo && $(PWD)/gaiag -l csp $*.scm
	[ -f out/webdemo/$*.csp ] || mv out/webdemo/*.csp out/webdemo/$*.csp
	$(diff) baseline/webdemo/$*.csp out/webdemo || true
	@$(diff) baseline/webdemo/$*.csp out/webdemo | diffstat || true
	$(CSPMCHECKER) out/webdemo/$*.csp
	$(REFINES) out/webdemo/$*.csp 2>/dev/null | grep -E '^x?false' || :
	@$(diff) baseline/webdemo/$*.csp out/webdemo >/dev/null
	touch $@

demo: $(EXAMPLE_SOURCES:%.asd=out/webdemo/%.refines) $(DEMO_SOURCES:%.asd=out/webdemo/%.refines)

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
	@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm | diffstat || true
	@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm > /dev/null
