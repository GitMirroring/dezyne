# Dezyne --- Dezyne command line tools
#
# Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

CXX=g++ -pthread -std=c++11
CXXFLAGS=-g -Wall
CPPFLAGS=-MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@' -I. -include MachineConstants.hh
CCACHE=$(basename $(shell which ccache))

%.o: %.cc
	$(CCACHE) $(COMPILE.cc) $(OUTPUT_OPTION) $<

all: runtime code
	make lego

runtime:
	cp -r ../../../dzn/runtime/c++/* .
	touch runtime

code: $(wildcard *.dzn)
	for f in $^; do ../../../dzn/bin/dzn -v code -l c++ $$f; done
	touch code

lego: $(patsubst %.cc, %.o, $(filter-out gui.cc main.cc, $(wildcard *.cc)))
	$(LINK.cc) $^ -lusb -o $@

clean:
	rm lego *.o

proper: clean
	git clean -f .

#-include $(wildcard *.d)
