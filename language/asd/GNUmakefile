# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

DEPTH = ../..
diff = diff -uw -I '^ *$$' -I '^ *//'
BUILD = build-master
asdgen = ASD_PREFIX=$(DEPTH) $(DEPTH)/$(BUILD)/asdgenerator

default: all

all: compile check

compile:
	guile -L ../.. spec.scm 

baseline:
	$(asdgen) -l cpp examples/alarm-component-pretty.asd && mv Alarm* examples
	$(asdgen) -l cpp examples/CommImpl.asd && mv CommImpl* examples
	$(asdgen) -l cpp examples/Aap.asd && mv AapInt* NootComp* examples

check: ast pretty c++

ast:
	./gaiag examples/interface-enums.asd
	./gaiag examples/interface-events.asd
	./gaiag examples/interface-reply-events.asd
	./gaiag examples/interface-behaviour.asd
	./gaiag examples/interface-imports.asd
	./gaiag examples/alarm-component.asd

pretty:
	guile -L ../.. --language=asd -s examples/interface-enums.asd | indent
	./gaiag -l asd examples/interface-enums.asd | indent
	./gaiag -l asd examples/alarm-component-pretty.asd | indent | tee pretty.asd && $(diff) examples/alarm-component-pretty.asd pretty.asd

c++: baseline
	./gaiag -l c++ examples/alarm-component-pretty.asd
	-$(diff) examples/AlarmComponent.h .
	-$(diff) examples/AlarmComponent.cpp .
	./gaiag examples/Aap.asd
	./gaiag -l c++ examples/Aap.asd
	[ -f examples/NootComponent.h ] && $(diff) examples/NootComponent.h .
	-[ -f examples/NootComponent.cpp ] && $(diff) examples/NootComponent.cpp .
	./gaiag -l c++ examples/CommImpl.asd
	[ -f examples/CommImplComponent.h ] && $(diff) examples/CommImplComponent.h .
	-[ -f examples/CommImplComponent.cpp ] && $(diff) examples/CommImplComponent.cpp .
	./gaiag -l test examples/interface-enums.asd 
