set script=%~dp0
set prefix=%script:~0,-1%
set GUILE_AUTO_COMPILE=0
set GUILE_LOAD_PATH=%GUILE_LOAD_PATH%;%prefix%/share/guile/site/2.2;%prefix%/share/guile/2.2
set GUILE_LOAD_COMPILED_PATH=%GUILE_LOAD_COMPILED_PATH%;%prefix%/lib/guile/2.2/site-ccache;%prefix%/lib/guile/2.2/ccache
set HOME=%USERPROFILE%
set PATH=%prefix%;%prefix%/lib;%PATH%
guile dzn %1 %2 %3 %4 %5 %6 %7 %8 %9
