# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

TARG := gaiag
FRST :=\
  gaiag/module/system/base/lalr.scm\
  gaiag/module/language/dezyne/location.scm\
  gaiag/module/language/dezyne/parse.scm\
  gaiag/module/language/dezyne/tokenize.scm\
  gaiag/module/language/dezyne/spec.scm\

GUILE_LIB_PREFIX := /usr/share/guile/site
GUILE_LIB_FILES :=\
 os/process.scm\
 compat/guile-2.scm\

MODULE_SRCS := $(filter %.scm,$(shell git ls-files $(CDIR)/module))
#MODULE_SRCS := $(filter %.scm,$(shell git ls-files $(CDIR)/module | grep -Ev 'module/g/|module/gr/' ))
SRCS := $(filter-out $(FRST),$(GUILE_LIB_SRCS) $(MODULE_SRCS))

CLEAN:=$(CLEAN) $(BUILD)/module $(HOME)/.cache/guile

$(BUILD)/module:
	ln -s $(shell pwd)/gaiag/module $(BUILD)/module

include make/guile.mk

TARG := scm2json
include make/guile.mk

TARG := json2scm
include make/guile.mk

TEST := $(TEST) $(CDIR)-check

$(CDIR)-check: CDIR:=$(CDIR)
$(CDIR)-check:
	cd $(CDIR) && GUILE_AUTO_COMPILE=0 GUILE_LOAD_COMPILED_PATH=$(shell cd $(BUILD) && pwd)/ccache ./test.sh

include make/check.mk
