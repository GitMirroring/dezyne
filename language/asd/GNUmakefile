# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
INDENT = ( cat > .$$$$; astyle -s2 -L < .$$$$; rm -f .$$$$)

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
	$(MAKE) pretty csp

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

	cd gaiag.lcov && ../coverage gaiag -l csp examples/pauls.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-pauls.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/Alarm.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++.info | grep -v Removing

	cd gaiag.lcov && ../coverage gaiag -l c++ examples/Aap.asd
	sed -i s@:[.][.]/@:$(PWD)/@ gaiag.lcov/gaiag.info
	lcov -r gaiag.lcov/gaiag.info /usr/share\* $(TOPDIR)/system/base\* \*pretty-print.scm -o gaiag.lcov/gaiag-c++-Aap.info | grep -v Removing

	rm gaiag.lcov/gaiag.info
	genhtml --output-dir=gaiag.lcov --prefix=$(shell cd ../.. && pwd) gaiag.lcov/gaiag*.info
	make clean # junk debug cache

dummy:

baseline: dummy
	rm -rf baseline && mkdir -p baseline
	cp examples/*asd baseline
	sed -rie 's/^(import .*);/\1.asd;/' baseline/*.asd
	cd baseline && $(asdgen) -l cpp alarm-component.asd
	cd baseline && $(asdgen) -l cpp CommImpl.asd
	cd baseline && $(asdgen) -l cpp Aap.asd
	cd baseline && $(asdgen) -l cpp Alarm.asd
	cd baseline && $(asdgen) -l cpp Console.asd
	cd baseline && $(asdgen) -l cpp Sensor.asd
	cd baseline && $(asdgen) -l cpp Siren.asd
	-cd baseline && $(asdgen) -l cpp AlarmSystem.asd # FIXME?
	cd baseline && $(asdgen) -l cpp $(DEPTH)/../examples/alarmsystem.asd
	cd baseline && $(asdgen) -l cpp webdemo.asd
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
	./gaiag -l asd examples/alarm-component.asd | $(INDENT) > out/alarm-component.asd 
	$(diff) examples/alarm-component.asd out
	./gaiag -l asd examples/function.asd | $(INDENT) > out/function.asd
	$(diff) examples/function.asd out
	./gaiag -l asd examples/argument2.asd | $(INDENT) > out/argument2.asd
	$(diff) examples/argument2.asd out
	./gaiag -l asd examples/Typedef.asd | $(INDENT) > out/Typedef.asd
	$(diff) examples/Typedef.asd out

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

	#system
	cd out && ../gaiag -l c++ examples/AlarmSystem.asd
	-$(diff) baseline/SensorComponent.h out
	-$(diff) baseline/SensorComponent.cpp out
	-$(diff) baseline/SirenComponent.h out
	-$(diff) baseline/SirenComponent.cpp out
	$(diff) baseline/AlarmSystemComponent.h out | $(sed)
	$(diff) baseline/AlarmSystemComponent.cpp out | $(sed)
	-cd out && g++ -I ../../../examples/codegen/asd_cpp_runtime --std=c++11 -c AlarmSystemComponent.cpp

wfc: compile
	-./gaiag -l wfc examples/double-on.asd
	#-./gaiag -l wfc examples/double-on-compound.asd #TODO
	-./gaiag -l wfc examples/mixing.asd

csp: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out

	cd out && ../gaiag -l csp examples/Alarm.asd
	$(diff) examples/Alarm.csp out || true
	@$(diff) examples/Alarm.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/Alarm.csp
	@$(diff) examples/Alarm.csp out >/dev/null

	cd out && ../gaiag -l csp examples/imperative.asd
	$(diff) examples/imperative.csp out || true
	@$(diff) examples/imperative.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/imperative.csp
	@$(diff) examples/imperative.csp out >/dev/null

	cd out && ../gaiag -l csp examples/Reply.asd
	$(diff) examples/Reply.csp out || true
	@$(diff) examples/Reply.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/Reply.csp
	@$(diff) examples/Reply.csp out >/dev/null

	cd out && ../gaiag -l csp examples/function.asd
	$(diff) examples/function.csp out || true
	@$(diff) examples/function.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/function.csp
	@$(diff) examples/function.csp out >/dev/null

	cd out && ../gaiag -l csp examples/argument.asd
	$(diff) examples/argument.csp out || true
	@$(diff) examples/argument.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/argument.csp
	@$(diff) examples/argument.csp out >/dev/null

	cd out && ../gaiag -l csp examples/Reply2.asd
	$(diff) examples/Reply2.csp out || true
	@$(diff) examples/Reply2.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/Reply2.csp
	@$(diff) examples/Reply2.csp out >/dev/null

	cd out && ../gaiag -l csp examples/sugar.asd
	$(diff) examples/sugar.csp out || true
	@$(diff) examples/sugar.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/sugar.csp
	@$(diff) examples/sugar.csp out >/dev/null

	cd out && ../gaiag -l csp examples/pauls.asd
	$(diff) examples/Comp.csp out
	@$(diff) examples/Comp.csp out | diffstat || true
	$(FDR3_PREFIX)/bin/cspmchecker out/Comp.csp
	@$(diff) examples/Comp.csp out >/dev/null

	cd out && ../gaiag -l csp examples/argument2.asd
	$(diff) examples/argument2.csp out || true
	@$(diff) examples/argument2.csp out | diffstat
	$(FDR3_PREFIX)/bin/cspmchecker out/argument2.csp
	@$(diff) examples/argument2.csp out >/dev/null

	cd out && ../gaiag -l csp examples/hide.asd
	$(diff) examples/hide.csp out || true
	@$(diff) examples/hide.csp out | diffstat
	$(FDR3_PREFIX)/bin/cspmchecker out/hide.csp
	@$(diff) examples/hide.csp out >/dev/null


	# cd out && ../gaiag -l csp examples/arguments.asd
	# $(diff) examples/arguments.csp out || true
	# @$(diff) examples/arguments.csp out | diffstat || true
	# @$(diff) examples/arguments.csp out >/dev/null
	# $(FDR3_PREFIX)/bin/cspmchecker out/arguments.csp

demo:
	rm -rf out && mkdir out && ln -s ../examples ../templates ../../../webdemo/asd out
	cd out && $(asdgen) -l scm examples/Reply.asd
	#sed -i -e 's/(type \([^.]+\)[.]\([^.()]+\))/(type \1 (type \2))/' out/Reply.scm
	cd out && ../gaiag -l csp Reply.scm
	$(diff) examples/Reply.csp out || true
	@$(diff) examples/Reply.csp out | diffstat || true
	-$(FDR3_PREFIX)/bin/cspmchecker out/Reply.csp

	cd out && $(asdgen) -l scm examples/Reply2.asd
	#sed -i -e 's/(type \([^.]+\)[.]\([^.()]+\))/(type \1 (type \2))/' out/Reply2.scm
	cd out && ../gaiag -l csp Reply2.scm
	$(diff) examples/Reply2.csp out || true
	@$(diff) examples/Reply2.csp out | diffstat || true
	-$(FDR3_PREFIX)/bin/cspmchecker out/Reply2.csp

	cd out && $(asdgen) -l scm asd/pauls.asd
	# sed -i -e 's/(type \([^.]+\)[.]\([^.()]+\))/(type \1 (type \2))/' out/pauls.scm
	cd out && ../gaiag -l csp pauls.scm
	-$(FDR3_PREFIX)/bin/cspmchecker out/Comp.csp

expression: compile
	rm -rf out && mkdir out && ln -s ../examples ../templates out
	cd out && ../gaiag -l csp examples/expressions.asd
	$(diff) examples/expressions.csp out || true
	@$(diff) examples/expressions.csp out | diffstat
	$(FDR3_PREFIX)/bin/cspmchecker out/expressions.csp
	@$(diff) examples/expressions.csp out >/dev/null

simulate: compile
#	./gaiag -l simulate examples/if.asd
	./gaiag -l simulate -t '(a a a)' examples/simulate.asd
	./gaiag -l simulate -t '(a a a a a)' examples/if.asd
#	./gaiag -l simulate examples/Alarm.asd |& grep '^\*\*' | wc -l
#	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/Console.asd | ./scm2json | sed -e "s/, /,\n /g"
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" examples/alarm-component.asd
	./gaiag -l simulate -t "$(shell cat examples/Alarm-trail.scm)" -j examples/alarm-component.asd | ./scm2json | sed -e 's/, /,\n /g'
	./gaiag -l simulate -t '(i.e i.e i.e)' examples/arguments.asd
	./gaiag -l simulate -t '(client.initialize result_t.OK result_t.OK client.perform_actions result_t.OK result_t.OK client.perform_actions result_t.NOK client.recover result_t.OK client.perform_actions)' examples/pauls.asd
