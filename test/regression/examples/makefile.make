# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Ladislau Posta <ladislau.posta@verum.com>
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

LANGUAGES:=$(ALL_LANGUAGES)
DZN_FILES:=$(wildcard $(CDIR)*.dzn)

# BurglarAlarm: does not compile
# GarageDoorControl does not compile due to system component specification
# Recursion: segfaults on stack overflow
# Stage: only interfaces
BROKEN_code:=\
  $(CDIR)BurglarAlarm.dzn\
  $(CDIR)GarageDoorControl.dzn\
  $(CDIR)GarageDoorControlErr.dzn\
  $(CDIR)Recursion.dzn\
  $(CDIR)Stage.dzn\
  $(CDIR)SystemComposition.dzn\

BROKEN_run:=\
  $(CDIR)Stage.dzn\

$(foreach lang,$(LANGUAGES), $(eval BROKEN_$(lang)+=$(BROKEN_code)))

ErrorPattern.flush:=--flush
SensorMultiplexer.flush:=--flush

include make/files.make
