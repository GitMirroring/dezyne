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

LIBS = /home/rutger/lib/libboost_coroutine.a /home/rutger/lib/libboost_context.a /home/rutger/lib/libboost_thread.a /home/rutger/lib/libboost_system.a

CXX = ccache g++
override CPPFLAGS += -I /home/rutger/include/ -MMD -MF $(@:%.o=%.d) -MT '$(@:%.o=%.d) $@'
CXXFLAGS = -pthread -std=c++14

COMPILE.cc = $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c

alarm: $(patsubst %.cc, %.o, $(wildcard *.cc))
	$(CXX) $(CXXFLAGS) $^ $(LIBS) -o $@

clean:
	rm -f *.o test

proper: clean
	rm -f *.d

test: alarm
	echo -e 'console.arm\nconsole.disarm\nsensor.triggered\nsensor.disabled' | ./alarm

help:
	@echo enable debug tracing with: make CPPFLAGS=-DDEBUG

-include $(patsubst %.cc, %.d, $(wildcard *.cc))
