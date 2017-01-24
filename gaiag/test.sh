# Gaiag --- Guile in Asd In Asd in Guile.
#
# This file is part of Gaiag.
#
# Copyright © 2014, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
# Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
#
# Gaiag is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Gaiag is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

#! /bin/sh
# try: ./test.sh --debug
self=$(readlink -f $(cut -d '' -f2 < /proc/$$/cmdline))
prefix=$(cd $(dirname $self) && pwd)
[ "$(basename $prefix)" != "gaiag" ] && prefix=$prefix/gaiag
dir=$(basename $prefix)
top=$(cd $prefix/.. && pwd)
build=${ABS_BUILD-$top/build}
ccache=$build/ccache
GUILE_AUTO_COMPILE=0
GUILE_LOAD_PATH="$prefix:$prefix/json:$GUILE_LOAD_PATH"
GUILE_LOAD_COMPILED_PATH="$ccache:$ccache/json:$ccache/test-suite:$GUILE_LOAD_COMPILED_PATH"
export GUILE_AUTO_COMPILE GUILE_LOAD_PATH GUILE_LOAD_COMPILED_PATH
cd $dir
#set -o pipefail
#${GUILE-guile} -e main test-suite/run-tests "$@" < /dev/null |& sed "s@^test-suite/@$dir/test-suite/@"
${GUILE-guile} -e main test-suite/run-tests "$@" < /dev/null
