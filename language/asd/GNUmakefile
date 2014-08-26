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
DEPTH = ../..
TOPDIR = $(shell cd $(DEPTH) && pwd)
diff = diff -uw -I '^ *$$' -I '^ *//'
sed = sed -e 's/^-gen/gen/' -re 's/((cppbase.cpp|.hh.scm|.cc.scm):[0-9]*):/\1:warning:/'
BUILD = build
asdgen = ASD_PREFIX=$(DEPTH)/.. $(DEPTH)/../$(BUILD)/asdgenerator
FDR3_PREFIX=/usr/local/
GUILE = guile
SCRIPTS = coverage gaiag json2scm scm2json
SCM_SOURCES = $(shell git ls-files *.scm | grep -v 'templates')
CSPMCHECKER = $(FDR3_PREFIX)/bin/cspmchecker
REFINES =  $(FDR3_PREFIX)/bin/refines --brief --quiet --format=plain

-include .local.make

default: all

all: compile wfc ast pretty c++ csp simulate check

tags:
	etags $(shell git ls-files)

compile:
	$(GUILE) -L $(TOPDIR) spec.scm

compile-all: clean
	$(GUILE) -L $(TOPDIR) spec.scm
	for i in $(SCRIPTS); do $(GUILE) -L $(PWD) -L $(TOPDIR) $$i; done
	for i in $(SCM_SOURCES); do $(GUILE) -L $(PWD) -L $(TOPDIR) $$i; done

clean:
	rm -rf ~/.cache/guile out baseline

test: check
check: compile
	./test.sh </dev/null
	$(MAKE) pretty csp c++

coverage: clean
	rm -rf gaiag.lcov && mkdir -p gaiag.lcov
	cd gaiag.lcov && ln -s ../examples ../templates .
	$(MAKE) GUILE='guile --debug' compile-all
	GUILE='guile --debug --no-auto-compile' ./test.sh --coverage </dev/null
	lcov -r gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-test.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/Alarm.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/function.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-function.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/imperative.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-imperative.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/argument2.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-argument2.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l asd examples/Typedef.asd >/dev/null
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-asd-Typedef.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/Alarm.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-csp.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/if.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-if.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/function.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-function.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/Comp.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-Comp.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l csp examples/expressions.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-expressions.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/Alarm.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/AlarmSystem.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-AlarmSystem.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/Aap.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-Aap.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/expressions.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-expressions.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/argument2.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-argument2.info | grep -v Removing

	cd gaiag.lcov && ! ../coverage gaiag -l wfc examples/double-on.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-wfc-double-on.info | grep -v Removing

	cd gaiag.lcov && ! ../coverage gaiag -l wfc examples/mixing.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-wfc-mixing.info | grep -v Removing

	rm gaiag.lcov/gaiag.info
	genhtml --output-dir=gaiag.lcov --prefix=$(shell cd ../.. && pwd) gaiag.lcov/gaiag*.info
	make clean # junk debug cache

dummy:

baseline: dummy
	rm -rf baseline && mkdir -p baseline
	cp examples/*asd baseline
	sed -rie 's/^(import .*);/\1.asd;/' baseline/*.asd
	-cd baseline && $(asdgen) -l cpp AlarmSystem.asd # FIXME?
	cd baseline && $(asdgen) -l cpp $(DEPTH)/../examples/alarmsystem.asd
	cd baseline && $(asdgen) -l cpp alarm-component.asd
	cd baseline && $(asdgen) -l cpp CommImpl.asd
	cd baseline && $(asdgen) -l cpp Aap.asd
	cd baseline && $(asdgen) -l cpp Alarm.asd
	cd baseline && $(asdgen) -l cpp Console.asd
	cd baseline && $(asdgen) -l cpp Sensor.asd
	cd baseline && $(asdgen) -l cpp Siren.asd
	-cd baseline && $(asdgen) -l cpp argument2.asd
	-cd baseline && $(asdgen) -l cpp expressions.asd
	cd baseline && $(asdgen) -l csp Alarm.asd

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
	./gaiag -l asd examples/function.asd > out/function.asd
	$(diff) examples/function.asd out
	./gaiag -l asd examples/argument2.asd > out/argument2.asd
	$(diff) examples/argument2.asd out
	./gaiag -l asd examples/Typedef.asd > out/Typedef.asd
	$(diff) examples/Typedef.asd out
	./gaiag -l asd examples/expressions.asd > out/expressions.asd
	$(diff) examples/expressions.asd out

c++: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ../gaiag -l c++ examples/Alarm.asd
	$(diff) examples/component-Alarm-c3.hh out
	$(diff) examples/component-Alarm-c3.cc out
	cd out && ../gaiag examples/Aap.asd
	cd out && ../gaiag -l c++ examples/Aap.asd
	$(diff) examples/component-Noot-c3.hh out
	$(diff) examples/component-Noot-c3.cc out
#	cd out && ../gaiag -l c++ examples/CommImpl.asd
#	[ -f examples/component-CommImpl-c3.hh ] && $(diff) examples/component-CommImpl-c3.hh out
#	-[ -f examples/component-CommImpl-c3.cc ] && $(diff) examples/component-CommImpl-c3.cc out

	cd out && ../gaiag -l c++ examples/Console.asd
	$(diff) examples/interface-Console-c3.hh out
	cd out && ../gaiag -l c++ examples/Sensor.asd
	$(diff) examples/interface-Sensor-c3.hh out
	cd out && ../gaiag -l c++ examples/Siren.asd
	$(diff) examples/interface-Siren-c3.hh out
	cd out && ../gaiag -l c++ examples/Alarm.asd
	$(diff) examples/component-Alarm-c3.hh out
	$(diff) examples/component-Alarm-c3.cc out
	cd out && g++ -I ../../../examples/codegen/asd_cpp_runtime -c component-Alarm-c3.cc

	#system
	cd out && ../gaiag -l c++ examples/AlarmSystem.asd
	$(diff) examples/component-Sensor-c3.hh out
	$(diff) examples/component-Sensor-c3.cc out
	$(diff) examples/component-Siren-c3.hh out
	$(diff) examples/component-Siren-c3.cc out
	$(diff) examples/component-AlarmSystem-c3.hh out
	$(diff) examples/component-AlarmSystem-c3.cc out
	-cd out && g++ -I ../../../examples/codegen/asd_cpp_runtime -c component-AlarmSystem-c3.cc

	cd out && ../gaiag -l c++ examples/argument2.asd
	$(diff) examples/component-argument2-c3.hh out
	$(diff) examples/component-argument2-c3.cc out
	$(diff) examples/component-argument2-c3.hh out
	-$(diff) examples/component-argument2-c3.cc out

	cd out && ../gaiag -l c++ examples/expressions.asd
	$(diff) examples/component-expressions-c3.hh out
	-$(diff) examples/component-expressions-c3.cc out
	cd out && g++ -I ../../../examples/codegen/asd_cpp_runtime -c component-expressions-c3.cc

wfc: compile
	-./gaiag -l wfc examples/double-on.asd
	#-./gaiag -l wfc examples/double-on-compound.asd #TODO
	-./gaiag -l wfc examples/mixing.asd

csp: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out

	cd out && ../gaiag -l csp examples/Alarm.asd
	$(diff) examples/Alarm.csp out || true
	@$(diff) examples/Alarm.csp out | diffstat || true
	$(CSPMCHECKER) out/Alarm.csp
	! $(REFINES) out/Alarm.csp | grep ': Failed'
	@$(diff) examples/Alarm.csp out >/dev/null

	cd out && ../gaiag -l csp examples/imperative.asd
	$(diff) examples/imperative.csp out || true
	@$(diff) examples/imperative.csp out | diffstat || true
	$(CSPMCHECKER) out/imperative.csp
	! $(REFINES) out/imperative.csp | grep ': Failed'
	@$(diff) examples/imperative.csp out >/dev/null

	cd out && ../gaiag -l csp examples/Reply.asd
	$(diff) examples/Reply.csp out || true
	@$(diff) examples/Reply.csp out | diffstat || true
	$(CSPMCHECKER) out/Reply.csp
	! $(REFINES) out/Reply.csp | grep ': Failed'
	@$(diff) examples/Reply.csp out >/dev/null

	cd out && ../gaiag -l csp examples/function.asd
	$(diff) examples/function.csp out || true
	@$(diff) examples/function.csp out | diffstat || true
	$(CSPMCHECKER) out/function.csp
	! $(REFINES) out/function.csp | grep ': Failed'
	@$(diff) examples/function.csp out >/dev/null

	cd out && ../gaiag -l csp examples/argument.asd
	$(diff) examples/argument.csp out || true
	@$(diff) examples/argument.csp out | diffstat || true
	$(CSPMCHECKER) out/argument.csp
	! $(REFINES) out/argument.csp | grep ': Failed'
	@$(diff) examples/argument.csp out >/dev/null

	cd out && ../gaiag -l csp examples/Reply2.asd
	$(diff) examples/Reply2.csp out || true
	@$(diff) examples/Reply2.csp out | diffstat || true
	$(CSPMCHECKER) out/Reply2.csp
	! $(REFINES) out/Reply2.csp | grep ': Failed'
	@$(diff) examples/Reply2.csp out >/dev/null

	cd out && ../gaiag -l csp examples/sugar.asd
	$(diff) examples/sugar.csp out || true
	@$(diff) examples/sugar.csp out | diffstat || true
	$(CSPMCHECKER) out/sugar.csp
	! $(REFINES) out/sugar.csp | grep ': Failed'
	@$(diff) examples/sugar.csp out >/dev/null

	cd out && ../gaiag -l csp examples/Comp.asd
	$(diff) examples/Comp.csp out
	@$(diff) examples/Comp.csp out | diffstat || true
	$(CSPMCHECKER) out/Comp.csp
	! $(REFINES) out/Comp.csp | grep ': Failed'
	@$(diff) examples/Comp.csp out >/dev/null

	cd out && ../gaiag -l csp examples/argument2.asd
	$(diff) examples/argument2.csp out || true
	@$(diff) examples/argument2.csp out | diffstat
	$(CSPMCHECKER) out/argument2.csp
	! $(REFINES) out/argument2.csp | grep ': Failed'
	@$(diff) examples/argument2.csp out >/dev/null

	cd out && ../gaiag -l csp examples/hide.asd
	$(diff) examples/hide.csp out || true
	@$(diff) examples/hide.csp out | diffstat
	$(CSPMCHECKER) out/hide.csp
	! $(REFINES) out/hide.csp | grep ': Failed'
	@$(diff) examples/hide.csp out >/dev/null

	cd out && ../gaiag -l csp examples/expressions.asd
	$(diff) examples/expressions.csp out || true
	@$(diff) examples/expressions.csp out | diffstat
	$(CSPMCHECKER) out/expressions.csp
	! $(REFINES) out/expressions.csp | grep ': Failed'
	@$(diff) examples/expressions.csp out >/dev/null

	cd out && ../gaiag -l csp examples/testBoolean.asd
	$(diff) examples/testBoolean.csp out || true
	@$(diff) examples/testBoolean.csp out | diffstat
	$(CSPMCHECKER) out/testBoolean.csp
	! $(REFINES) out/testBoolean.csp | grep ': Failed'
	@$(diff) examples/testBoolean.csp out >/dev/null

	cd out && ../gaiag -l csp examples/mangle.asd
	$(diff) examples/mangle.csp out || true
	@$(diff) examples/mangle.csp out | diffstat
	$(CSPMCHECKER) out/mangle.csp
	! $(REFINES) out/mangle.csp | grep ': Failed'
	@$(diff) examples/mangle.csp out >/dev/null

	cd out && ../gaiag -l csp examples/livelock.asd
	$(diff) examples/livelock.csp out || true
	@$(diff) examples/livelock.csp out | diffstat
	$(CSPMCHECKER) out/livelock.csp
	$(REFINES) out/livelock.csp |& grep ': Failed'
	-$(REFINES) out/livelock.csp |& grep 'panic: '
	-@$(diff) examples/livelock.csp out >/dev/null

livelock:
	rm -rf out && mkdir out && ln -s ../examples ../templates ../../../webdemo/asd out
	cd out && ../gaiag -l csp examples/livelock.asd
	$(diff) examples/livelock.csp out || true
	@$(diff) examples/livelock.csp out | diffstat
	$(CSPMCHECKER) out/livelock.csp
	$(REFINES) out/livelock.csp |& grep 'panic: '
	@$(diff) examples/livelock.csp out >/dev/null

mangle: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out

	cd out && ../gaiag -l csp examples/mangle.asd
	$(diff) examples/mangle.csp out || true
	@$(diff) examples/mangle.csp out | diffstat
	./gaiag -l mangle examples/mangle.asd
	$(CSPMCHECKER) out/mangle.csp
	@$(diff) examples/mangle.csp out >/dev/null

	cd out && ../gaiag -l csp examples/argument2.asd
	$(diff) examples/argument2.csp out || true
	@$(diff) examples/argument2.csp out | diffstat
	./gaiag -l manglex examples/argument2.asd
	$(CSPMCHECKER) out/argument2.csp
	@$(diff) examples/argument2.csp out >/dev/null

simulate: compile
#	./gaiag -l simulate examples/if.asd
	./gaiag -l simulate -t '(a a a)' examples/simulate.asd
	./gaiag -l simulate -t '(a a a a a)' examples/if.asd
#	./gaiag -l simulate examples/Alarm.asd |& grep '^\*\*' | wc -l
#	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/Console.asd | ./scm2json | sed -e "s/, /,\n /g"
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/alarm-component.asd
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" -j examples/alarm-component.asd | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '(i.e i.e i.e)' examples/arguments.asd
	./gaiag -l simulate -t '(client.initialize result_t.OK result_t.OK client.perform_actions result_t.OK result_t.OK client.perform_actions result_t.NOK client.recover result_t.OK client.perform_actions)' examples/Comp.asd


alarm-gen:
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ln -s ../examples/main.cc .
	cd out && for file in examples/AlarmSystem.asd examples/Alarm.asd \
                              examples/Console.asd examples/Sensor.asd examples/Siren.asd; \
                  do ../gaiag -l c++ $$file; done

alarm: alarm-gen
	g++ -Wall -Wextra out/*.cc -o out/test && ./out/test

alarm-legacy: alarm-gen
	rm out/component-Alarm-c3.cc
	cd out && ln -s ../alarm_legacy/* .
	g++ -g -Wall -Wextra out/*.c* -o out/test && ./out/test
