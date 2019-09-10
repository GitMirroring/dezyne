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

AC_INIT([Dezyne command-line],
        [m4_esyscmd([build-aux/git-version-gen .tarball-version])],
        [bug-dezyne@nongnu.org],
        [dzn])
AC_CONFIG_SRCDIR([dzn/parse.scm])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([build-aux])

AM_INIT_AUTOMAKE([silent-rules subdir-objects])
AM_SILENT_RULES([yes])

GUILE_PKG([3.0 2.2 2.0])
GUILE_PROGS
GUILE_SITE_DIR
GUILE_FLAGS

#GUILE_SITE_DIR
guilemoduledir="${datarootdir}/guile/site/$GUILE_EFFECTIVE_VERSION"
guileobjectdir="${libdir}/guile/$GUILE_EFFECTIVE_VERSION/site-ccache"
AC_SUBST([guilemoduledir])
AC_SUBST([guileobjectdir])

dnl Check for Guile-JSON.
GUILE_MODULE_AVAILABLE([have_guile_json], [(json)])
if test "x$have_guile_json" != "xyes"; then
  AC_MSG_ERROR([Guile-JSON is missing; please install it.])
fi

AC_PATH_PROG([PERL5], [perl5 perl])
AC_PATH_PROG([M4_CW], [m4-cw])
AC_PATH_PROG([LTS], [lts])
AC_PATH_PROG([MCRL22LPS], [mcrl22lps])

VERSION_MAJOR=[$(expr $PACKAGE_VERSION : '\([0-9]\+\)[.][0-9]\+[.][0-9][^ ]*')]
VERSION_MINOR=[$(expr $PACKAGE_VERSION : '[0-9]\+[.]\([0-9]\+\)[.][0-9][^ ]*')]
VERSION_PATCH=[$(expr $PACKAGE_VERSION : '[0-9]\+[.][0-9]\+[.]\([0-9]\+\)[^ ]*')]
VERSION_COMMIT=[$(expr $PACKAGE_VERSION : '[0-9]\+[.][0-9]\+[.][0-9]\+\([^ ]*\)')]
AC_SUBST([VERSION_MAJOR])
AC_SUBST([VERSION_MINOR])
AC_SUBST([VERSION_PATCH])
AC_SUBST([VERSION_COMMIT])

AM_CONDITIONAL([CROSS_COMPILING], [test x$cross_compiling = xyes])

AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([pre-inst-env:build-aux/pre-inst-env.in],
                [chmod +x pre-inst-env])
AC_CONFIG_FILES([runtime/c++/dzn/meta.hh])
AC_CONFIG_FILES([runtime/c++-msvc11/dzn/meta.hh])
AC_CONFIG_FILES([runtime/c++03/dzn/meta.hh])

AC_OUTPUT
