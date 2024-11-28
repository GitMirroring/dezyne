# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
# Copyright © 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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
: ${CFLAGS="-g -O0 --std=c99"}
: ${CXXFLAGS="-g --std=c++11"}
AC_CONFIG_SRCDIR([dzn/parse.scm])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIRS([build-aux])

AM_INIT_AUTOMAKE([silent-rules subdir-objects -Woverride -Wno-portability])
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

dnl Check for SCMackerel sm:indent.
GUILE_MODULE_CHECK([have_smackerel_sm_indent],
   [(scmackerel indent)], [sm:indent], [has sm:indent])
if test "x$have_smackerel_sm_indent" != "xyes"; then
  AC_MSG_ERROR([SCMackerel's sm:indent is missing; please upgrade to 0.5.2.])
fi

dnl Check whether we're using Guile-Gcrypt 0.2.x or later.
AC_CACHE_CHECK([whether Guile-Gcrypt is available and recent enough],
  [dzn_cv_have_recent_guile_gcrypt],
  [GUILE_CHECK([retval],
    [(use-modules (gcrypt hash))
     (equal? (hash-algorithm sha256)
             (lookup-hash-algorithm 'sha256))])
   if test "$retval" = 0; then
     dzn_cv_have_recent_guile_gcrypt="yes"
   else
     dzn_cv_have_recent_guile_gcrypt="no"
   fi])
if test "x$dzn_cv_have_recent_guile_gcrypt" != "xyes"; then
  AC_MSG_ERROR([A recent Guile-Gcrypt could not be found; please install it.])
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
  [AS_IF([echo 'init delta;' | $MCRL22LPS | $LPS2LTS --save-at-end --out=aut - /dev/null 2>&5], [ac_cv_lps2lts_stdout=yes], [ac_cv_lps2lts_stdout=no])])
if test "x$ac_cv_lps2lts_stdout" = xno; then
   AC_MSG_ERROR([Please install an lps2lts that writes valid LTSs to stdout])
fi

dnl Check whether lps2lts supports --threads=N
dnl For cross-compiling, use ./configure ac_cv_lps2lts_threads=yes
AC_CACHE_CHECK([whether lps2lts supports --threads], [ac_cv_lps2lts_threads],
  [AS_IF([echo 'init delta;' | $MCRL22LPS | $LPS2LTS --threads=1 --save-at-end --out=aut - /dev/null 2>&5], [ac_cv_lps2lts_threads=yes], [ac_cv_lps2lts_threads=no])])
if test "x$ac_cv_lps2lts_threads" = xno; then
   AC_MSG_ERROR([Please update mCRL2 to 202307.1])
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

LT_INIT()
LIBDZN_INTERFACE_CURRENT=0
LIBDZN_INTERFACE_REVISION=0
LIBDZN_INTERFACE_AGE=0
LIBDZN_INTERFACE="${LIBDZN_INTERFACE_CURRENT}:${LIBDZN_INTERFACE_REVISION}:${LIBDZN_INTERFACE_AGE}"
AC_SUBST(LIBDZN_INTERFACE_CURRENT)
AC_SUBST(LIBDZN_INTERFACE_REVISION)
AC_SUBST(LIBDZN_INTERFACE_AGE)
AC_SUBST(LIBDZN_INTERFACE)

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

AC_DEFINE_UNQUOTED([DZN_VERSION_ASSERT], [1],
  [Define whether to enable the dzn version assert.])
AC_SUBST(DZN_VERSION_ASSERT)

AX_PTHREAD([have_pthread=yes], [have_pthread=no])
AC_LANG_PUSH([C++])
AX_BOOST_BASE([1.67])
AC_CHECK_HEADER([mutex])
AC_CHECK_TYPE([std::mutex], [have_mutex=yes], [have_mutex=no],[#include <mutex>])
AC_CHECK_HEADERS([boost/coroutine/all.hpp],
  [have_boost_coroutine=$want_boost
   HAVE_BOOST_COROUTINE=$want_boost
   dzn_thread_pool=no],
  [have_boost_coroutine=no
   dzn_thread_pool="$have_mutex"])
if test "x$have_boost_coroutine" = "xyes"; then
   AC_DEFINE_UNQUOTED([HAVE_BOOST_COROUTINE], [1],
      [Define if you have the boost coroutine library.])
fi
AC_LIB_HAVE_LINKFLAGS([boost_coroutine], [],
  [#include <boost/coroutine/all.hpp>],
  [boost::coroutines::stack_traits::default_size ();])
AC_LANG_POP()
AC_SUBST(HAVE_BOOST_COROUTINE)

AC_ARG_ENABLE([c++-thread-pool], [AC_HELP_STRING([--disable-c++-thread-pool],
  [Disable the C++ thread-pool?])],
  [dzn_thread_pool="$enableval"],
  [dzn_thread_pool="$dzn_thread_pool"])

AC_LANG_PUSH([C])
AC_CHECK_HEADERS([pth.h],[have_pth=yes],[have_pth=no])
AC_LIB_HAVE_LINKFLAGS([pth],[],[#include <pth.h>], [pth_init ();])
AC_LANG_POP()
case ,${enable_languages}, in
  *,c,*)
if test "x$courageous" = xno; then
    AC_MSG_ERROR([`c' is not a supported language.
See "Porting" in the manual, or try `--with-courage'.])
fi
if test "x$HAVE_LIBPTH" != "xyes" -a x$cross_compiling = xno; then
    AC_MSG_ERROR([GNU Pth is required, please install it.])
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
AM_CONDITIONAL([have_boost], [test "x$have_boost" = xtrue])
AM_CONDITIONAL([have_mutex], [test "x$have_mutex" = xyes])
AM_CONDITIONAL([have_pth], [test "x$have_pth" = xyes])
AM_CONDITIONAL([have_pthread], [test "x$have_pthread" = xyes])
AM_CONDITIONAL([dzn_thread_pool], [test "x$dzn_thread_pool" = xyes])
AM_CONDITIONAL([have_javascript], [test "x$have_javascript" = xtrue])
AM_CONDITIONAL([have_scheme], [test "x$have_scheme" = xtrue])

languages=`echo "$enable_languages" | sed 's/, *,/,/g' | tr , ' '`
AC_SUBST(languages)

AC_MSG_CHECKING([if building from git])
if test -e .git; then
   in_git_p=yes
else
   in_git_p=no
fi
AC_MSG_RESULT([$in_git_p])
AM_CONDITIONAL([in_git_p],
  [test "x$in_git_p" = "xyes"])

# Output
AUTOHEADER=true
AC_CONFIG_HEADERS([runtime/c/dzn/config.h])
AC_CONFIG_HEADERS([runtime/c++/dzn/config.hh])
AC_CONFIG_FILES([config.make:build-aux/config.make.in])
AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([pre-inst-env:build-aux/pre-inst-env.in],
                [chmod +x pre-inst-env])
AC_CONFIG_FILES([test/bin/run:test/bin/run.in],
                [chmod +x test/bin/run])
AC_CONFIG_FILES([test/bin/run-baseline:test/bin/run-baseline.in],
                [chmod +x test/bin/run-baseline])
AC_CONFIG_FILES([test/bin/run-build:test/bin/run-build.in],
                [chmod +x test/bin/run-build])
AC_CONFIG_FILES([test/bin/run-execute:test/bin/run-execute.in],
                [chmod +x test/bin/run-execute])
AC_CONFIG_FILES([runtime/c++/dzn/meta.hh])

AC_OUTPUT

cat <<EOF

    Dezyne is configured for languages: $languages
    Use Boost::Coroutine for C++:        $have_boost_coroutine
    Use C++ thread pool:                 $dzn_thread_pool
EOF
