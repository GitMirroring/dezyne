# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2020 Rutger van Beusekom <rutger@dezyne.org>
# Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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

if have_c99
runtime_c_dzndir = $(pkgdatadir)/runtime/c/dzn
dist_runtime_c_dzn_DATA =			\
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
dist_runtime_c_DATA =				\
 %D%/c/locator.c				\
 %D%/c/map.c					\
 %D%/c/mem.c					\
 %D%/c/queue.c					\
 %D%/c/runtime.c
endif

if have_cs
runtime_cs_dzndir = $(pkgdatadir)/runtime/cs/dzn
dist_runtime_cs_dzn_DATA =			\
 %D%/cs/dzn/container.cs			\
 %D%/cs/dzn/context.cs				\
 %D%/cs/dzn/coroutine.cs			\
 %D%/cs/dzn/locator.cs				\
 %D%/cs/dzn/meta.cs				\
 %D%/cs/dzn/pump.cs				\
 %D%/cs/dzn/runtime.cs
endif

if have_cxx11
runtime_cxx_dzndir = $(pkgdatadir)/runtime/c++/dzn
dist_runtime_cxx_dzn_DATA =			\
 %D%/c++/dzn/container.hh			\
 %D%/c++/dzn/context.hh				\
 %D%/c++/dzn/coroutine.hh			\
 %D%/c++/dzn/locator.hh				\
 %D%/c++/dzn/meta.hh				\
 %D%/c++/dzn/pump.hh				\
 %D%/c++/dzn/runtime.hh

dist_noinst_DATA += %D%/c++/dzn/meta.hh.in

runtime_cxxdir = $(pkgdatadir)/runtime/c++
dist_runtime_cxx_DATA =				\
 %D%/c++/pump.cc				\
 %D%/c++/runtime.cc                             \
 %D%/c++/thread_pool.cc
endif

if have_javascript
runtime_javascript_dzndir = $(pkgdatadir)/runtime/javascript/dzn
dist_runtime_javascript_dzn_DATA =		\
 %D%/javascript/dzn/runtime.js
endif

if have_cxx_exception_wrappers
runtime_examplesdir = $(pkgdatadir)/runtime/examples
dist_runtime_examples_DATA =		\
 %D%/examples/exception_context.hh
endif

if have_scheme
runtime_scheme_dzndir = $(pkgdatadir)/runtime/scheme/dzn
dist_runtime_scheme_dzn_DATA =			\
 %D%/scheme/dzn/locator.scm			\
 %D%/scheme/dzn/pump.scm			\
 %D%/scheme/dzn/runtime.scm
endif
