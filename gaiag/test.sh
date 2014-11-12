# Gaiag --- Guile in Asd In Asd in Guile.
#
# This file is part of Gaiag.
#
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
GUILE_LOAD_PATH="$prefix:$prefix/module:$GUILE_LOAD_PATH"
GUILE_LOAD_COMPILED_PATH="$prefix/ccache:$GUILE_LOAD_COMPILED_PATH"
export GUILE_LOAD_PATH GUILE_LOAD_COMPILED_PATH
spec=language/dezyne/spec
[ -f $prefix/ccache/$spec.go ] || guile $prefix/module/$spec.scm
${GUILE-guile} $prefix/module/language/dezyne/spec.scm
exec ${GUILE-guile} -e main test-suite/run-tests "$@"
