# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
# Copyright © 2015 Henk Katerberg <henk.katerberg@yahoo.com>
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

## common
.PHONY: bugs regression
.SECONDARY:
.SUFFIXES:
SHELL:=/bin/bash
DZN:=../webapp/client/dzn
OUT:=out
CCACHE:=$(shell type -p ccache)
#TRIANGLE_MAX:=cat
TRIANGLE_MAX:=head -50 # use `cat' for all
VERBOSE:=

DEFAULT_CODE_LANGUAGES:=c c++ c++03 cs goops javascript python
CODE_LANGUAGES:=$(DEFAULT_CODE_LANGUAGES)

JAVA:=$(strip $(shell /usr/bin/javac -version 2>&1 | grep -oe 'javac 1.8' >/dev/null && echo 8))
JAVA7:=$(strip $(shell /usr/bin/javac -version 2>&1 | grep -oe 'javac 1.[78]' >/dev/null && echo 7))

ifeq ($(DEFAULT_CODE_LANGUAGES),$(CODE_LANGUAGES))
ifneq ($(JAVA),)
CODE_LANGUAGES+=java
endif
ifneq ($(JAVA7),)
CODE_LANGUAGES+=java7
endif
endif

# PSEUDO_LANGUAGES=convert parse run table verify
PSEUDO_LANGUAGES=run table verify
ALL_LANGUAGES=$(CODE_LANGUAGES) $(PSEUDO_LANGUAGES)

# put your local overrides here, e.g.,
# DZN:=~/development.git/webapp/client/dzn
-include .local.make

default: check

help: help-common

define HELP_COMMON
Usage: make [OPTION]... [VARIABLE=VALUE]... [TARGET]...

Options:
  see make --help

Variables:
  DZN={dzn|~/development.git/webapp/client/dzn} [$(DZN)]
  ALL_LANGUAGES='...' [$(ALL_LANGUAGES)]
  CODE_LANGUAGES='...' [$(CODE_LANGUAGES)]
  OUT=<dir> [$(OUT)]
  VERBOSE={|debug|info} [$(VERBOSE)]

Targets:
  all            update everything
  check          run all checks
  clean          remove all generated stuff in $(OUT)
  smoke          quick smoke test
  update         overwrite all baselines
endef
export HELP_COMMON
help-common:
	@echo "$$HELP_COMMON"

all: $(OUT)/.gitignore

all: check
smoke: check
smoke-clean:
	rm -rf $(OUT)/alarm.project/{c,c++}

$(OUT)/.gitignore:
	mkdir -p $(OUT)
	echo '*' > $(OUT)/.gitignore

clean:
	rm -rf $(OUT)

ifeq ($(strip $(filter-out bugs clean help smoke smoke-clean,$(MAKECMDGOALS))),$(MAKECMDGOALS))
MAKE_SNIPPETS:=regression/makefile.make $(sort $(wildcard regression/*/makefile.make regression/*/*/makefile.make))
endif
ifeq ($(MAKECMDGOALS),smoke)
MAKE_SNIPPETS:=regression/alarm.project/makefile.make
CODE_LANGUAGES:=c c++
ALL_LANGUAGES:=$(CODE_LANGUAGES) run verify
endif
ifeq ($(strip $(filter bugs,$(MAKECMDGOALS:update-bugs=bugs))),bugs)
MAKE_SNIPPETS:=bugs/makefile.make
bugs: check
update-bugs: update
endif

$(foreach i,$(MAKE_SNIPPETS),$(eval CDIR:=$(dir $(i))) $(info Entering $(i:%/makefile.make=%)) $(eval -include $(i)))
