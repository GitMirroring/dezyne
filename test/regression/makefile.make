# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Ladislau Posta <ladislau.posta@verum.com>
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@hansei-kaizen.org>
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

BROKEN:=\
  regression/ConsumeMultiple.dzn\
  regression/QTriggerModeling.dzn\
#

# error: Reply5: variable s is already defined in method i_done()
BROKEN_cs:=\
 regression/DataVariables.dzn\
 regression/List.dzn\
 regression/Reply5.dzn\
 regression/SynchronousLivelock.dzn\

# c++ is main language, can never be broken
BROKEN_c++03:=\

BROKEN_goops:=\
 regression/DataVariables.dzn\
 regression/QTriggerModeling.dzn\
 regression/SynchronousLivelock.dzn\
 regression/SynchronousOut.dzn\

# error: Reply5: variable s is already defined in method i_done()
# error: R: non-static type variable R cannot be referenced from a static context
BROKEN_java:=\
 regression/DataVariables.dzn\
 regression/List.dzn\
 regression/Reply5.dzn\
 regression/R.dzn\
 regression/SynchronousLivelock.dzn\

BROKEN_java7:=$(BROKEN_java)

BROKEN_javascript:=\
 regression/DataVariables.dzn\
#

BROKEN_python:=\
 regression/DataVariables.dzn\
 regression/SynchronousLivelock.dzn\
#

BROKEN_run:=\
 regression/MultipleOutEventsOnSingleTau.dzn\
 regression/Simpleint.dzn\
 regression/SyncPedal.dzn\
 regression/incomplete.dzn\
 regression/inner_space.dzn\
 regression/name_space.dzn\
 regression/simple_space.dzn\
#

ConsumeMultiple.flush:=--flush
DataVariables.flush:=--flush
Handle.flush:=--flush
MultipleOutEventsOnSingleTau.flush:=--flush
RequiredOptional.flush:=--flush
TauEmitMultiple.flush:=--flush
flush2cb.flush:=--flush
multiple_provides.flush:=--flush
single_tau_to_multiple_tau_should_not_refine.flush:=--flush

include make/files.make
