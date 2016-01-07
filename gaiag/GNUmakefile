# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Henk Katerberg <henk.katerberg@yahoo.com>
# Copyright © 2014, 2015 Rob Wieringa <Rob.Wieringa@verum.com>
# Copyright © 2014 Jan Nieuwenhuizen <jan@avatar.nl>
# Copyright © 2014, 2015, 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
BUILD = build
GUILE = guile
SCRIPTS = coverage gaiag json2scm scm2json
SCM_SOURCES = $(shell cd module git ls-files)
SCM_TEST_SOURCES = $(shell cd test-suite git ls-files)
GAIAG_PREFIX = $(abspath $(shell pwd))
GUILE_LOAD_PATH = $(GAIAG_PREFIX):$(GAIAG_PREFIX)/module
GUILE_FLAGS := $(patsubst %,-L %, $(subst :, ,$(GUILE_LOAD_PATH)))

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
	rm -rf ~/.cache/guile out ../build/ccache

test: check
check: compile
	./test.sh </dev/null
#	$(MAKE) csp asserts c c++ pretty loc goops java javascript python run wfc

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
	cd gaiag.lcov && ../gaiag --coverage -l dzn $< >/dev/null
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
	cd gaiag.lcov && ../gaiag --coverage -l $(CXX) $<
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
