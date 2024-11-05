# Dezyne --- Dezyne command line tools
#
# Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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
 %D%/accessor.scm				\
 %D%/display.scm				\
 %D%/equal.scm					\
 %D%/goops.scm					\
 %D%/lookup.scm					\
 %D%/normalize.scm				\
 %D%/parse.scm					\
 %D%/recursive.scm				\
 %D%/serialize.scm				\
 %D%/util.scm					\
 %D%/wfc.scm

dist_nocompile_%C%_scm_DATA =

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)
%C%_godir = $(guileobjectdir)/%D%
%C%_go_DATA = $(dist_%C%_scm_DATA:%.scm=%.go)
%C%_go_DATA += $(nodist_%C%_scm_DATA:%.scm=%.go)
ALL_GO += $(%C%_go_DATA)
