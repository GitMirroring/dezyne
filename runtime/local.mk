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

runtime_cxx03_dzndir = $(pkgdatadir)/runtime/c++03/dzn
runtime_cxx03_dzn_DATA =			\
 %D%/c++03/dzn/container.hh			\
 %D%/c++03/dzn/coroutine.hh			\
 %D%/c++03/dzn/locator.hh			\
 %D%/c++03/dzn/meta.hh				\
 %D%/c++03/dzn/meta.hh.in			\
 %D%/c++03/dzn/pump.hh				\
 %D%/c++03/dzn/runtime.hh			\
 %D%/c++03/dzn/sexp.hh

runtime_cxx03dir = $(pkgdatadir)/runtime/c++03
runtime_cxx03_DATA =				\
 %D%/c++03/pump.cc				\
 %D%/c++03/runtime.cc

runtime_c_dzndir = $(pkgdatadir)/runtime/c/dzn
runtime_c_dzn_DATA =				\
 %D%/c/dzn/boolc90.h				\
 %D%/c/dzn/closure.h				\
 %D%/c/dzn/config.h				\
 %D%/c/dzn/locator.h				\
 %D%/c/dzn/map.h				\
 %D%/c/dzn/mem.h				\
 %D%/c/dzn/meta.h				\
 %D%/c/dzn/pair.h				\
 %D%/c/dzn/queue.h				\
 %D%/c/dzn/runloc.h				\
 %D%/c/dzn/runtime.h

runtime_cdir = $(pkgdatadir)/runtime/c
runtime_c_DATA =				\
 %D%/c/locator.c				\
 %D%/c/map.c					\
 %D%/c/mem.c					\
 %D%/c/queue.c					\
 %D%/c/runtime.c

runtime_cxx_dzndir = $(pkgdatadir)/runtime/c++/dzn
runtime_cxx_dzn_DATA =				\
 %D%/c++/dzn/container.hh			\
 %D%/c++/dzn/context.hh				\
 %D%/c++/dzn/coroutine.hh			\
 %D%/c++/dzn/locator.hh				\
 %D%/c++/dzn/meta.hh				\
 %D%/c++/dzn/meta.hh.in				\
 %D%/c++/dzn/pump.hh				\
 %D%/c++/dzn/runtime.hh				\
 %D%/c++/dzn/sexp.hh

runtime_cxxdir = $(pkgdatadir)/runtime/c++
runtime_cxx_DATA =				\
 %D%/c++/pump.cc				\
 %D%/c++/runtime.cc

runtime_cxx_msvc11_dzndir = $(pkgdatadir)/runtime/c++-msvc11/dzn
runtime_cxx_msvc11_dzn_DATA =			\
 %D%/c++-msvc11/dzn/meta.hh			\
 %D%/c++-msvc11/dzn/meta.hh.in

runtime_cs_dzndir = $(pkgdatadir)/runtime/cs/dzn
runtime_cs_dzn_DATA =				\
 %D%/cs/dzn/container.cs			\
 %D%/cs/dzn/context.cs				\
 %D%/cs/dzn/coroutine.cs			\
 %D%/cs/dzn/locator.cs				\
 %D%/cs/dzn/meta.cs				\
 %D%/cs/dzn/pump.cs				\
 %D%/cs/dzn/runtime.cs

runtime_javascript_dzndir = $(pkgdatadir)/runtime/javascript/dzn
runtime_javascript_dzn_DATA =			\
 %D%/javascript/dzn/runtime.js			\
 %D%/javascript/dzn/sexp.js

runtime_scheme_dzndir = $(pkgdatadir)/runtime/scheme/dzn
runtime_scheme_dzn_DATA =			\
 %D%/scheme/dzn/pump.scm			\
 %D%/scheme/dzn/runtime.scm
