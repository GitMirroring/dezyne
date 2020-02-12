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
 %D%/dzn.scm					\
 %D%/json.scm					\
 %D%/makreel.scm

if have_cxx11
dist_nocompile_%C%_scm_DATA += %D%/c++.scm
dist_nocompile_%C%_scm_DATA += %D%/glue.scm
endif

if have_cs
dist_nocompile_%C%_scm_DATA += %D%/cs.scm
endif

if have_c99
dist_nocompile_%C%_scm_DATA += %D%/c.scm
endif

if have_javascript
dist_nocompile_%C%_scm_DATA += %D%/javascript.scm
endif

if have_scheme
dist_nocompile_%C%_scm_DATA += %D%/scheme.scm
endif

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)

EXTRA_DIST +=					\
 %D%/dzn					\
 %D%/json					\
 %D%/makreel

if have_cxx11
EXTRA_DIST += %D%/c++
endif

if have_cs
EXTRA_DIST += %D%/cs
endif

if have_c99
EXTRA_DIST += %D%/c99
endif

if have_javascript
EXTRA_DIST += %D%/javascript
endif

if have_scheme
EXTRA_DIST += %D%/scheme
endif

%C%dir = $(pkgdatadir)/%D%
