#! /bin/sh

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

LANG=C
LC_ALL=C

LC_ADDRESS=C
LC_IDENTIFICATION=C
LC_MEASUREMENT=C
LC_MONETARY=C
LC_NAME=C
LC_NUMERIC=C
LC_PAPER=C
LC_TELEPHONE=C
LC_TIME=C

export LANG LC_ALL
export LC_ADDRESS LC_IDENTIFICATION LC_MEASUREMENT LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME

if [ "$0" = "@COMMAND@" ]; then
    wrapper=$(type -p @COMMAND@)
else
    wrapper=$(readlink -f "$0")
fi
dir=$(dirname "$wrapper")
PATH=$dir:$PATH
exec "$dir/gnu/bin/@COMMAND@" "$@"
