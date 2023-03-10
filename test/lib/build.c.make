# Dezyne --- Dezyne command line tools
#
# Copyright © 2016, 2018, 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2016 Rutger van Beusekom <rutger@dezyne.org>
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

include config.make

.PHONY: default test

default: $(OUT)/test

define CHECKPARAM
ifeq ($(origin $(1)), undefined)
$$(error $(1) undefined)
endif
endef

$(foreach i,IN OUT,$(eval $(call CHECKPARAM,$(i))))

SHELL:=bash
CCACHE:=$(shell type -p ccache)
CC:=$(CCACHE) gcc
CFLAGS=--std=c99 -g -O0
LDFLAGS=$(LIBPTH)
# Tiny: all/Tiny
#CFLAGS=--std=c99 -g -DDZN_TINY=1
#CFLAGS=--std=c99 -Os -DDZN_TINY=1

CPPFLAGS=-I$(OUT) -I$(OUT)/.. -I$(OUT)/../.. -I$(OUT)/../../c -I$(IN) -I$(abs_top_srcdir)/runtime/c
GLOBALS_H=$(wildcard $(DIR)/globals.h)
ifneq ($(GLOBALS_H),)
CPPFLAGS:=$(CPPFLAGS) -include $(GLOBALS_H)
endif

$(OUT)/%.o: $(abs_top_srcdir)/runtime/c/%.c
	mkdir -p $(dir $@)
	$(COMPILE.c) -o $@ $<

$(OUT)/%.o: $(IN)/%.c
	mkdir -p $(dir $@)
	$(COMPILE.c) -o $@ $<

$(OUT)/%.o: $(IN)/c/%.c
	mkdir -p $(dir $@)
	$(COMPILE.c) -o $@ $<

$(foreach f, $(wildcard $(IN)/c/*.c), $(eval $(OUT)/test: $(patsubst $(IN)/c/%.c, $(OUT)/%.o, $(f))))

RUNTIME_SOURCES := $(wildcard $(abs_top_srcdir)/runtime/c/*.c)
RUNTIME_O := $(RUNTIME_SOURCES:$(abs_top_srcdir)/runtime/c/%.c=$(OUT)/%.o)

$(OUT)/test: $(patsubst $(IN)/%.c, $(OUT)/%.o, $(wildcard $(IN)/*.c))
$(OUT)/test: $(patsubst $(OUT)/%.c, $(OUT)/%.o,  $(wildcard $(OUT)/*.c))
$(OUT)/test: $(RUNTIME_O)
	mkdir -p $(dir $@)
	$(LINK.c) -o $@ $^ $(LDFLAGS)

-include $(patsubst $(IN)/%.c, $(OUT)/%.d, $(wildcard $(IN)/*.c))
