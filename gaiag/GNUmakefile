# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2014 Rob Wieringa <Rob.Wieringa@verum.com>
# Copyright © 2014 Jan Nieuwenhuizen <jan@avatar.nl>
# Copyright © 2014, 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
# Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
GUILE = guile
SCRIPTS = coverage gaiag json2scm scm2json
SCM_SOURCES = $(shell cd module git ls-files)
SCM_TEST_SOURCES = $(shell cd test-suite git ls-files)
CSPMCHECKER = cspmchecker
REFINES = fdr2 batch
TRANSIT = transit
PREFIX = $(abspath $(shell pwd))
GUILE_LOAD_PATH = $(PREFIX):$(PREFIX)/module
GUILE_FLAGS := $(patsubst %,-L %, $(subst :, ,$(GUILE_LOAD_PATH)))
PYTHON = PYTHONPATH= python
WFC = true
#WFC = $(TOPDIR)/$(BUILD)/asdgenerator

default: all

all: compile

tags:
	etags $(shell git ls-files)

compile:
	$(GUILE) $(GUILE_FLAGS) module/language/dezyne/spec.scm

compile-all: clean
#	make -C .. PROJECTS=gaiag GUILE='$(GUILE) --debug' BUILD=build-debug VERBOSE=
	$(GUILE) $(GUILE_FLAGS) module/language/dezyne/spec.scm
	for i in $(SCRIPTS); do $(GUILE) $(GUILE_FLAGS) $$i; done
	for i in $(SCM_SOURCES); do $(GUILE) $(GUILE_FLAGS) $$i; done
	for i in $(SCM_TEST_SOURCES); do $(GUILE) $(GUILE_FLAGS) $$i; done

clean:
	rm -rf ~/.cache/guile out

test: check
check: compile
	./test.sh </dev/null
	$(MAKE) csp asserts c c++ pretty loc goops java javascript python simulate wfc

REGRESSION_SOURCES = $(shell cd examples/regression && ls *.dzn)
WFC_SOURCES = $(shell cd examples/wfc && ls -1 *.dzn)

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
	lcov -r gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o gaiag.lcov/gaiag-test.info | grep -v Removing

gaiag.lcov/%-dzn.info: examples/regression/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l dezyne $< >/dev/null
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-csp.info: examples/regression/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l csp $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-c.info: examples/regression/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l c $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-c++.info: examples/regression/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l c++ $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-python.info: examples/regression/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l python $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-javascript.info: examples/regression/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ../gaiag --coverage -l javascript $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

gaiag.lcov/%-wfc.info: examples/wfc/%.dzn
	rm -f gaiag.lcov/gaiag.info
	cd gaiag.lcov && ! ../gaiag --coverage -l wfc $<
	sed -i s@:[.][.]/@:$(shell pwd)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/gaiag $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*pretty-print.scm \*gaiag/coverage -o $@ | grep -v Removing

cover-regression:\
 $(REGRESSION_SOURCES:%.dzn=gaiag.lcov/%-dzn.info)\
 $(REGRESSION_SOURCES:%.dzn=gaiag.lcov/%-csp.info)\
 $(REGRESSION_SOURCES:%.dzn=gaiag.lcov/%-c++.info)\
 gaiag.lcov/Alarm-javascript.info\
 gaiag.lcov/Alarm-python.info\

# $(WFC_SOURCES:%.dzn=gaiag.lcov/%-wfc.info)\

dummy:

ast: compile
	./gaiag examples/interface-enums.dzn
	./gaiag examples/interface-events.dzn
	./gaiag examples/interface-reply-events.dzn
	./gaiag examples/interface-behaviour.dzn
	./gaiag examples/interface-imports.dzn
	./gaiag examples/alarm-component.dzn

pretty: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	./gaiag -l dezyne examples/interface-enums.dzn > out/interface-enums.dzn
	$(diff) examples/interface-enums.dzn out
	./gaiag -l dezyne examples/alarm-component.dzn > out/alarm-component.dzn
	$(diff) examples/alarm-component.dzn out
	./gaiag -l dezyne examples/Typedef.dzn > out/Typedef.dzn
	$(diff) examples/Typedef.dzn out

	./gaiag -l dezyne examples/regression/function.dzn > out/function.dzn
	$(diff) examples/regression/function.dzn out
	./gaiag -l dezyne examples/regression/argument2.dzn > out/argument2.dzn
	$(diff) examples/regression/argument2.dzn out
	./gaiag -l dezyne examples/regression/expressions.dzn > out/expressions.dzn
	$(diff) examples/regression/expressions.dzn out

alarm: c-alarm c++-alarm goops-alarm java-alarm javascript-alarm python-alarm
dataparam: c-dataparam c++-dataparam goops-dataparam javascript-dataparam
inject: c-inject c++-inject

c++-alarm-update:
	-$(MAKE) c++-alarm
	cp out/*cc out/*hh baseline

c++-choice-update:
	-$(MAKE) c++-choice
	cp out/*cc out/*hh baseline

c++-dataparam-update:
	-$(MAKE) c++-dataparam
	cp out/*cc out/*hh baseline

c++-inject-update:
	-$(MAKE) c++-inject
	cp out/*cc out/*hh baseline

c-alarm-update:
	-$(MAKE) c-alarm
	cp out/*c out/*h baseline

c-dataparam-update:
	-$(MAKE) c-dataparam
	cp out/*c out/*h baseline

c-inject-update:
	-$(MAKE) c-inject
	cp out/*c out/*h baseline


goops-alarm-update:
	 -$(MAKE) goops-alarm
	cp out/*dezyne/*scm baseline

goops-dataparam-update:
	 -$(MAKE) goops-dataparam
	cp out/*dezyne/*scm baseline


javascript-alarm-update:
	 -$(MAKE) javascript-alarm
	cp out/*dezyne/*js baseline

javascript-dataparam-update:
	 -$(MAKE) javascript-dataparam
	cp out/*dezyne/*js baseline


java-alarm-update:
	 -$(MAKE) java-alarm
	cp out/*dezyne/*java baseline


python-alarm-update:
	 -$(MAKE) python-alarm
	cp out/*dezyne/*py baseline

code: alarm out/Reply7.o out/Reply7.java out/Reply7.js out/Reply7.py

# c
c: compile c-alarm c-inject c-dataparam c-regression

c-alarm:
	rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c/* .
	cd out && for file in\
		examples/Alarm.dzn\
		examples/IConsole.dzn\
		examples/ISensor.dzn\
		examples/Sensor.dzn\
		examples/ISiren.dzn\
		examples/Siren.dzn\
		examples/AlarmComponentSystem.dzn\
		;\
	do $(shell pwd)/../build/asdgenerator -l scm $$file && $(shell pwd)/gaiag -l c $$(basename $$file .dzn).scm; done
	#do $(shell pwd)/gaiag -l c $$file; done
	cd out && ln -s ../examples/alarm.c .
	#cp baseline/{AlarmSystem,Alarm,Sensor,Siren}.{h,c} out
	#cp baseline/{IConsole,ISensor,ISiren}.h out
	for i in out/*c; do ccache gcc -g -std=c99 -Wall -pedantic -pedantic-errors -c $$i -o out/$$(basename $$i .c).o; done && gcc -o out/$@ out/*.o && out/$@ > out/$@.trace
	$(diff) baseline/$@.trace out
	for i in out/*.h out/*.c; do $(diff) baseline/$$(basename $$i) $$i; done

c-dataparam:
	rm -rf out && mkdir out && cd out && ln -s ../runtime/c/* .
	cd out && ../gaiag -l c ../examples/regression/Dataparam.dzn
	cd out && ln -sf ../examples/dataparam.c .
	for i in out/*c; do ccache gcc -g -std=c99 -Wall -pedantic -pedantic-errors -c $$i -o out/$$(basename $$i .c).o; done && gcc -o out/$@ out/*.o && out/$@ > out/$@.trace
	$(diff) baseline/$@.trace out
	for i in out/*.h out/*.c; do $(diff) baseline/$$(basename $$i) $$i; done

c-inject:
	rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c/* .
	cd out && ln -s ../examples/injected.c .
	cd out && $(shell pwd)/gaiag -l c examples/Injected.dzn
	for i in out/*c; do ccache gcc -g -std=c99 -Wall -pedantic -pedantic-errors -c $$i -o out/$$(basename $$i .c).o; done && gcc -o out/$@ out/*.o && out/$@ > out/$@.trace
	for i in out/*.h out/*.c; do $(diff) baseline/$$(basename $$i) $$i; done
	$(diff) baseline/$@.trace out

#out/%.c: examples/regression/%.dzn
define .C_REGRESSION
rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c/* .
cd out && $(shell pwd)/gaiag -l c examples/regression/$*.dzn
-$(diff) baseline/$*.h out
-$(diff) baseline/$*.c out
ccache gcc -std=c99 -Wall -pedantic -pedantic-errors -o out/$*.o -c out/$*.c $(UPDATE)
@$(diff) baseline/$*.h out >/dev/null
@$(diff) baseline/$*.c out >/dev/null
endef

C_BROKEN =\
 Alarm.dzn\
 Noot.dzn\
 hide.dzn\
 livelock1.dzn\
 livelock2.dzn\
 mangle.dzn\

C_SOURCES = $(filter-out $(C_BROKEN),$(shell cd examples/regression && grep -l ^component *.dzn))

#out/%.c.up: UPDATE=||:; cp out/$*.c out/*.h baseline
out/%.c.up: UPDATE=&& cp out/$*.c out/*.h baseline
out/%.c.up: examples/regression/%.dzn
	$(.C_REGRESSION)

out/%.c: examples/regression/%.dzn
	$(.C_REGRESSION)

c-regression: $(C_SOURCES:%.dzn=out/%.c)
c-update: $(C_SOURCES:%.dzn=out/%.c.up) c-alarm-update c-inject-update c-dataparam-update

# c++
c++: compile c++-alarm glue c++-inject c++-dataparam c++-choice c++-regression

c++-alarm:
	rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c++/* .
	cd out && for file in\
		examples/AlarmSystem.dzn\
		examples/regression/Alarm.dzn\
		examples/IConsole.dzn\
		examples/ISensor.dzn\
		examples/Sensor.dzn\
		examples/ISiren.dzn\
		examples/Siren.dzn\
		;\
	do $(shell pwd)/gaiag -l c++ $$file; done
	cd out && ln -s ../examples/alarm.cc .
	for i in out/*cc; do ccache g++ -std=c++11 -g -Wall -Wextra -c -o out/$$(basename $$i .cc).o $$i; done && g++ -o out/$@ out/*.o && out/$@ |& sed -e s/0[^:]*://g | grep -Ev '^(|0 )0x' >out/$@.trace
	$(diff) baseline/$@.trace out
	for i in out/*.hh out/*.cc; do $(diff) baseline/$$(basename $$i) $$i; done

c++-inject:
	rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c++/* .
	cd out && ln -s ../examples/injected.cc .
	cd out && $(shell pwd)/gaiag -l c++ examples/Injected.dzn
	for i in out/*cc; do ccache g++ -std=c++11 -g -Wall -Wextra -c -o out/$$(basename $$i .cc).o $$i; done && g++ -o out/$@ out/*.o && out/$@ |& sed -e s/0[^:]*://g | grep -Ev '^(|0 )0x' >out/$@.trace
	-$(diff) baseline/$@.trace out # FIXME

c++-dataparam:
	rm -rf out && mkdir out && cd out && ln -s ../runtime/c++/* .
	cd out && ../gaiag -l c++ ../examples/regression/Dataparam.dzn
	cd out && ln -sf ../examples/dataparam.cc .
	for i in out/*cc; do ccache g++ -std=c++11 -g -Wall -Wextra -c -o out/$$(basename $$i .cc).o $$i; done && g++ -o out/$@ out/*.o && out/$@ |& sed -e s/0[^:]*://g | grep -Ev '^(|0 )0x' >out/$@.trace
	$(diff) baseline/$@.trace out
	for i in out/*.hh out/*.cc; do $(diff) baseline/$$(basename $$i) $$i; done

c++-choice:
	rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c++/* .
	cd out && $(shell pwd)/gaiag -l c++ examples/regression/Choice.dzn
	ln -s ../../webapp/server/commands/runtime/c++/main.cc out
	for i in out/*cc; do ccache g++ -std=c++11 -g -Wall -Wextra -c -o out/$$(basename $$i .cc).o $$i; done && g++ -o out/$@ out/*.o && out/$@ |& sed -e s/0[^:]*://g | grep -Ev '^(|0 )0x' >out/$@.trace
	$(diff) baseline/$@.trace out
	$(diff) baseline/Choice.cc out

#out/%.c++: examples/regression/%.dzn
define .CC_REGRESSION
rm -rf out && mkdir out && cd out && ln -s ../examples ../templates ../runtime/c++/* .
cd out && $(shell pwd)/gaiag -l c++ examples/regression/$*.dzn
-$(diff) baseline/$*.hh out
-$(diff) baseline/$*.cc out
ccache g++ -std=c++11 -o out/$*.o -c out/$*.cc $(UPDATE)
@$(diff) baseline/$*.hh out >/dev/null
@$(diff) baseline/$*.cc out >/dev/null
endef

CC_BROKEN =\
 Alarm.dzn\
 Noot.dzn\
 hide.dzn\
 livelock1.dzn\
 livelock2.dzn\
 mangle.dzn\

CC_SOURCES = $(filter-out $(CC_BROKEN),$(shell cd examples/regression && grep -l ^component *.dzn))

#out/%.c++.up: UPDATE=||:; cp out/$*.cc out/*.hh baseline
out/%.c++.up: UPDATE=&& cp out/$*.cc out/*.hh baseline
out/%.c++.up: examples/regression/%.dzn
	$(.CC_REGRESSION)

out/%.c++: examples/regression/%.dzn
	$(.CC_REGRESSION)

c++-regression: $(CC_SOURCES:%.dzn=out/%.c++)
c++-update: $(CC_SOURCES:%.dzn=out/%.c++.up) c++-alarm-update c++-choice-update c++-inject-update c++-dataparam-update

out/%.wfc: examples/wfc/%.dzn
	! ./gaiag -l wfc $<

wfc: compile $(WFC_SOURCES:%.dzn=out/%.wfc)

define .REGRESSION_REFINES
rm -rf out && mkdir -p out && ln -s ../examples ../templates out
cd out && $(WFC) $< && $(shell pwd)/gaiag -l csp $<
$(diff) baseline/$*.csp out || true
@$(diff) baseline/$*.csp out | diffstat || true
$(CSPMCHECKER) out/$*.csp
$(REFINES) out/$*.csp 2>/dev/null > $@ 2>/dev/null ||:
$(diff) -I '^Checking' baseline/$*.refines $@ $(UPDATE)
@$(diff) baseline/$*.csp out >/dev/null
endef

#out/%.update: UPDATE=||:; cp out/$*.update baseline/$*.refines; cp out/$*.csp baseline/
out/%.update: UPDATE=&& cp out/$*.csp baseline/
out/%.update: examples/regression/%.dzn
	$(.REGRESSION_REFINES)

out/%.refines: examples/regression/%.dzn
	$(.REGRESSION_REFINES)

define .WEBDEMO_REFINES
rm -rf out && mkdir -p out/webdemo && ln -s ../../$(DEPTH)/webapp/server/commands ../../templates out/webdemo && ln -s commands/examples out/webdemo/examples && ln -s commands out/webdemo/webdemo && ln -s ../$(DEPTH)/webapp out
cd out/webdemo && $(TOPDIR)/$(BUILD)/asdgenerator -M -l scm $<
cd out/webdemo && $(shell pwd)/gaiag -l csp $*.scm
[ -f out/webdemo/$*.csp ] || mv out/webdemo/*.csp out/webdemo/$*.csp
$(diff) baseline/webdemo/$*.csp out/webdemo || true
@$(diff) baseline/webdemo/$*.csp out/webdemo | diffstat || true
$(CSPMCHECKER) out/webdemo/$*.csp
$(REFINES) out/webdemo/$*.csp > $@ 2>/dev/null ||:
$(diff) -I '^Checking' baseline/webdemo/$*.refines $@ $(UPDATE)
@$(diff) baseline/webdemo/$*.csp out/webdemo >/dev/null
endef

#out/webdemo/%.update: UPDATE=||:; cp out/webdemo/$*.update baseline/webdemo/$*.refines; cp out/webdemo/$*.csp baseline/webdemo/
out/webdemo/%.update: UPDATE=&& cp out/webdemo/$*.csp baseline/webdemo/
out/webdemo/%.update: $(DEPTH)/webapp/server/commands/examples/%.dzn
	$(.WEBDEMO_REFINES)

out/webdemo/%.refines: $(DEPTH)/webapp/server/commands/examples/%.dzn
	$(.WEBDEMO_REFINES)
out/webdemo/%.refines: examples/regression/%.dzn
	$(.WEBDEMO_REFINES)

define .ASSERT_REFINES
rm -rf out && mkdir -p out/assert && ln -s ../../examples ../templates ../../$(DEPTH)/examples/assert out/assert
ln -s assert out/examples
cd out/assert && $(TOPDIR)/$(BUILD)/asdgenerator -M -l scm $<
cd out/assert && $(shell pwd)/gaiag -l csp $*.scm
[ -f out/assert/$*.csp ] || mv out/assert/*.csp out/assert/$*.csp
$(diff) baseline/assert/$*.csp out/assert || true
@$(diff) baseline/assert/$*.csp out/assert | diffstat || true
$(CSPMCHECKER) out/assert/$*.csp
$(REFINES) out/assert/$*.csp > $@ 2>/dev/null ||:
$(diff) -I '^Checking' baseline/assert/$*.refines $@ $(UPDATE)
@$(diff) baseline/assert/$*.csp out/assert >/dev/null
endef

#out/assert/%.update: UPDATE=||:; cp out/assert/$*.update baseline/assert/$*.refines; cp out/assert/$*.csp baseline/assert
out/assert/%.update: UPDATE=&& cp out/assert/$*.csp baseline/assert/
out/assert/%.update: $(DEPTH)/examples/assert/%.dzn
	$(.ASSERT_REFINES)

out/assert/%.refines: $(DEPTH)/examples/assert/%.dzn
	$(.ASSERT_REFINES)

CSP_BROKEN=\
 provides_twice.dzn\

CSP_SOURCES = $(filter-out $(CSP_BROKEN),$(REGRESSION_SOURCES))

csp-regression: compile $(CSP_SOURCES:%.dzn=out/%.refines)

csp-regression-update: $(CSP_SOURCES:%.dzn=out/%.update)

BROKEN =\
 large-injection.dzn\

DEMO_SOURCES = $(filter-out $(BROKEN) ,$(shell cd $(DEPTH)/webapp/server/commands/examples && ls *.dzn))
csp-demo: $(DEMO_SOURCES:%.dzn=out/webdemo/%.refines)
csp-demo-update: $(DEMO_SOURCES:%.dzn=out/webdemo/%.update)

ASSERT_SOURCES = $(shell cd $(DEPTH)/examples/assert && ls *.dzn)
csp-assert: $(ASSERT_SOURCES:%.dzn=out/assert/%.refines)
csp-assert-update: $(ASSERT_SOURCES:%.dzn=out/assert/%.update)

csp: csp-regression csp-demo csp-assert
csp-update: csp-regression-update csp-assert-update csp-demo-update csp-assert-update

simulate: compile
	./gaiag -l simulate -t '(a a a)' examples/simulate.dzn
	./gaiag -l simulate -t '(a a a a a)' examples/regression/If.dzn
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/alarm-component.dzn
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" -j examples/alarm-component.dzn | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '(i.e i.e i.e)' examples/arguments.dzn
	./gaiag -l simulate -t '(client.initialize result_t.OK result_t.OK client.perform_actions result_t.OK result_t.OK client.perform_actions result_t.NOK client.recover result_t.OK client.perform_actions)' examples/regression/Comp.dzn

asserts:
	rm -rf out && mkdir out
	./gaiag -l asserts examples/regression/Alarm.dzn > out/alarm-asserts.scm
	$(diff) baseline/alarm-asserts.scm out

compare:
	rm -rf out && mkdir out && ln -s ../examples ../templates . out
	make -C ../..
	./gaiag -l resolve examples/regression/trip.dzn > out/gaiag-trip.scm
	cd out && ../$(DEPTH)/build/asdgenerator -l scm examples/trip.dzn
	sed -i 's/i[0-9]\+_//g' out/trip.scm
	./gaiag out/trip.scm > out/om-trip-pretty.scm
#	guile -c '(use-modules (ice-9 pretty-print)) (pretty-print (read))' < out/trip.scm > out/om-trip-pretty.scm
	-@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm
	@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm | diffstat || true
	@diff -uw out/om-trip-pretty.scm out/gaiag-trip.scm > /dev/null

python-alarm: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && $(shell pwd)/gaiag -l python examples/regression/Alarm.dzn
	cd out && $(shell pwd)/gaiag -l python examples/ISensor.dzn
	cd out && $(shell pwd)/gaiag -l python examples/ISiren.dzn
	cd out && $(shell pwd)/gaiag -l python examples/Alarm.dzn
	cd out && $(shell pwd)/gaiag -l python examples/AlarmSystem.dzn
	$(pydiff) baseline/IConsole.py out/dezyne
	$(pydiff) baseline/ISensor.py out/dezyne
	$(pydiff) baseline/ISiren.py out/dezyne
	$(pydiff) baseline/Alarm.py out/dezyne
	$(pydiff) baseline/AlarmSystem.py out/dezyne
	ln -s ../examples/Sensor.py out/dezyne
	ln -s ../examples/Siren.py out/dezyne
	ln -s ../examples/alarm.py out
	ln -s ../examples/__init__.py out/dezyne
	cd out && $(PYTHON) alarm.py

PY_BROKEN=\
 Dataparam.dzn\
 Extern.dzn\

PY_SOURCES = $(filter-out $(PY_BROKEN),$(CC_SOURCES))

define .PY_REGRESSION
rm -rf out && mkdir out && ln -s ../examples ../templates out
cd out && $(shell pwd)/gaiag -l python examples/regression/$*.dzn
-$(pydiff) baseline/$*.py out/dezyne
ln -s ../examples/__init__.py out/dezyne
(cd out && $(PYTHON) dezyne/$*.py) $(UPDATE)
$(pydiff) baseline/$*.py out/dezyne | diffstat || true
$(pydiff) baseline/$*.py out/dezyne > /dev/null
endef

#out/%.py.up: UPDATE=||:; cp out/dezyne/$*.py baseline && cp out/dezyne/*.py baseline
out/%.py.up: UPDATE=&& cp out/dezyne/$*.py baseline && cp out/dezyne/*.py baseline
out/%.py.up: examples/regression/%.dzn
	$(.PY_REGRESSION)

out/%.py: examples/regression/%.dzn
	$(.PY_REGRESSION)

python-regression: $(PY_SOURCES:%.dzn=out/%.py)
python-update: $(PY_SOURCES:%.dzn=out/%.py.up) python-alarm-update

python: compile python-alarm python-regression

JAVA_BROKEN =\
 Dataparam.dzn\
 Extern.dzn\
 hide.dzn\
 provides_twice.dzn\
 Reply5.dzn\

JAVA_SOURCES = $(filter-out $(JAVA_BROKEN),$(CC_SOURCES))

define .JAVA_REGRESSION
rm -rf out && mkdir out && ln -s ../examples ../templates out
cd out && $(WFC) $< && $(shell pwd)/gaiag -l java $<
-$(diff) baseline/$*.java out/dezyne
cat templates/java/header.java\
	 $$(find out/dezyne -name '*.java')\
	examples/alarm.java > $@
cat templates/java/header.java $$(find out/dezyne -name '*.java') > $@
cd $(dir $@) && cp -f --backup $(notdir $@) $*.java
(cd $(dir $@) && javac $*.java) $(UPDATE)
$(diff) baseline/$*.java out/dezyne | diffstat || true
@$(diff) baseline/$*.java out/dezyne > /dev/null
endef

#out/%.java.up: UPDATE=||:; cp out/dezyne/$*.java baseline && cp out/dezyne/*.java baseline
out/%.java.up: UPDATE=&& cp out/dezyne/$*.java baseline && cp out/dezyne/*.java baseline
out/%.java.up: examples/regression/%.dzn
	$(.JAVA_REGRESSION)

out/%.java: examples/regression/%.dzn
	$(.JAVA_REGRESSION)

java-regression: $(JAVA_SOURCES:%.dzn=out/%.java)
java-update: $(JAVA_SOURCES:%.dzn=out/%.java.up) java-alarm-update

java-alarm: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && for file in\
	 	examples/AlarmSystem.dzn\
	 	examples/regression/Alarm.dzn\
	 	examples/IConsole.dzn\
	 	examples/ISensor.dzn\
	 	examples/ISiren.dzn;\
	 	do $(shell pwd)/gaiag -l java $$file; done
	cat templates/java/header.java\
		 $$(find out/dezyne -name '*.java')\
		examples/alarm.java > out/alarm.java
	cd out && javac alarm.java
	cd out && java alarm
	$(diff) baseline/IConsole.java out/dezyne
	$(diff) baseline/ISensor.java out/dezyne
	$(diff) baseline/ISiren.java out/dezyne
	$(diff) baseline/Alarm.java out/dezyne
	$(diff) baseline/AlarmSystem.java out/dezyne

java: compile java-alarm java-regression

# javascript // js FIXME

javascript: compile javascript-alarm javascript-dataparam javascript-regression

JS_BROKEN=\
 Dataparam.dzn\
 Extern.dzn\

JS_SOURCES = $(filter-out $(JS_BROKEN),$(CC_SOURCES))

define .JAVASCRIPT_REGRESSION
rm -rf out && mkdir out && ln -s ../examples ../templates out
cd out && $(WFC) $< && $(shell pwd)/gaiag -l javascript $<
-$(diff) baseline/$*.js out/dezyne
cat runtime/javascript/header.js\
	 $$(find out/dezyne -name '*.js')\
	examples/alarm.js > $@
cat runtime/javascript/header.js $$(find out/dezyne -name '*.js') > $@
if [ -f node_modules/jshint/bin/jshint ]; then nodejs node_modules/jshint/bin/jshint $@; fi
nodejs $@ $(UPDATE)
$(diff) baseline/$*.js out/dezyne | diffstat || true
@$(diff) baseline/$*.js out/dezyne > /dev/null
endef

#out/%.js.up: UPDATE=||:; cp out/dezyne/$*.js baseline
out/%.js.up: UPDATE=&& cp out/dezyne/$*.js baseline
out/%.js.up: examples/regression/%.dzn
	$(.JAVASCRIPT_REGRESSION)

out/%.js: examples/regression/%.dzn
	$(.JAVASCRIPT_REGRESSION)

javascript-regression: $(JS_SOURCES:%.dzn=out/%.js)
javascript-update: $(JS_SOURCES:%.dzn=out/%.js.up) javascript-alarm-update javascript-dataparam-update

javascript-alarm: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && for file in\
	 	examples/AlarmSystem.dzn\
	 	examples/regression/Alarm.dzn\
	 	examples/IConsole.dzn\
	 	examples/ISensor.dzn\
	 	examples/ISiren.dzn;\
	 	do $(shell pwd)/gaiag -l javascript $$file; done
	cat runtime/javascript/header.js\
		 $$(find out/dezyne -name '*.js')\
		examples/alarm.js > out/alarm.js
	chmod +x out/alarm.js
	nodejs out/alarm.js 2> out/$@.trace
	$(diff) baseline/$@.trace out
	for i in out/dezyne/*.js; do $(diff) baseline/$$(basename $$i) $$i; done

javascript-dataparam: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ../gaiag -l javascript ../examples/regression/Dataparam.dzn
	cat runtime/javascript/header.js\
		 $$(find out/dezyne -name '*.js')\
		examples/dataparam.js > out/dataparam.js
	chmod +x out/dataparam.js
	nodejs out/dataparam.js 2> out/$@.trace
	$(diff) baseline/$@.trace out || echo '**********FIXME: semantics**********'
	for i in out/dezyne/*.js; do $(diff) baseline/$$(basename $$i) $$i; done

# goops

GOOPS_BROKEN=\
 Dataparam.dzn\
 Extern.dzn\

GOOPS_SOURCES = $(filter-out $(GOOPS_BROKEN),$(CC_SOURCES))

define .GOOPS_REGRESSION
rm -rf out && mkdir out && ln -s ../examples ../templates out
cd out && $(WFC) $< && $(shell pwd)/gaiag -l goops $<
-$(diff) baseline/$*.scm out/dezyne
cat templates/goops/header.scm\
	 $$(find out/dezyne -name '*.scm')\
	examples/alarm.scm > $@
cat templates/goops/header.scm $$(find out/dezyne -name '*.scm') > $@
guile $@ $(UPDATE)
$(diff) baseline/$*.scm out/dezyne | diffstat || true
@$(diff) baseline/$*.scm out/dezyne > /dev/null
endef

#out/%.scm.up: UPDATE=||:; cp out/dezyne/$*.scm baseline && cp out/dezyne/*.scm baseline
out/%.scm.up: UPDATE=&& cp out/dezyne/$*.scm baseline && cp out/dezyne/*.scm baseline
out/%.scm.up: examples/regression/%.dzn
	$(.GOOPS_REGRESSION)

out/%.scm: examples/regression/%.dzn
	$(.GOOPS_REGRESSION)

goops-regression: $(GOOPS_SOURCES:%.dzn=out/%.scm)
goops-update: $(GOOPS_SOURCES:%.dzn=out/%.scm.up) goops-alarm-update goops-dataparam-update

goops-alarm: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && for file in\
	 	examples/AlarmSystem.dzn\
	 	examples/regression/Alarm.dzn\
	 	examples/IConsole.dzn\
	 	examples/ISensor.dzn\
	 	examples/ISiren.dzn;\
	 	do $(shell pwd)/gaiag -l goops $$file; done
	cat templates/goops/header.scm\
		 $$(find out/dezyne -name '*.scm')\
		examples/alarm.scm > out/alarm.scm
	cd out && bash ./alarm.scm |& grep -v ^';' >$@.trace
	$(diff) baseline/$@.trace out
	for i in out/dezyne/*.scm; do $(diff) baseline/$$(basename $$i) $$i; done

goops-dataparam:

goops: compile goops-alarm goops-dataparam goops-regression

.PHONY: glue

glue:
	rm -rf out && mkdir -p out && cd out && ln -s ../examples ../../webapp/server/commands ../runtime/c++/* ../templates .
	cd out && for model in\
	 	AlarmSystem\
	 	Alarm\
	 	Console\
	 	Sensor\
	 	Siren;\
	 	do $(shell pwd)/gaiag -m $$model -l c++ commands/examples/AlarmSystem.dzn; done
	ln -sf examples/glue.cc out
	ln -sf examples/ISensorInterface.h out
	ln -sf examples/SensorComponent.h out
	ln -sf examples/SensorComponent.cpp out
	ln -sf examples/ISirenInterface.h out
	ln -sf examples/SirenComponent.h out
	ln -sf examples/SirenComponent.cpp out
	for i in out/*.c*; do ccache g++ -std=c++11 -g -Wall -Wextra -I out -I $(DEPTH)/examples/codegen/asd_cpp_runtime -c $$i -o out/$$(basename $$(basename $$i .cpp) .cc).o; done
	cd out && g++ -o test *.o && ./test
	ln -sf examples/AlarmComponent.h out
	ln -sf examples/IConsoleInterface.h out
	cd out && $(shell pwd)/gaiag -l c++ examples/ExternalAlarm.dzn
	g++ -std=c++11 -g -Wall -Wextra -I out -I $(DEPTH)/examples/codegen/asd_cpp_runtime -c out/glue-Alarm.cc -o out/glue-Alarm.o
	$(diff) baseline/glue-Alarm.cc out

code-update: c-update c++-update goops-update java-update javascript-update python-update
update: csp-update code-update

data-csp:
	cd out && ../gaiag -l csp ../examples/Dataparam.dzn
	$(CSPMCHECKER) out/Dataparam.csp
	cd out && ../../build/asdgenerator -l scm ../examples/Dataparam.dzn
	./gaiag out/Dataparam.scm > out/Dataparam-om.scm
	./gaiag examples/Dataparam.dzn > out/Dataparam.scm
	diff -uw out/Dataparam.scm out/Dataparam-om.scm

loc:
	make -C .. build/asdgenerator
	rm -rf out && mkdir -p out && cd out && ln -s ../examples .
	cd out && ../../build/asdgenerator -L -l scm examples/loc.dzn
	./gaiag out/loc.scm | sed -re 's@ [0-9]+[)]@ #f)@g' > out/om-loc.scm
	$(diff) baseline/om-loc.scm out/om-loc.scm
	./gaiag -l annotate examples/loc.dzn | sed -e s@[.]/@@g > out/loc.scm
	$(diff) baseline/loc.scm out/loc.scm
	./gaiag -j -l table out/om-loc.scm | ./scm2json | sed -e 's/,/,\n /g' > out/om-loc.json
	$(diff) baseline/om-loc.json out/om-loc.json
	./gaiag -j -l table examples/loc.dzn | ./scm2json | sed -e 's/,/,\n /g' > out/loc.json
	$(diff) baseline/loc.json out/loc.json

table:
	./gaiag -j -l table examples/table.dzn | ./scm2json | sed -e 's/,/,\n /g'
	@echo
	./gaiag -j -l table examples/ISiren.dzn | ./scm2json | sed -e 's/,/,\n /g'
#	@echo
#	./gaiag -l table examples/ISiren.dzn
	@echo
	./gaiag -m Alarm -j -l table examples/Alarm.dzn | ./scm2json | sed -e 's/, /,\n /g'
	@echo
	./gaiag -m SensorMultiplexer4 -l table ../webapp/server/commands/examples/choiceexample.dzn # | ./scm2json | sed -e 's/, /,\n /g'

lts/%.svg: ../webdemo/examples/%.dzn
	mkdir -p $(dir $@)
	for component in `grep -E '^component' $< | sed 's,^component \([^ ]*\).*,\1,'`; do \
	  if sed -e 's,^component,###component,' -e 's,^interface,###interface,' $< | tr -d '\n' | sed 's,###,\n,g'| grep -E "^component[ ]*$$component[^{]*{" | grep -q -E 'behaviour[ ]*{'; then \
	    ./gaiag --lts -m $$component -l csp -o lts/$(notdir $(basename $<)).csp $<; \
	    for process in `grep -E -o '^LTS_[^ =]*' lts/$(notdir $(basename $<)).csp`; do \
	      $(TRANSIT) -n lts/$(notdir $(basename $<)).csp $$process lts/$(notdir $(basename $<)).$$process.svg svg >&/dev/null; \
	    done; rm lts/$(notdir $(basename $<)).csp; \
	  fi; \
	done; \
	touch $@

lts: $(DEMO_SOURCES:%.dzn=lts/$(notdir %).svg)
