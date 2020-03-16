@echo off
setlocal
if not exist tmp mkdir tmp
set LANG=C
set LC_ALL=C
set LC_ADDRESS=C
set LC_IDENTIFICATION=C
set LC_MEASUREMENT=C
set LC_MONETARY=C
set LC_NAME=C
set LC_NUMERIC=C
set LC_PAPER=C
set LC_TELEPHONE=C
set LC_TIME=C
set TMPDIR=tmp
set dir=.
set DZN_UNINSTALLED=1
set absdir=%~p0
set PREFIX=%absdir:\=/%
set GUILE_AUTO_COMPILE=0
set GUILE_LOAD_PATH=%GUILE_LOAD_PATH%;%dir%/share/guile/site/2.2;%dir%/share/guile/2.2
set GUILE_LOAD_COMPILED_PATH=%GUILE_LOAD_COMPILED_PATH%;%dir%/lib/guile/2.2/site-ccache;%dir%/lib/guile/2.2/ccache
set HOME=%USERPROFILE%
set PATH=%~p0;%~p0/bin;%~p0/lib;%PATH%
guile.exe %*
