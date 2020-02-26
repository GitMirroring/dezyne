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

if have_cxx11
runtime_cxx_dzndir = $(pkgdatadir)/runtime/c++/dzn
dist_runtime_cxx_dzn_DATA =			\
 %D%/c++/dzn/container.hh			\
 %D%/c++/dzn/context.hh				\
 %D%/c++/dzn/coroutine.hh			\
 %D%/c++/dzn/locator.hh				\
 %D%/c++/dzn/meta.hh.in				\
 %D%/c++/dzn/pump.hh				\
 %D%/c++/dzn/runtime.hh				\
 %D%/c++/dzn/sexp.hh

runtime_cxxdir = $(pkgdatadir)/runtime/c++
dist_runtime_cxx_DATA =				\
 %D%/c++/pump.cc				\
 %D%/c++/runtime.cc
endif

if have_javascript
runtime_javascript_dzndir = $(pkgdatadir)/runtime/javascript/dzn
dist_runtime_javascript_dzn_DATA =		\
 %D%/javascript/dzn/runtime.js			\
 %D%/javascript/dzn/sexp.js
endif

if have_scheme
runtime_scheme_dzndir = $(pkgdatadir)/runtime/scheme/dzn
dist_runtime_scheme_dzn_DATA =			\
 %D%/scheme/dzn/pump.scm			\
 %D%/scheme/dzn/runtime.scm
endif
