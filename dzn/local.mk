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
 %D%/c++.scm					\
 %D%/c++03.scm					\
 %D%/c.scm					\
 %D%/code.scm					\
 %D%/command-line.scm				\
 %D%/config.scm					\
 %D%/cs.scm					\
 %D%/display.scm				\
 %D%/dzn.scm					\
 %D%/fifo.scm					\
 %D%/gdzn.scm					\
 %D%/glue.scm					\
 %D%/goops.scm					\
 %D%/indent.scm					\
 %D%/javascript.scm				\
 %D%/json2scm.scm				\
 %D%/lts.scm					\
 %D%/makreel.scm				\
 %D%/misc.scm					\
 %D%/normalize.scm				\
 %D%/parse.scm					\
 %D%/scheme.scm					\
 %D%/serialize.scm				\
 %D%/shell-util.scm				\
 %D%/templates.scm				\
 %D%/wfc.scm

dist_nocompile_%C%_scm_DATA =

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)
%C%_godir = $(guileobjectdir)/%D%
%C%_go_DATA = $(dist_%C%_scm_DATA:%.scm=%.go)
ALL_GO += $(%C%_go_DATA)
