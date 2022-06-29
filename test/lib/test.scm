#! @GUILE@ \
--no-auto-compile -L @OUT@/../../scheme -L @OUT@ -L runtime/scheme
!#
(add-to-load-path "@OUT@/../../scheme")
(add-to-load-path "@OUT@")
(add-to-load-path "runtime/scheme")
((@ (main) main) (command-line))
