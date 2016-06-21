# Dezyne --- Dezyne command line tools
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
# Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

.PHONY: all check regression smoke stress test
SHELL:=bash
DZN:=../client/bin/dzn

# quick check target
check: prerequisite
	bin/test -j16 check

regression: prerequisite
	bin/test -j16 regression-test

stress: prerequisite
	DZN=$(DZN) bin/stress.sh $(CONFIG)

prerequisite:
	timeout 2 $(DZN) hello || { echo "timeout running: dzn hello" 1>&2; kill -9 $$PPID; }
