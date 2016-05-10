# Dezyne --- Dezyne command line tools
#
# Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

BLOCKING_DEADLOCK:=\
 $(CDIR)SimpleBlockingDeadlock.dzn\
 $(CDIR)SimpleBlockingDeadlock2.dzn\
#
BLOCKING_SYSTEM:=\
 $(CDIR)BlockedSystem.dzn\
 $(CDIR)BlockedSystem1.dzn\
 $(CDIR)BlockedSystem2.dzn\
 $(CDIR)BlockedSystem3.dzn\
 $(CDIR)BlockedSystem4.dzn\
#
BROKEN_triangle:=\
 $(BLOCKING_SYSTEM)\
#
BROKEN_run:=\
 $(BLOCKING_DEADLOCK)\
 $(BLOCKING_SYSTEM)\
#
LANGUAGES:=$(filter c++ javascript run table verify,$(CODE_LANGUAGES) $(PSEUDO_LANGUAGES))
include make/files.make
