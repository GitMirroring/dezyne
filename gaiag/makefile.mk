# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
# Copyright © 2014 Henk Katerberg <henk.katerberg@yahoo.com>
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

SUBM := json/
SRCS := $(filter %.scm,$(shell $(GIT_LS_FILES) $(CDIR)/$(SUBM)json))
SRCS += $(filter $(CDIR)/$(SUBM)%.scm,$(shell $(GIT_LS_FILES) $(CDIR)/$(SUBM)*.scm))

include make/guile.mk

ifeq ($(GUILE_EFFECTIVE_VERSION),2.0)
$(shell rm -f $(CDIR)/system; ln -s 2.0/system $(CDIR)/system)
SRCS := $(filter %.scm,$(shell $(GIT_LS_FILES) $(CDIR)/system))

include make/guile.mk
else
$(shell rm -f $(CDIR)/system)
endif

SRCS := $(filter %.scm,$(shell $(GIT_LS_FILES) $(CDIR)/language))

include make/guile.mk

SRCS := $(filter %.scm,$(shell $(GIT_LS_FILES) $(CDIR)/gaiag))

CLEAN:=$(CLEAN) $(BUILD)/ccache $(HOME)/.cache/guile

TARG := gaiag
include make/guile.mk

TARG := scm2json
include make/guile.mk

TARG := json2scm
include make/guile.mk

TEST := $(TEST) $(CDIR)-check

$(CDIR)-check: CDIR:=$(CDIR)
$(CDIR)-check: $(BUILD)/$(CDIR)
	cd $(CDIR) && GUILE_AUTO_COMPILE=0 GUILE_LOAD_PATH=$(GLP) GUILE_LOAD_COMPILED_PATH=$(GLCP) ./test.sh

SUBM := test-suite/
SRCS := $(filter %.scm %.test,$(shell $(GIT_LS_FILES) $(CDIR)/test-suite))

include make/guile.mk

coverage: $(CDIR)-coverage

TOPDIR := $(shell pwd)
$(CDIR)-coverage: CDIR:=$(CDIR)
$(CDIR)-coverage: $(BUILD)/gaiag $(BUILD)/gaiag.lcov/gaiag.info

$(BUILD)/gaiag.lcov/gaiag.info: CDIR:=$(CDIR)
$(BUILD)/gaiag.lcov/gaiag.info:
	mkdir -p $(BUILD)/gaiag.lcov
	cd $(CDIR) && GUILE='guile --debug --no-auto-compile' ./test.sh --coverage < /dev/null
	mv $(CDIR)/gaiag.info $(BUILD)/gaiag.lcov

COVERAGE_REPORT:=$(BUILD)/gaiag.lcov/index.html
COVERAGE_INFOS:=$(wildcard $(BUILD)/gaiag.lcov/*.info)
COVERAGE_GAIAG:=$(COVERAGE_INFOS:%.info=%.info.gaiag)
$(COVERAGE_REPORT): $(COVERAGE_GAIAG)
	genhtml --output-dir=$(@D) --prefix=$(TOPDIR)/gaiag $^

coverage: $(COVERAGE_REPORT)

%.info.gaiag: %.info
	lcov -r $< /usr/share\* /gnu/store\* $(TOPDIR) $(TOPDIR)/gaiag/module/system/\* $(TOPDIR)/gaiag/test-suite\* \*gaiag/coverage -o $@ | grep -v Removing

include make/check.mk
