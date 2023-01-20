# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

AC_INIT([Dezyne],
        [m4_esyscmd([build-aux/git-version-gen .tarball-version])],
        [bug-dezyne@nongnu.org],
        [dezyne])
AC_CONFIG_SRCDIR([dzn/parse.scm])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([build-aux])

AM_INIT_AUTOMAKE([silent-rules subdir-objects])
AM_SILENT_RULES([yes])

AM_PATH_LISPDIR
AC_PATH_PROG([GUIX], [guix])
AM_CONDITIONAL([have_guix], [test "x$GUIX" != ""])

GUILE_PKG([3.0 2.2 2.0])
GUILE_PROGS
GUILE_SITE_DIR
GUILE_FLAGS

if test "x$GUILD" = "x"; then
   AC_MSG_ERROR(['guild' binary not found; please check your Guile installation.])
fi

#GUILE_SITE_DIR
guilemoduledir="${datarootdir}/guile/site/$GUILE_EFFECTIVE_VERSION"
guileobjectdir="${libdir}/guile/$GUILE_EFFECTIVE_VERSION/site-ccache"
AC_SUBST([guilemoduledir])
AC_SUBST([guileobjectdir])

dnl Check for Guile pipeline.
GUILE_MODULE_CHECK([have_guile_pipeline], [(ice-9 popen)],
   [pipeline], [has pipeline])
if test "x$have_guile_pipeline" != "xyes"; then
  AC_MSG_ERROR([Guile's pipeline is missing; please upgrade or patch Guile.])
fi

dnl Check for Guile-JSON.
GUILE_MODULE_AVAILABLE([have_guile_json], [(json)])
if test "x$have_guile_json" != "xyes"; then
  AC_MSG_ERROR([Guile-JSON is missing; please install it.])
fi

dnl Check for Guile readline support.
GUILE_MODULE_AVAILABLE([have_guile_readline], [(ice-9 readline)])
if test "x$have_guile_readline" != "xyes"; then
  AC_MSG_ERROR([Guile readline support is missing; please install it.])
fi

dnl Check for SCMackerel.
GUILE_MODULE_AVAILABLE([have_scmackerel], [(scmackerel processes)])
if test "x$have_scmackerel" != "xyes"; then
  AC_MSG_ERROR([SCMackerel is missing; please install it.])
fi

AC_PATH_PROG([HELP2MAN], [help2man])
AM_CONDITIONAL([have_help2man], [test -n "$HELP2MAN"])
AC_PATH_PROGS([PERL5], [perl5 perl])
AC_PATH_PROG([MCRL22LPS], [mcrl22lps])
AC_PATH_PROG([LPS2LTS], [lps2lts])
AC_PATH_PROG([LTSCOMPARE], [ltscompare])
AS_IF([test "x$LPS2LTS" = "x"], AC_MSG_ERROR([lps2lts from mCRL2 is missing; please install it.]))
AS_IF([test "x$MCRL22LPS" = "x"], AC_MSG_ERROR([mcrl22lps from mCRL2 is missing; please install it.]))
AS_IF([test "x$LTSCOMPARE" = "x"], AC_MSG_ERROR([ltscompare from mCRL2 is missing; please install it.]))

dnl Check whether lps2lts can produce a valid lts on stdout
dnl This patch also has lps2lts read from stdin
dnl For cross-compiling (with patched mCRL2), use ./configure ac_cv_lps2lts_stdout=yes
AC_CACHE_CHECK([whether lps2lts writes valid lts to stdout], [ac_cv_lps2lts_stdout],
  [AS_IF([echo 'init delta;' | $MCRL22LPS | $LPS2LTS --save-at-end --out=aut - - 2>&5], [ac_cv_lps2lts_stdout=yes], [ac_cv_lps2lts_stdout=no])])
if test "x$ac_cv_lps2lts_stdout" = xno; then
   AC_MSG_ERROR([Please install an lps2lts that writes valid LTSs to stdout])
fi

dnl Check whether ltscompare can read two LTSes from stdin
dnl For cross-compiling (with patched mCRL2), use ./configure ac_cv_lpscompare_stdin=yes
AC_CACHE_CHECK([whether ltscompare can read two LTSes from stdin], [ac_cv_ltscompare_stdin],
  [AS_IF([echo -e 'des (0,1,1)\n(0,stays,0)\n\004\ndes (0,1,1)\n(0,stays,0)\n' | $LTSCOMPARE -pweak-failures --in1=aut --in2=aut - - 1>&5 2>&5], [ac_cv_ltscompare_stdin=yes], [ac_cv_ltscompare_stdin=no])])
if test "x$ac_cv_ltscompare_stdin" = xno; then
   AC_MSG_ERROR([Please install an ltscompare that can read two LTSses form stdin])
fi

dnl Check whether ltscompare can produce structured output
dnl For cross-compiling (with patched mCRL2), use ./configure ac_cv_lpscompare_structured_output=yes
AC_CACHE_CHECK([whether ltscompare produce structured output], [ac_cv_ltscompare_structured_output],
  [AS_IF([echo -e 'des (0,1,1)\n(0,stays,0)\n\004\n\ndes (0,1,1)\n(0,stays,0)\n' | $LTSCOMPARE -pweak-failures --structured-output --in1=aut --in2=aut - - 1>&5 2>&5], [ac_cv_ltscompare_structured_output=yes], [ac_cv_ltscompare_structured_output=no])])
if test "x$ac_cv_ltscompare_structured_output" = xno; then
   AC_MSG_ERROR([Please install an ltscompare with --structured-output support])
fi

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
AC_ARG_WITH([courage], [AC_HELP_STRING([--with-courage], [Assert that
  even if this language is unsupported, you will be courageous and
  add/finish Dezyne support for it (see "Porting" in the manual.)])],
  [courageous="$withval"], [courageous="no"])

all_languages=""
if test "x$courageous" = "xyes"; then
   all_languages="$all_languages,scheme"
fi

AC_PROG_CXX
_AC_PROG_CXX_CXX11([have_cxx11=true])

if test "x$have_cxx11" = "xtrue"; then
   CXX11="$CXX"
   all_languages="$all_languages,c++"
fi
AC_SUBST([CXX11])

AC_PROG_CC
AC_PROG_CC_C99
if test "x$ac_cv_prog_cc_c99" != "xyes" -a "x$have_cxx11" != "xtrue"; then
   CC99=
else
   if test "x$courageous" = "xyes"; then
      CC99="$CC"
      all_languages="$all_languages,c"
   fi
fi

AC_PATH_PROGS([MCS], [mcs])
if test "x$MCS" != "x"; then
   all_languages="$all_languages,cs"
fi

AC_PATH_PROGS([NODE], [nodejs node])
if test "x$NODE" != "x"; then
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
if test "x$CXX11" = x -a x$cross_compiling = xno; then
    AC_MSG_ERROR([language c++ enabled, but no C11 compiler was found])
fi
have_cxx11=true
;;
  *)
have_cxx11=false
;;
esac

case ,${enable_languages}, in
  *,c,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`c' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
if test "x$CC99" = x -a x$cross_compiling = xno; then
    AC_MSG_ERROR([language c enabled, but no C99 compiler was found])
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
if test "x$NODE" = x -a x$cross_compiling = xno; then
    AC_MSG_ERROR([language javascript enabled, but nodejs was not found])
fi
have_javascript=true
;;
esac

case ,${enable_languages}, in
  *,cs,*)
if test x$MCS = x -a x$cross_compiling = xno; then
    AC_MSG_ERROR([language cs enabled, but mcs was not found])
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
AM_CONDITIONAL([have_cxx11], [test "x$have_cxx11" = xtrue])
AM_CONDITIONAL([have_javascript], [test "x$have_javascript" = xtrue])
AM_CONDITIONAL([have_scheme], [test "x$have_scheme" = xtrue])

languages=`echo "$enable_languages" | sed 's/, *,/,/g' | tr , ' '`
AC_SUBST(languages)

AC_ARG_ENABLE([c++-exception-wrappers],
   [AS_HELP_STRING([[--enable-c++-exception-wrappers]],
      [Build exception wrappers for c++ (experimental)])],
   [cxx_exception_wrappers="$enableval"],
   [cxx_exception_wrappers="no"])

case ${cxx_exception_wrappers} in
  yes)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`c++ execption-wrappers is an experimental feature, try `--with-courage'.])
fi
have_cxx_exception_wrappers=true
;;
esac

AM_CONDITIONAL([have_cxx_exception_wrappers], [test "x$have_cxx_exception_wrappers" = xtrue])

# Output
AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([pre-inst-env:build-aux/pre-inst-env.in],
                [chmod +x pre-inst-env])
AC_CONFIG_FILES([test/bin/run:test/bin/run.in],
                [chmod +x test/bin/run])
AC_CONFIG_FILES([test/bin/run-baseline:test/bin/run-baseline.in],
                [chmod +x test/bin/run-baseline])
AC_CONFIG_FILES([runtime/c++/dzn/meta.hh])

AC_OUTPUT

cat <<EOF

    Dezyne is configured for languages: $languages
    Experimental c++ exception wrappers: $cxx_exception_wrappers
EOF
