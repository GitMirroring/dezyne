# Dezyne --- Dezyne command line tools
#
# Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

#! /bin/sh
tree=${tree-../step}

# already done and patched
# tar -C $tree -cf- test/bin | tar -xf-
# tar -C $tree -cf- test/lib | tar -xf-

dirs="
smoke
hello
regression

async
blocking
error
import
namespace
parser
glue
step
compliance
interpreter-error-msg
verification-error-msg
"

for i in $dirs; do
    lst=$(ls -1 $tree/test/$i | sed -e s,^,test/all/, | grep -v roadmap.org)
    tar -C $tree -cf- $lst "test/$i" | tar -xf-
done

cp -r "$tree/test/all/hello space" test/all
cp -r "$tree/test/regression/hello space" test/regression
rm -rf test/smoke/trip test/all/trip
