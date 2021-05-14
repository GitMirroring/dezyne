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
# Code:

dist_%C%_scm_DATA =				\
 %D%/code.scm					\
 %D%/makreel.scm

dist_nocompile_%C%_scm_DATA =

if have_cxx11
dist_%C%_scm_DATA += %D%/c++.scm
else
dist_noinst_DATA += %D%/c++.scm
endif

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)
%C%_godir = $(guileobjectdir)/%D%
%C%_go_DATA = $(dist_%C%_scm_DATA:%.scm=%.go)
ALL_GO += $(%C%_go_DATA)
