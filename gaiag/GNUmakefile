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
pydiff = diff -u -I '^ *$$' -I '^ *\#'
sed = sed -e 's/^-gen/gen/' -re 's/((cppbase.cpp|.hh.scm|.cc.scm):[0-9]*):/\1:warning:/'
BUILD = build
#asdgen = ASD_PREFIX=$(DEPTH)/.. $(DEPTH)/../$(BUILD)/asdgenerator
GUILE = guile
SCRIPTS = coverage gaiag json2scm scm2json
SCM_SOURCES = $(shell cd module git ls-files)
SCM_TEST_SOURCES = $(shell cd test-suite git ls-files)
CSPMCHECKER = cspmchecker
REFINES =  fdr2 batch
PREFIX = $(abspath $(shell pwd))
GUILE_LOAD_PATH = $(PREFIX):$(PREFIX)/module
GUILE_FLAGS := $(patsubst %,-L %, $(subst :, ,$(GUILE_LOAD_PATH)))

default: all

all: compile

tags:
	etags $(shell git ls-files)

compile:
	$(GUILE) $(GUILE_FLAGS) module/language/asd/spec.scm

compile-all: clean
#	make -C .. PROJECTS=gaiag GUILE='$(GUILE) --debug' BUILD=build-debug VERBOSE=
	$(GUILE) $(GUILE_FLAGS) module/language/asd/spec.scm
	for i in $(SCRIPTS); do $(GUILE) $(GUILE_FLAGS) $$i; done
	for i in $(SCM_SOURCES); do $(GUILE) $(GUILE_FLAGS) $$i; done
	for i in $(SCM_TEST_SOURCES); do $(GUILE) $(GUILE_FLAGS) $$i; done

clean:
	rm -rf ~/.cache/guile out

test: check
check: compile
	./test.sh </dev/null
	$(MAKE) csp asserts c++ demo pretty simulate wfc

REGRESSION_SOURCES = $(shell cd examples/regression && grep -l ^component *.asd)
WFC_SOURCES = $(shell cd examples/wfc && ls -1 *.asd)

coverage: clean cover-compile cover-test cover-regression
	rm gaiag.lcov/gaiag.info
	genhtml --output-dir=gaiag.lcov --prefix=$(shell pwd) gaiag.lcov/*.info
	make clean # junk debug cachep

xcover:  cover-compile cover-regression
	rm gaiag.lcov/gaiag.info
	genhtml --output-dir=gaiag.lcov --prefix=$(shell pwd) gaiag.lcov/*.info

cover-compile:
	@echo GUILE_LOAD_PATH=$(GUILE_LOAD_PATH)
	rm -rf gaiag.lcov && mkdir -p gaiag.lcov
	cd gaiag.lcov && ln -s ../examples ../templates .
	$(MAKE) GUILE='guile --debug' compile-all

cover-test:
	GUILE='guile --debug --no-auto-compile' ./test.sh --coverage </dev/null
	lcov -r gaiag.info /usr/share\* $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/module/language/\* $(TOPDIR)/gaiag/test-suite\*  \*pretty-print.scm \*gaiag/coverage -o gaiag.lcov/gaiag-test.info | grep -v Removing

gaiag.lcov/%-asd.info: examples/regression/%.asd
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l asd $< >/dev/null
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/module/language/\* $(TOPDIR)/gaiag/test-suite\*  \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-csp.info: examples/regression/%.asd
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l csp $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/module/language/\* $(TOPDIR)/gaiag/test-suite\*  \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-c++.info: examples/regression/%.asd
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l c++ $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/module/language/\* $(TOPDIR)/gaiag/test-suite\*  \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-wfc.info: examples/wfc/%.asd
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ! ../gaiag --coverage -l wfc $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/module/language/\* $(TOPDIR)/gaiag/test-suite\*  \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

cover-regression:\
 $(REGRESSION_SOURCES:%.asd=gaiag.lcov/%-asd.info)\
 $(REGRESSION_SOURCES:%.asd=gaiag.lcov/%-csp.info)\
 $(REGRESSION_SOURCES:%.asd=gaiag.lcov/%-c++.info)\

# $(WFC_SOURCES:%.asd=gaiag.lcov/%-wfc.info)\

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

out/%.compiles: examples/regression/%.asd
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && $(shell pwd)/gaiag -l c++ examples/regression/$*.asd
	$(diff) baseline/component-$*-c3.hh out
	$(diff) baseline/component-$*-c3.cc out
	ccache g++ -o out/component-$*-c3.o -c out/component-$*-c3.cc

out/%.compiles: examples/%.asd
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && $(shell pwd)/gaiag -l c++ examples/$*.asd
	$(diff) baseline/component-$*-c3.hh out
	$(diff) baseline/component-$*-c3.cc out
	ccache g++ -o out/component-$*-c3.o -c out/component-$*-c3.cc

CC_BROKEN =\
 Alarm.asd\
 Noot.asd\
 livelock1.asd\
 livelock2.asd\
 mangle.asd\

CC_SOURCES = $(filter-out $(CC_BROKEN),$(REGRESSION_SOURCES))

c++: compile c++-alarm alarm-gen alarm-legacy $(CC_SOURCES:%.asd=out/%.compiles)

c++-alarm:
	cd out && $(shell pwd)/gaiag -l c++ examples/regression/Alarm.asd
	cd out && $(shell pwd)/gaiag -l c++ examples/Sensor.asd
	cd out && $(shell pwd)/gaiag -l c++ examples/Siren.asd
	cd out && $(shell pwd)/gaiag -l c++ examples/Alarm.asd
	cd out && $(shell pwd)/gaiag -l c++ examples/AlarmSystem.asd
	$(diff) baseline/interface-Console-c3.hh out
	$(diff) baseline/interface-Sensor-c3.hh out
	$(diff) baseline/interface-Siren-c3.hh out
	$(diff) baseline/component-Alarm-c3.hh out
	$(diff) baseline/component-Alarm-c3.cc out
	$(diff) baseline/component-AlarmSystem-c3.hh out
	$(diff) baseline/component-AlarmSystem-c3.cc out
	ccache g++ -o out/boo -c out/component-Alarm-c3.cc
	ccache g++ -o out/boo -I $(DEPTH)/examples/regression/codegen/asd_cpp_runtime -c out/component-AlarmSystem-c3.cc

out/%.wfc: examples/wfc/%.asd
	! ./gaiag -l wfc $<

wfc: compile $(WFC_SOURCES:%.asd=out/%.wfc)

out/%.refines: examples/regression/%.asd
	rm -rf out && mkdir -p out && ln -s ../examples ../webdemo ../templates ../$(DEPTH)/webdemo/asd out
	cd out && $(shell pwd)/gaiag -l csp $^
	$(diff) baseline/$*.csp out || true
	@$(diff) baseline/$*.csp out | diffstat || true
	$(CSPMCHECKER) out/$*.csp
	$(REFINES) out/$*.csp 2>/dev/null | grep -E '^x?false' || :
	@$(diff) baseline/$*.csp out >/dev/null
	touch $@

CSP_BROKEN=\
 provides_twice.asd\

CSP_SOURCES = $(filter-out $(CSP_BROKEN),$(REGRESSION_SOURCES))
csp: compile $(CSP_SOURCES:%.asd=out/%.refines)

simulate: compile
#	./gaiag -l simulate examples/regression/if.asd
	./gaiag -l simulate -t '(a a a)' examples/simulate.asd
	./gaiag -l simulate -t '(a a a a a)' examples/regression/If.asd
#	./gaiag -l simulate examples/regression/Alarm.asd |& grep '^\*\*' | wc -l
#	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/regression/Console.asd | ./scm2json | sed -e "s/, /,\n /g"
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/alarm-component.asd
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" -j examples/alarm-component.asd | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '(i.e i.e i.e)' examples/arguments.asd
	./gaiag -l simulate -t '(client.initialize result_t.OK result_t.OK client.perform_actions result_t.OK result_t.OK client.perform_actions result_t.NOK client.recover result_t.OK client.perform_actions)' examples/regression/Comp.asd


alarm-gen:
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ln -s ../examples/main.cc .
	cd out && for file in\
		examples/AlarmSystem.asd\
		examples/regression/Alarm.asd\
		examples/Console.asd\
		examples/Sensor.asd\
		examples/Siren.asd;\
	do $(shell pwd)/gaiag -l c++ $$file; done

alarm: alarm-gen
	-ccache g++ -Wall -Wextra out/*.cc -o out/test && ./out/test

alarm-legacy: alarm-gen
	rm out/component-Alarm-c3.cc
	cd out && cp ../alarm_legacy/* .
	-ccache g++ -g -Wall -Wextra out/*.c* -o out/test && ./out/test

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
	cd out/webdemo && $(TOPDIR)/$(BUILD)/asdgenerator -M -l scm asd/$*.asd
	cd out/webdemo && $(shell pwd)/gaiag -l csp $*.scm
	[ -f out/webdemo/$*.csp ] || mv out/webdemo/*.csp out/webdemo/$*.csp
	$(diff) baseline/webdemo/$*.csp out/webdemo || true
	@$(diff) baseline/webdemo/$*.csp out/webdemo | diffstat || true
	$(CSPMCHECKER) out/webdemo/$*.csp
	$(REFINES) out/webdemo/$*.csp 2>/dev/null | grep -E '^x?false' || :
	@$(diff) baseline/webdemo/$*.csp out/webdemo >/dev/null
	touch $@

out/webdemo/%.refines: examples/regression/%.asd
	rm -rf out && mkdir -p out/webdemo && ln -s ../../examples ../../webdemo ../../templates ../../$(DEPTH)/webdemo/asd out/webdemo
	cd out/webdemo && $(TOPDIR)/$(BUILD)/asdgenerator -M -l scm examples/regression/$*.asd
	cd out/webdemo && $(shell pwd)/gaiag -l csp $*.scm
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

csp-update: csp-regression-update csp-demo-update

csp-regression-update: dummy
	while ! $(MAKE) csp; do cp out/*.csp baseline; done

csp-demo-update: dummy
	while ! $(MAKE) demo; do cp out/webdemo/*.csp baseline/webdemo; done

c++-update: dummy
	while ! $(MAKE) c++; do cp -pv out/*.hh out/*.cc baseline; done

glue:
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ln -s ../examples/main.cpp .
	cd out && for file in\
	 	examples/AlarmSystem.asd\
	 	examples/regression/Alarm.asd\
	 	examples/Console.asd\
	 	examples/Sensor.asd\
	 	examples/Siren.asd;\
	 	do $(shell pwd)/gaiag -l c++ $$file; done
	cd out && cp ../examples/component-Sensor-c3.cc .
	-cd out && ccache g++ -Wall -Wextra -I ../$(DEPTH)/examples/codegen/asd_cpp_runtime -c *.c*
	-cd out && g++ -o test *.o && ./test

out/%.py: examples/regression/%.asd
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && $(shell pwd)/gaiag -l python examples/regression/$*.asd
	-$(pydiff) baseline/component/$*.py out/component
	ln -s ../examples/__init__.py out/interface
	ln -s ../examples/__init__.py out/component
	cd out && python component/$*.py
	$(pydiff) baseline/component/$*.py out/component | diffstat || true
	$(pydiff) baseline/component/$*.py out/component > /dev/null

python-alarm: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && $(shell pwd)/gaiag -l python examples/regression/Alarm.asd
	cd out && $(shell pwd)/gaiag -l python examples/Sensor.asd
	cd out && $(shell pwd)/gaiag -l python examples/Siren.asd
	cd out && $(shell pwd)/gaiag -l python examples/Alarm.asd
	cd out && $(shell pwd)/gaiag -l python examples/AlarmSystem.asd
	$(pydiff) baseline/interface/Console.py out/interface
	$(pydiff) baseline/interface/Sensor.py out/interface
	$(pydiff) baseline/interface/Siren.py out/interface
	$(pydiff) baseline/component/Alarm.py out/component
	$(pydiff) baseline/component/AlarmSystem.py out/component
	ln -s ../examples/alarm.py out
	ln -s ../examples/__init__.py out/interface
	ln -s ../examples/__init__.py out/component
	cd out && python alarm.py

PY_BROKEN =\
 Alarm.asd\
 Noot.asd\
 livelock1.asd\
 livelock2.asd\
 mangle.asd\

PY_SOURCES = $(filter-out $(PY_BROKEN),$(REGRESSION_SOURCES))

python: compile python-alarm python-regression

python-regression: $(PY_SOURCES:%.asd=out/%.py)

python-update: dummy
	while ! $(MAKE) python-alarm; do\
		cp -pv out/interface/*py baseline/interface;\
		cp -pv out/component/*py baseline/component;\
	done
	while ! $(MAKE) python-regression; do\
		cp -pv out/interface/*py baseline/interface;\
		cp -pv out/component/*py baseline/component;\
	done
