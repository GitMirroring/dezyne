# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

ifneq ($(strip $(wildcard *.c)),)
LANGUAGE:=c
else
LANGUAGE:=c++
endif

## common
.SUFFIXES:
SHELL:=/bin/bash
OUT:=out
CCACHE:=$(shell type -p ccache)

default: all

help: help-common

help-common:
	@echo 'Usage: make [OPTION]... [TARGET]...'
	@echo ''
	@echo 'Targets:'
	@echo '  all            update everything'
	@echo '  clean          remove all generated stuff in $(OUT)'
	@echo '  test           make $(TARGET) and run it'

all: $(OUT)/.gitignore

clean:
	rm -rf $(OUT)

## specific

include make/compile.make
include make/dezyne.make

TARGET:=$(OUT)/test
$(TARGET).o: $(RUNTIME:%=$(OUT)/%) $(O_FILES)
$(TARGET): $(O_FILES)
	$(LINK.cc) $^ $(LOADLIBES) $(LDLIBS) -o $@

all: $(TARGET)

test: all
	$(TARGET)
