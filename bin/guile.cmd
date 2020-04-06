@echo off
setlocal
if not exist tmp mkdir tmp
set LANG=C
set LC_ALL=C
set LC_CTYPE=C
set TMPDIR=tmp
set dir=.
set absdir=%~p0
set PREFIX=%absdir:\=/%
set GUILE_AUTO_COMPILE=0
set GUILE_LOAD_PATH=%GUILE_LOAD_PATH%;%dir%/share/guile/site/2.2;%dir%/share/guile/2.2
set GUILE_LOAD_COMPILED_PATH=%GUILE_LOAD_COMPILED_PATH%;%dir%/lib/guile/2.2/site-ccache;%dir%/lib/guile/2.2/ccache
set HOME=%USERPROFILE%
set PATH=%~p0;%~p0/bin;%~p0/lib;%PATH%
guile.exe %*
