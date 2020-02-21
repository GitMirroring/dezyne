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

dist_nocompile_%C%_scm_DATA =			\
 %D%/code.scm					\
 %D%/c++.scm					\
 %D%/dzn.scm					\
 %D%/glue.scm					\
 %D%/javascript.scm				\
 %D%/makreel.scm				\
 %D%/scheme.scm

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)

EXTRA_DIST +=					\
 %D%/c++					\
 %D%/dzn					\
 %D%/javascript					\
 %D%/makreel					\
 %D%/scheme

%C%dir = $(pkgdatadir)/%D%
