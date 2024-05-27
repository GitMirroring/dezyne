#! /usr/bin/env bash
# Dezyne --- Dezyne command line tools
#
# Copyright © 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2023 Karol Kobiela <karol.kobiela@verum.com>
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
parse=false
if [ $1 = verify ]; then
    verify=true
    shift
fi

if [ $1 = simulate ]; then
    simulate=true
    shift
fi

if [ $1 = parse ]; then
    parse=true
    shift
fi
dir=$1
echo $dir;
base=$(basename $dir)

if $parse; then
    fall_back=$(grep -Eo 'fall-back #t' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ "$fall_back" = '#t' ]; then
        fall_back=--fall-back
    fi
    mkdir -p $dir/baseline
    ./pre-inst-env dzn -v parse $fall_back $dir/$base.dzn     \
        > $dir/baseline/verify.out                                   \
        2> $dir/baseline/verify.err
fi

if $verify; then
    model=$(grep -Eo '[(]model [^)]*' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -z "$model" ]; then
        model=
    elif [ "$model" = '#f' ]; then
        model=
    elif [ -n $model ]; then
        model="--model=$model"
    fi
    determinism=$(grep -Eo 'no-interface-determinism[?] #t' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ "$determinism" = true ]; then
        determinism=--no-interface-determinism
    else
        determinism=
    fi
    queue_size_external=$(grep -Eo '[(]queue-size-external [^)]*' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -n "$queue_size_external" ]; then
        queue_size_external="--queue-size-external=$queue_size_external"
    fi

    mkdir -p $dir/baseline
    ./pre-inst-env dzn -v verify -a $model $determinism \
        $queue_size_external $dir/$base.dzn             \
        > $dir/baseline/verify.out                      \
        2> $dir/baseline/verify.err
fi

if $simulate; then
    model=$(grep -Eo '[(]model [^)]*' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -z "$model" ]; then
        model=
    elif [ "$model" = '#f' ]; then
        model=
    elif [ -n $model ]; then
        model="--model=$model"
    fi
    format=$(grep -Eo 'trace-format "[^")}]*"' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -z "$format" ]; then
        format="trace"
    fi
    strict='--strict'
    non_strict=$(grep -Eo 'non-strict[?] #t[^")}]*' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ "$non_strict" = "#t" ]; then
        strict=""
    fi
    flags=$(grep -Eo 'simulate-flags \([^)]*)' $dir/META | cut -d'(' -f 2 | tr -d '()"')
    queue_size_external=$(grep -Eo '[(]queue-size-external [^)]*' $dir/META | cut -d' ' -f 2 | tr -d '"')
    if [ -n "$queue_size_external" ]; then
        queue_size_external="--queue-size-external $queue_size_external"
    fi

    mkdir -p $dir/baseline
    ./pre-inst-env dzn simulate $strict --format=$format $model \
        $flags $queue_size_external $dir/$base.dzn < $dir/trace \
        > $dir/baseline/simulate.out                            \
        2> $dir/baseline/simulate.err
fi

rm -f $(find $dir/baseline -size 1c -o -size 0c)
