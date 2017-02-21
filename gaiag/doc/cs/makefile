# Dezyne --- Dezyne command line tools
#
# Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

default: all

all: test.exe

test.exe: ../../runtime/cs/dzn/context.cs ../../runtime/cs/dzn/coroutine.cs test.cs
	rm -f $@
	mcs -debug -out:$@ $^ |& sed -e 's@[.]cs(@.cs:@' -e 's@,@:@' -e 's@): @:@'

coroutine:
	mcs coroutine.cs |& sed -e 's@[.]cs(@.cs:@' -e 's@,@:@' -e 's@): @:@'

await.exe: ../../runtime/cs/dzn/coroutine.cs await.cs
	rm -f $@
	mcs -debug -out:$@ $^ |& sed -e 's@[.]cs(@.cs:@' -e 's@,@:@' -e 's@): @:@'
