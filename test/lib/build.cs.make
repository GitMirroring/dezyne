# Dezyne --- Dezyne command line tools
#
# Copyright © 2016, 2018, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

define MONO_SCRIPT
#! $(SHELL)
mono --debug $$(dirname $$0)/test.exe "$$@"
endef
export MONO_SCRIPT

default: $(OUT)/test

$(OUT)/test: $(OUT)/test.exe
	echo "$$MONO_SCRIPT" > $@
	chmod +x $@

DEVELOPMENT:=$(shell readlink -f $(dir $(filter %/build.cs.make,$(MAKEFILE_LIST)))../../)

IN_SOURCES := $(wildcard $(IN)/*.cs) $(wildcard $(IN)/cs/*.cs)
RUNTIME_SOURCES := $(wildcard $(DEVELOPMENT)/runtime/cs/dzn/*.cs)
OUT_SOURCES := $(wildcard $(OUT)/*cs)
ifneq ($(filter %/main.cs,$(IN_SOURCES)),)
OUT_SOURCES := $(filter-out %/main.cs,$(OUT_SOURCES))
endif
$(OUT)/test.exe: $(OUT_SOURCES) $(IN_SOURCES) $(RUNTIME_SOURCES)
	mcs -debug -out:$@ $^
