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
SRCS := $(filter %.scm,$(shell test -d .git && (git ls-files $(CDIR)/$(SUBM)json) || (find $(CDIR)/$(SUBM)json -name '*.scm')))
SRCS += $(filter %.scm,$(shell test -d .git && (git ls-files $(CDIR)/$(SUBM)*.scm) || (find $(CDIR)/$(SUBM) -maxdepth 1 -name '*.scm')))

include make/guile.mk

SRCS := $(filter %.scm,$(shell test -d .git && (git ls-files $(CDIR)/language) || find $(CDIR)/language))

include make/guile.mk

SRCS := $(filter %.scm,$(shell test -d .git && (git ls-files $(CDIR)/gaiag) || find $(CDIR)/gaiag))

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

include make/check.mk
