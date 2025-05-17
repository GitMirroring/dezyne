# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
# Copyright © 2020 Paul Hoogendijk <paul@dezyne.org>
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
 %D%/anonymize.scm				\
 %D%/code.scm					\
 %D%/exec.scm					\
 %D%/graph.scm					\
 %D%/hash.scm					\
 %D%/hello.scm					\
 %D%/language.scm				\
 %D%/lts.scm					\
 %D%/parse.scm					\
 %D%/simulate.scm				\
 %D%/trace.scm					\
 %D%/traces.scm					\
 %D%/verify.scm

dist_nocompile_%C%_scm_DATA =

%C%_scmdir = $(guilemoduledir)/%D%
nocompile_%C%_scmdir = $(%C%_scmdir)
%C%_godir = $(guileobjectdir)/%D%
%C%_go_DATA = $(dist_%C%_scm_DATA:%.scm=%.go)
ALL_GO += $(%C%_go_DATA)
