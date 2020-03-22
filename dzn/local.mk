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

dist_%C%_scm_DATA =				\
 %D%/ast.scm					\
 %D%/code.scm					\
 %D%/command-line.scm				\
 %D%/display.scm				\
 %D%/dzn.scm					\
 %D%/fifo.scm					\
 %D%/gdzn.scm					\
 %D%/goops.scm					\
 %D%/indent.scm					\
 %D%/json.scm					\
 %D%/lts.scm					\
 %D%/makreel.scm				\
 %D%/misc.scm					\
 %D%/normalize.scm				\
 %D%/parse.scm					\
 %D%/peg.scm					\
 %D%/serialize.scm				\
 %D%/shell-util.scm				\
 %D%/templates.scm				\
 %D%/wfc.scm

if have_cxx11
dist_%C%_scm_DATA += %D%/c++.scm
dist_%C%_scm_DATA += %D%/glue.scm

if have_cxx03
dist_%C%_scm_DATA += %D%/c++03.scm
endif

endif

if have_cs
dist_%C%_scm_DATA += %D%/cs.scm
endif

if have_c99
dist_%C%_scm_DATA += %D%/c.scm
endif

if have_javascript
dist_%C%_scm_DATA += %D%/javascript.scm
endif

if have_scheme
dist_%C%_scm_DATA += %D%/scheme.scm
endif

EXTRA_DIST += %D%/config.scm.in
BUILT_SOURCES += %D%/config.scm
nodist_%C%_scm_DATA = %D%/config.scm

dist_nocompile_%C%_scm_DATA =

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)
%C%_godir = $(guileobjectdir)/%D%
%C%_go_DATA = $(dist_%C%_scm_DATA:%.scm=%.go)
%C%_go_DATA += $(nodist_%C%_scm_DATA:%.scm=%.go)
ALL_GO += $(%C%_go_DATA)
