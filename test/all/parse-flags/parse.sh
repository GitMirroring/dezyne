#! /usr/bin/env bash
# Dezyne --- Dezyne command line tools
#
# Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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
TESTS="
test/all/ihelloworld/ihelloworld.dzn
test/language/interface1.dzn
test/all/parse_import_path/parse_import_path.dzn
test/all/parse_non_existent_import/parse_non_existent_import.dzn
test/all/parse_assign_void/parse_assign_void.dzn
"

function pretty2line () {
    guile -c '(unless (eof-object? (peek-char)) ((compose write read)))'
}

set -o pipefail
for i in $TESTS; do
    echo "parse --fall-back $i"
    echo "parse --fall-back $i" 1>&2
    dzn parse --fall-back $i
    echo "parse --fall-back $i => $?"

    echo "parse --fall-back --parse-tree $i"
    echo "parse --fall-back --parse-tree $i" 1>&2
    dzn parse --fall-back --parse-tree -o- $i | pretty2line
    echo "parse --fall-back --parse-tree $i => $?"

    echo "--verbose parse parse --parse-tree $i"
    echo "--verbose parse parse --parse-tree $i" 1>&2
    dzn --verbose parse --parse-tree -o- $i | pretty2line
    echo "--verbose parse --parse-tree $i => $?"

    echo "parse --parse-tree -o- $i"
    echo "parse --parse-tree -o- $i" 1>&2
    dzn parse --parse-tree -o- $i | pretty2line
    echo "parse --parse-tree -o- $i => $?"

    echo "parse --preprocess $i"
    echo "parse --preprocess $i" 1>&2
    dzn parse --preprocess $i
    echo "parse --preprocess $i => $?"

    echo "parse --preprocess $i | --verbose parse -"
    echo "parse --preprocess $i | --verbose parse -" 1>&2
    dzn parse --preprocess $i | dzn --verbose parse -
    echo "parse --preprocess $i | --verbose parse - => $?"

    echo "--verbose parse $i"
    echo "--verbose parse $i" 1>&2
    dzn  --verbose parse $i
    echo "--verbose --parse $i => $?"

    echo "parse $i -o-"
    echo "parse $i -o-" 1>&2
    dzn parse -o- $i | pretty2line
    echo "parse -o- $i => $?"
done
