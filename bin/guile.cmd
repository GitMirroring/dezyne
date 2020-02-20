@echo off
if not exist tmp mkdir tmp
set TMPDIR=tmp
set prefix=.
set GUILE_AUTO_COMPILE=0
set GUILE_LOAD_PATH=%GUILE_LOAD_PATH%;%prefix%/share/guile/site/2.2;%prefix%/share/guile/2.2
set GUILE_LOAD_COMPILED_PATH=%GUILE_LOAD_COMPILED_PATH%;%prefix%/lib/guile/2.2/site-ccache;%prefix%/lib/guile/2.2/ccache
set HOME=%USERPROFILE%
set PATH=%~p0;%~p0/lib;%PATH%
guile.exe %*
