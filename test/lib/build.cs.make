# Dezyne --- Dezyne command line tools
#
# Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

ifeq ($(MAIN),)
MAIN:=$(OUT)/main.js
endif

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

$(OUT)/test.exe: $(wildcard $(OUT)/*cs) $(wildcard $(IN)/*.cs) $(wildcard $(IN)/cs/*.cs) $(wildcard $(DEVELOPMENT)/runtime/cs/dzn/*.cs)
	mcs -debug -out:$@ $^
