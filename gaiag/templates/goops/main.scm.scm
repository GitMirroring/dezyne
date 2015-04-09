#! /bin/bash
# -*- scheme -*-
exec ${GUILE:-/usr/bin/guile-2.0} -L $(cd $(dirname $0); pwd) $GUILE_FLAGS -e '(@@ (dezyne) main)' -s "$0" "$@"
!#

(read-set! keywords 'prefix)

(define-module (dezyne)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (oop goops)
  :use-module (dezyne runtime)
  :use-module (dezyne #.model)
  :export (main))

(define (main . args)
  (format ##t "run\n"))
