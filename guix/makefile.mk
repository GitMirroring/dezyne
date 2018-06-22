# Dezyne --- Dezyne command line tools
#
# Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

SRCS := $(shell $(GIT_LS_FILES)\
  $(CDIR)/dezyne/*.scm\
  $(CDIR)/dezyne/*/*.scm\
)

SRCS := $(SRCS:%.scm.in=%.scm)
GOBJS := $(SRCS:%.scm=%.go)

$(CDIR)-clean: CDIR:=$(CDIR)
$(CDIR)-clean: GOBJS:=$(GOBJS)
$(CDIR)-clean: clean-go

all-go: all-go-$(CDIR)
clean-go: clean-go-$(CDIR)

all-go: all-go-$(CDIR)
clean-go: clean-go-$(CDIR)

include make/guile.mk
include make/reset.mk
