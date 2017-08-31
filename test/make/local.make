# Dezyne --- Dezyne command line tools
#
# Copyright © 2015, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

CURPATH:=$(shell echo $(CURDIR)/ | sed -e s,^.*/test/,,)
DEPTH:=$(shell echo $(CURPATH) | sed -re s,[^/]+/,../,g)
ifeq ($(DEPTH),)
DEPTH:=.
endif
PHONIES:=all check clean default force depend help list stress update
MAKE_SNIPPETS:=$(sort $(shell find . -name makefile.make))
MAKE_SNIPPETS:=$(MAKE_SNIPPETS:./%=$(CURPATH)%)
DIRECTORIES:=$(dir $(MAKE_SNIPPETS))
DIRECTORIES:=$(DIRECTORIES:$(notdir $(basename $(CURDIR)))/%/=%)
.PHONY: $(DIRECTORIES) $(PHONIES)
default: all
%:
	$(MAKE) -C $(DEPTH) MAKE_SNIPPETS="$(MAKE_SNIPPETS)" $(MAKEOVERRIDES) $@

$(DIRECTORIES):
	$(MAKE) -C $(DEPTH) MAKE_SNIPPETS="$(CURPATH)$@/makefile.make" $(MAKEOVERRIDES) check

$(PHONIES):
	$(MAKE) -C $(DEPTH) MAKE_SNIPPETS="$(MAKE_SNIPPETS)" $(MAKEOVERRIDES) $@
