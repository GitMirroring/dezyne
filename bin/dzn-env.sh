#! /bin/sh

# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

if [ "$0" = "@COMMAND@" ]; then
    wrapper=$(type -p @COMMAND@)
else
    wrapper=$(readlink -f "$0")
fi
dir=$(dirname "$wrapper")
PATH="$dir:$dir/gnu/bin:$PATH"
GUILE_LOAD_PATH="$dir/gnu/share/guile/site/2.2:$dir/gnu/guile/2.2${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"
GUILE_LOAD_COMPILED_PATH="$dir/gnu/lib/guile/2.2/site-ccache:$dir/gnu/lib/guile/2.2/ccache${GUILE_LOAD_COMPILED_PATH:+:}$GUILE_LOAD_COMPILED_PATH"
export GUILE_LOAD_PATH GUILE_LOAD_COMPILED_PATH
# for dzn-mode.el
EMACSLOADPATH="$dir/gnu/share/emacs/site-lisp${EMACSLOADPATH:+:}$EMACSLOADPATH"
export EMACSLOADPATH
# for Emacs' sake, leave colon even if empty.
INFOPATH="$dir/gnu/share/info:$INFOPATH"
export INFOPATH
MANPATH="$dir/gnu/share/man${MANPATH:+:}$MANPATH"
export MANPATH

exec "$@"
