#! /usr/bin/env bash
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
# Usage: test/bin/update.sh {simulate|verify} test/all/<test>
#
# Code:

verify=false
simulate=false
if [ $1 = verify ]; then
    verify=true
    shift
fi

if [ $1 = simulate ]; then
    simulate=true
    shift
fi

dir=$1
echo $dir;
base=$(basename $dir)

if $verify; then
    model=$(grep -Eo '[(]model [^)]*' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -z "$model" ]; then
        model="--model $base"
    elif [ $model = '#f' ]; then
        model=
    else
        model="--model $model"
    fi
    determinism=$(grep -Eo 'no-interface-determinism[?] #t' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ "$determinism" = true ]; then
        determinism=--no-interface-determinism
    else
        determinism=
    fi

    mkdir -p $dir/baseline/verify
    ./pre-inst-env dzn -v verify -a $model $determinism $dir/$base.dzn  \
        > $dir/baseline/verify/$base                                    \
        2> $dir/baseline/verify/$base.stderr

    rm -f $(find $dir/baseline/verify -size 1c -o -size 0c)
fi

if $simulate; then
    format=$(grep -Eo 'trace-format "[^")}]*"' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -z "$format" ]; then
        format="trace"
    fi

    mkdir -p $dir/baseline/simulate
    ./pre-inst-env dzn simulate --format=$format $dir/$base.dzn < $dir/trace    \
        > $dir/baseline/simulate/$base                                          \
        2> $dir/baseline/simulate/$base.stderr

    rm -f $(find $dir/baseline/simulate -size 1c -o -size 0c)
fi
