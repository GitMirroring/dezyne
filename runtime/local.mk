# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

nobase_include_headers =
lib_LTLIBRARIES =
version_info = @LIBDZN_INTERFACE_CURRENT@:@LIBDZN_INTERFACE_REVISION@:@LIBDZN_INTERFACE_AGE@

if have_c99
runtime_c_dzndir = $(pkgdatadir)/runtime/c/dzn
dist_runtime_c_dzn_DATA =			\
 %D%/c/dzn/closure.h				\
 %D%/c/dzn/config.h				\
 %D%/c/dzn/coroutine.h				\
 %D%/c/dzn/list.h				\
 %D%/c/dzn/locator.h				\
 %D%/c/dzn/map.h				\
 %D%/c/dzn/mem.h				\
 %D%/c/dzn/meta.h				\
 %D%/c/dzn/pair.h				\
 %D%/c/dzn/pump.h				\
 %D%/c/dzn/queue.h				\
 %D%/c/dzn/runtime.h

dist_noinst_DATA += %D%/c/dzn/config.h.in
nobase_include_headers += $(dist_runtime_c_dzn_DATA)

runtime_cdir = $(pkgdatadir)/runtime/c
dist_runtime_c_DATA =				\
 %D%/c/coroutine.c				\
 %D%/c/list.c					\
 %D%/c/locator.c				\
 %D%/c/map.c					\
 %D%/c/mem.c					\
 %D%/c/pump.c					\
 %D%/c/queue.c					\
 %D%/c/runtime.c

if have_pth
lib_LTLIBRARIES += %D%/libdzn.la
%C%_libdzn_la_HEADERS = $(dist_runtime_c_dzn_DATA)
%C%_libdzn_la_SOURCES = $(dist_runtime_c_DATA)

%C%_libdzn_ladir = $(includedir)/dzn

%C%_libdzn_la_CPPFLAGS = -I $(abs_top_srcdir)/runtime/c

%C%_libdzn_la_LDFLAGS =				\
 $(PTH_LIBS)					\
 -version-info $(version_info)			\
 -export-dynamic -no-undefined			\
 $(GNU_LD_FLAGS)
endif
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
 %D%/c++/dzn/std-async.hh				\
 %D%/c++/dzn/config.hh				\
 %D%/c++/dzn/container.hh			\
 %D%/c++/dzn/context.hh				\
 %D%/c++/dzn/coroutine.hh			\
 %D%/c++/dzn/locator.hh				\
 %D%/c++/dzn/meta.hh				\
 %D%/c++/dzn/pump.hh				\
 %D%/c++/dzn/runtime.hh

nobase_include_headers += $(dist_runtime_cxx_dzn_DATA)

dist_noinst_DATA += %D%/c++/dzn/config.hh.in %D%/c++/dzn/meta.hh.in

runtime_cxxdir = $(pkgdatadir)/runtime/c++
dist_runtime_cxx_DATA =				\
 %D%/c++/pump.cc				\
 %D%/c++/runtime.cc                             \
 %D%/c++/std-async.cc				\
 %D%/c++/thread-pool.cc

if have_mutex
lib_LTLIBRARIES += %D%/libdzn-c++.la
%C%_libdzn_c___la_HEADERS = $(dist_runtime_cxx_dzn_DATA)
%C%_libdzn_c___la_SOURCES =			\
 %D%/c++/pump.cc				\
 %D%/c++/runtime.cc

if dzn_thread_pool
%C%_libdzn_c___la_SOURCES += %D%/c++/thread-pool.cc
else
%C%_libdzn_c___la_SOURCES += %D%/c++/std-async.cc
endif

%C%_libdzn_c___ladir = $(includedir)/dzn

%C%_libdzn_c___la_CPPFLAGS =			\
 -I $(abs_top_srcdir)/runtime/c++

%C%_libdzn_c___la_LDFLAGS =			\
 -version-info $(version_info)			\
 -export-dynamic -no-undefined			\
 $(LIBBOOST_COROUTINE)				\
 $(GNU_LD_FLAGS)
endif
endif

if have_javascript
runtime_javascript_dzndir = $(pkgdatadir)/runtime/javascript/dzn
dist_runtime_javascript_dzn_DATA =		\
 %D%/javascript/dzn/runtime.js
endif
