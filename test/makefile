# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Ladislau Posta <ladislau.posta@verum.com>
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
PHONIES:=all check clean default depend help list regression stress update
DIRECTORIES:=$(notdir $(shell find . -mindepth 2 -type d | grep -Ev 'baseline|out|[.]git'))
.PHONY: $(PHONIES)
.PHONY: $(DIRECTORIES)

.SECONDARY:
.SUFFIXES:
SHELL:=/bin/bash
DZN:=../client/dzn
OUT:=out
CCACHE:=$(shell type -p ccache)
#TRIANGLE_MAX:=cat
TRIANGLE_MAX:=head -50 # use `cat' for all
VERBOSE:=

ALL_CODE_LANGUAGES:=c c++ c++03 cs goops javascript python

JAVA:=$(strip $(shell /usr/bin/javac -version 2>&1 | grep -oe 'javac 1.8' >/dev/null && echo java))
JAVA7:=$(strip $(shell /usr/bin/javac -version 2>&1 | grep -oe 'javac 1.[78]' >/dev/null && echo java7))

ifneq ($(JAVA),)
ALL_CODE_LANGUAGES+=java
endif
ifneq ($(JAVA7),)
ALL_CODE_LANGUAGES+=java7
endif

ALL_CODE_LANGUAGES:=c++
CODE_LANGUAGES:=$(ALL_CODE_LANGUAGES)

# PSEUDO_LANGUAGES=convert parse run table verify
PSEUDO_LANGUAGES=run table verify
ALL_LANGUAGES=$(CODE_LANGUAGES) $(PSEUDO_LANGUAGES)

SUFFIXES:=code parse update $(PSEUDO_LANGUAGES) $(CODE_LANGUAGES)
.PHONY: $(SUFFIXES)
PHONIES+=$(SUFFIXES)
#SUFFIX_FILTER:=$(foreach s,$(SUFFIXES),$(shell echo "%-$(s)"))
GOAL_TARGETS:=$(strip $(filter-out $(PHONIES),$(MAKECMDGOALS)))
#GOAL_TARGETS:=$(strip $(filter $(SUFFIX_FILTER),$(MAKECMDGOALS)))
GOAL_NAMES:=
$(foreach i,$(GOAL_TARGETS),$(eval GOAL_NAMES+=$(firstword $(subst -, ,$(i)))))
GOAL_NAMES:=$(strip $(GOAL_NAMES))
GOAL_LANGUAGES:=
$(foreach i,$(GOAL_TARGETS),$(eval GOAL_LANGUAGES+=$(word 2,$(subst -, ,$(i)))))
ifeq ($(filter code,$(GOAL_LANGUAGES)),code)
GOAL_LANGUAGES:=$(filter-out code,$(GOAL_LANGUAGES)) $(ALL_CODE_LANGUAGES)
endif
GOAL_LANGUAGES:=$(strip $(GOAL_LANGUAGES))

# put your local overrides here, e.g.,
# DZN:=~/development.git/client/dzn
-include .local.make

default: check

help: help-common

define HELP_COMMON
Usage: make [OPTION]... [VARIABLE=VALUE]... [TARGET]...

Options:
  see make --help

Variables:
  DZN={dzn|~/development.git/client/dzn} [$(DZN)]
  ALL_LANGUAGES='...' [$(ALL_LANGUAGES)]
  CODE_LANGUAGES='...' [$(CODE_LANGUAGES)]
  OUT=<dir> [$(OUT)]
  VERBOSE={|debug|info} [$(VERBOSE)]

Targets:
  check          run all checks
  clean          remove all generated stuff in $(OUT)
  check          check
  list           list all targets
  regression     full regression test suite
  stress         run stress test
  update         overwrite all baselines
endef
export HELP_COMMON
help-common:
	@echo "$$HELP_COMMON"

#ifeq ($(filter list,$(MAKECMDGOALS)),list)
#$(info Targets:)
#endif

clean:
	rm -rf $(OUT)

$(OUT)/.gitignore:
	mkdir -p $(OUT)
	echo '*' > $(OUT)/.gitignore

DIRECTORIES:=$(shell find -mindepth 1 -name makefile | sed s,/makefile,,)
#.PHONY: $(DIRECTORIES)
ifeq ($(SUB),)
$(DIRECTORIES):
	$(MAKE) -C $@ SUB=$@ $(MAKEOVERRIDES)
endif
$(DIRECTORIES:%=%-clean):
	$(MAKE) -C $(@:%-clean=%) SUB=$(@:%-clean=%) $(MAKEOVERRIDES) clean
$(DIRECTORIES:%=%-update):
	$(MAKE) -C $(@:%-update=%) SUB=$(@:%-update=%) $(MAKEOVERRIDES) update

stress:
	DZN=$(DZN) bin/stress.sh $(CONFIG)

ifneq ($(filter help list,$(MAKECMDGOALS)),)
MAKE_SNIPPETS="$(CURPATH)makefile.make $(patsubst %,$(CURPATH)%,$(sort $(wildcard */makefile.make)))" $(MAKEOVERRIDES) $$@
endif

$(foreach i,$(MAKE_SNIPPETS),$(eval CDIR:=$(dir $(i))) $(info Entering $(i:%/makefile.make=%)) $(eval -include $(i)))
