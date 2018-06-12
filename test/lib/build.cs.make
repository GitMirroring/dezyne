# Dezyne --- Dezyne command line tools
#
# Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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
MAIN:=$(OUT)/main.cs
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

$(OUT)/test.exe: $(MAIN) $(wildcard $(OUT)/*cs $(OUT)/dzn/*.cs)
	cp --force --backup $(MAIN) $(OUT)/main.cs
	mcs -debug -out:$@ $^
