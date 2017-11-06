# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
# Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
# Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
# Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
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

SRCS := $(shell $(GIT_LS_FILES)\
  $(CDIR)/gash/*.scm\
  $(CDIR)/gaiag/*.scm\
  $(CDIR)/gaiag/*.scm.in\
  $(CDIR)/gaiag/deprecated/*.scm\
  $(CDIR)/gaiag/commands/*.scm\
  $(CDIR)/scmcrl2/*.scm\
)

SRCS := $(SRCS:%.scm.in=%.scm)
GOBJS := $(SRCS:%.scm=%.go)

$(CDIR)-clean: CDIR:=$(CDIR)
$(CDIR)-clean: GOBJS:=$(GOBJS)
$(CDIR)-clean: clean-go

include make/guile.mk

TARG := gdzn
include make/guile.mk

TARG := scm2json
include make/guile.mk

TARG := json2scm
include make/guile.mk

$(BIN)/gdzn: $(BIN)/generate

$(CDIR)-check: CDIR:=$(CDIR)
$(CDIR)-check: $(BUILD)/$(CDIR)
	@true

include make/check.mk
