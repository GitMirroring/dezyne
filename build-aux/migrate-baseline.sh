#! /bin/sh
# Dezyne --- Dezyne command line tools
#
# Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
# Usage: build-aux/migrate-baseline.sh
#
# Code:

git clean -fdx test/all/out
for i in $(find test/all -name simulate); do
    d=$(dirname $i)
    b=$(basename $(dirname $d))
    if test -f $i/$b; then
        git mv $i/$b $d/simulate.out
    fi
    if test -f $i/$b.stderr; then
        git mv $i/$b.stderr $d/simulate.err
    fi
done

for i in $(find test/all -name verify); do
    d=$(dirname $i)
    b=$(basename $(dirname $d))
    if test -f $i/$b; then
        git mv $i/$b $d/verify.out
    fi
    if test -f $i/$b.stderr; then
        git mv $i/$b.stderr $d/verify.err
    fi
done

git mv test/all/parse_peg_locations/baseline/parse_peg_locations        \
    test/all/parse_peg_locations/baseline/parse.out

git mv test/all/parse_locations/baseline/parse_locations        \
    test/all/parse_locations/baseline/parse.out
