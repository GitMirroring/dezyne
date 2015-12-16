# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

ifeq (0,0)
default:
	@echo disabled, try ./build.sh
else
GAIAG:= ~/development/build/gaiag
CONVERT:= ~/development/externals/asdsuite/0.0.0/asd
PARSER:= ~/development/build/generate

CXX:= clang++ -g -std=c++11 -pthread
CPPFLAGS:= -I ~/development/gaiag/runtime/c++
CXXFLAGS:= -Wall -Wextra

VERSION:= 9.2.0

all: Generic.h asdDiagnostics.cpp runtime.cc pump.cc test

test: main.o AlarmSystemComponent.o AlarmSystemComp.o asdDiagnostics.o runtime.o pump.o
	$(LINK.cc) -o $@ $^

Generic.h:
	touch Generic.h
	asdgenerate -v $(VERSION) -r -l cpp
	ln -s ~/development/gaiag/runtime/c++/runtime.cc .
	ln -s ~/development/gaiag/runtime/c++/pump.cc .

%Comp.dzn: %.dm
	$(CONVERT) -a no-system -l gen2 $<
	sed -i -e 's/provides /provides dzn./' -e 's/requires /requires dzn./' -e 's/reply(/reply(dzn./' $@

I%.dzn: %.im
	$(CONVERT) -l gen2 $<
	sed -i 's/^interface /interface dzn./' $@

AlarmSystemComponent.cpp AlarmSystemComponent.h: AlarmSystem.dm ConsoleInterface.h SensorInterface.h SirenInterface.h SensorComponent.h SirenComponent.h
	asdgenerate -v $(VERSION) -l cpp -o . $<

%Interface.h: %.im
	asdgenerate -v $(VERSION) -l cpp -o . $<

AlarmSystemComp.scm: AlarmSystemComp.dzn IConsole.dzn ISensor.dzn ISiren.dzn
	$(PARSER) -l scm $<

I%.hh: I%.dzn
	$(GAIAG) -l c++ $<
	mv dzn_$@ $@

main.cc AlarmSystemComp.cc AlarmSystemComp.hh SensorComponent.h SirenComponent.h: AlarmSystemComp.scm ConsoleInterface.h IConsole.hh ISensor.hh ISiren.hh
	$(GAIAG) -l c++ -m AlarmSystemComp --glue=asd $<

%.cc %.hh: %.dzn
	$(GAIAG) -l c++ $<

clean:
	rm -f *.o *.cc *.hh *.cpp *.scm *.dzn *.map
endif
