# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  gaiag/module/language/asd/parse.scm\
  gaiag/module/language/asd/tokenize.scm\
  gaiag/module/language/asd/spec.scm\

GUILE_LIB_PREFIX := /usr/share/guile/site
GUILE_LIB_FILES :=\
 os/process.scm\
 compat/guile-2.scm\

MODULE_SRCS := $(filter %.scm,$(shell git ls-files $(CDIR)/module))
SRCS := $(subst :,\:,$(filter-out $(FRST),$(GUILE_LIB_SRCS) $(MODULE_SRCS)))

include makeutils/guile.mk

TARG := scm2json
include makeutils/guile.mk

TARG := json2scm
include makeutils/guile.mk

TEST = $(BUILD)/$(CDIR).check

$(BUILD)/$(CDIR).check:
	cd $(CDIR) && make check

include makeutils/check.mk
