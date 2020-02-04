# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
AC_CONFIG_SRCDIR([gaiag/parse.scm])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([build-aux])

AM_INIT_AUTOMAKE([silent-rules subdir-objects])
AM_SILENT_RULES([yes])

AC_PATH_PROG([GUIX], [guix])
AM_CONDITIONAL([have_guix], [test "x$GUIX" != ""])

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

dnl Check for Guile piped-process
dnl For cross-compiling (with patched Guile), use ./configure ac_cv_guile_piped_process=yes
AC_CACHE_CHECK([for Guile piped-process], [ac_cv_guile_piped_process],
  [AS_IF([$GUILE -c '(@ (ice-9 popen) piped-process)' 2>&5], [ac_cv_guile_piped_process=yes], [ac_cv_guile_piped_process=no])])
AC_SUBST([have_guile_piped_process], [$ac_cv_guile_piped_process])

AC_PATH_PROG([PERL5], [perl5 perl])
AC_PATH_PROG([M4_CW], [m4-cw])
AC_PATH_PROG([MCRL22LPS], [mcrl22lps])
AC_PATH_PROG([LPS2LTS], [lps2lts])
AC_PATH_PROG([LTSCOMPARE], [ltscompare])
AS_IF([test "x$LPS2LTS" = "x"], AC_MSG_ERROR([lps2lts from mCRL2 is missing; please install it.]))
AS_IF([test "x$MCRL22LPS" = "x"], AC_MSG_ERROR([mcrl22lps from mCRL2 is missing; please install it.]))
AS_IF([test "x$LTSCOMPARE" = "x"], AC_MSG_ERROR([ltscompare from mCRL2 is missing; please install it.]))

dnl Check whether lps2lts can produce a valid lts on stdout
dnl This patch also has lps2lts read from stdin
dnl For cross-compiling (with patched mCRL2), use ./configure ac_cv_lps2lts_stdout=yes
AC_CACHE_CHECK([whether lps2lts writes valid lts to from stdout], [ac_cv_lps2lts_stdout],
  [AS_IF([echo 'init delta;' | $MCRL22LPS | $LPS2LTS - 2>&5], [ac_cv_lps2lts_stdout=yes], [ac_cv_lps2lts_stdout=no])])
AC_SUBST([have_lps2lts_stdout], [$ac_cv_lps2lts_stdout])

dnl Check whether ltscompare can read two LTSes from stdin
dnl For cross-compiling (with patched mCRL2), use ./configure ac_cv_lpscompare_stdin=yes
AC_CACHE_CHECK([whether ltscompare can read two LTSes from stdin], [ac_cv_ltscompare_stdin],
  [AS_IF([echo -e 'des (0,1,1)\n(0,stays,0)\ndes (0,1,1)\n(0,stays,0)\n' | $LTSCOMPARE -pweak-failures  --in1=aut --in2=aut - - 1>&5 2>&5], [ac_cv_ltscompare_stdin=yes], [ac_cv_ltscompare_stdin=no])])
AC_SUBST([have_ltscompare_stdin], [$ac_cv_ltscompare_stdin])

dnl Check whether ltscompare can produce structured output
dnl For cross-compiling (with patched mCRL2), use ./configure ac_cv_lpscompare_structured_output=yes
AC_CACHE_CHECK([whether ltscompare produce structured output], [ac_cv_ltscompare_structured_output],
  [AS_IF([echo -e 'des (0,1,1)\n(0,stays,0)\ndes (0,1,1)\n(0,stays,0)\n' | $LTSCOMPARE -pweak-failures --structured-output --in1=aut --in2=aut - - 1>&5 2>&5], [ac_cv_ltscompare_structured_output=yes], [ac_cv_ltscompare_structured_output=no])])
AC_SUBST([have_ltscompare_structured_output], [$ac_cv_ltscompare_structured_output])

if test "$PACKAGE_VERSION" = UNKNOWN; then
    PACKAGE_VERSION=0.0.0
fi
VERSION_MAJOR=[$(expr $PACKAGE_VERSION : '\([0-9]\+\)[.]')]
VERSION_MINOR=[$(expr $PACKAGE_VERSION : '[0-9]\+[.]\([0-9]\+\)')]
VERSION_PATCH=[$(expr $PACKAGE_VERSION : '[0-9]\+[.][0-9]\+[.]\([0-9]\+\)[^ ]*')]
if test "x$VERSION_PATCH" = "x"; then
   VERSION_PATCH=[-$(expr $PACKAGE_VERSION : '[0-9]\+[.][0-9]\+[.]rc\([0-9]\+\)[^ ]*')]
fi
if test "x$VERSION_PATCH" = "x"; then
   VERSION_PATCH=0
fi
VERSION_COMMIT=[$(expr $PACKAGE_VERSION : '[0-9]\+[.][0-9]\+[.][0-9]\+\([^ ]*\)')]
AC_SUBST([VERSION_MAJOR])
AC_SUBST([VERSION_MINOR])
AC_SUBST([VERSION_PATCH])
AC_SUBST([VERSION_COMMIT])

AM_CONDITIONAL([CROSS_COMPILING], [test x$cross_compiling = xyes])

# Test framework
all_languages=""
if test "x$courageous" = "xyes"; then
   all_languages="$all_languages,scheme"
fi

AC_ARG_WITH([courage], [AC_HELP_STRING([--with-courage], [Assert that
  even if this language is unsupported, you will be courageous and
  add/finish Dezyne support for it (see "Porting" in the manual.)])],
  [courageous="$withval"], [courageous="no"])

AC_PROG_CXX
_AC_PROG_CXX_CXX11([have_cxx11=true])

if test "x$have_cxx11" = "xtrue"; then
   CXX11="$CXX"
   all_languages="$all_languages,c++"
fi
AC_SUBST([CXX11])

AX_BOOST_BASE([1.67], [have_boost=yes])
if test "x$have_boost" = "xyes"; then
   if test "x$courageous" = "xyes"; then
      CXX03="$CXX"
      all_languages="$all_languages,c++03"
   fi
fi
AC_SUBST([CXX03])

AC_PROG_CC
AC_PROG_CC_C99
if test "xx$ac_cv_prog_cc_c99" != "xyes"; then
   CC99=
else
   if test "x$courageous" = "xyes"; then
      CC99="$CC"
      all_languages="$all_languages,c"
   fi
fi

AC_PATH_PROGS([MCS], [mcs])
if test "x$MCS" != "x"; then
   if test "x$courageous" = "xyes"; then
      all_languages="$all_languages,cs"
   fi
fi

AC_PATH_PROGS([NODEJS], [nodejs node])
if test "x$NODEJS" != "x"; then
   if test "x$courageous" = "xyes"; then
      all_languages="$all_languages,javascript"
   fi
fi

AC_ARG_ENABLE([languages], [AS_HELP_STRING([[--enable-languages=LANGUAGES [default=all] {all|LANG[,LANG...]}]],
   [choose languages to build for])],
   [enable_languages="$enableval"],
   [enable_languages="$all_languages"])

case ,${enable_languages}, in
  *,c++,*)
if test "x$CXX11" = x; then
    AC_MSG_ERROR([language c++ enabled, but no C11 compiler was not found])
fi
have_cxx11=true
;;
esac

case ,${enable_languages}, in
  *,c++03,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`c++03' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
if test "x$CXX03" = x; then
    AC_MSG_ERROR([language c++03 enabled, but no C++ compiler with boost was not found])
fi
have_cxx03=true
;;
esac

case ,${enable_languages}, in
  *,c,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`c' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
if test "x$CC99" = x; then
    AC_MSG_ERROR([language c enabled, but no C99 compiler was not found])
fi
have_c99=true
;;
esac

case ,${enable_languages}, in
  *,javascript,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`javascript' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
if test "x$NODEJS" = x; then
    AC_MSG_ERROR([language javascript enabled, but nodejs was not found])
fi
have_javascript=true
;;
esac

case ,${enable_languages}, in
  *,cs,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`cs' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
if test "x$NODEJS" = x; then
    AC_MSG_ERROR([language cs enabled, but nodejs was not found])
fi
have_cs=true
;;
esac

case ,${enable_languages}, in
  *,scheme,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`scheme' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
have_scheme=true
;;
esac

AM_CONDITIONAL([have_c99], [test "x$have_c99" = xtrue])
AM_CONDITIONAL([have_cs], [test "x$have_cs" = xtrue])
AM_CONDITIONAL([have_cxx03], [test "x$have_boost" = xtrue])
AM_CONDITIONAL([have_cxx11], [test "x$have_cxx11" = xtrue])
AM_CONDITIONAL([have_javascript], [test "x$have_javascript" = xtrue])
AM_CONDITIONAL([have_scheme], [test "x$have_scheme" = xtrue])

languages=`echo "$enable_languages" | sed s/,,/,/g | tr , ' '`
AC_SUBST(languages)

# Output
AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([pre-inst-env:build-aux/pre-inst-env.in],
                [chmod +x pre-inst-env])
AC_CONFIG_FILES([test/bin/reorder:test/bin/reorder.in],
                [chmod +x test/bin/reorder])
AC_CONFIG_FILES([test/bin/run:test/bin/run.in],
                [chmod +x test/bin/run])
AC_CONFIG_FILES([runtime/c++/dzn/meta.hh])

AC_OUTPUT

cat <<EOF

    Dezyne is configured for languages: $languages
EOF
