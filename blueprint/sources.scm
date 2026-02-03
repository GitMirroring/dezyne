;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (blueprint sources)
  #:export (scm-files
            no-compile-scm-files
            no-install-scm-files

            c++-scm-files
            c-scm-files
            cs-scm-files
            javascript-scm-files
            scheme-scm-files

            runtime-hh-files
            runtime-cc-files

            runtime-h-files
            runtime-c-files

            runtime-cs-files
            runtime-js-files
            runtime-scm-files))

(define scm-files
  '(;; dzn/
    "dzn/ast.scm"
    "dzn/code.scm"
    "dzn/command-line.scm"
    "dzn/explore.scm"
    "dzn/hash.scm"
    "dzn/lts.scm"
    "dzn/misc.scm"
    "dzn/parse.scm"
    "dzn/peg.scm"
    "dzn/pipe.scm"
    "dzn/script.scm"
    "dzn/shell-util.scm"
    "dzn/simulate.scm"
    "dzn/templates.scm"
    "dzn/test.scm"
    "dzn/timing.scm"
    "dzn/trace.scm"
    "dzn/transform.scm"

    ;; dzn/ast/
    "dzn/ast/accessor.scm"
    "dzn/ast/ast.scm"
    "dzn/ast/context.scm"
    "dzn/ast/display.scm"
    "dzn/ast/equal.scm"
    "dzn/ast/lookup.scm"
    "dzn/ast/normalize.scm"
    "dzn/ast/parse.scm"
    "dzn/ast/recursive.scm"
    "dzn/ast/serialize.scm"
    "dzn/ast/util.scm"
    "dzn/ast/wfc.scm"

    ;; dzn/code/
    "dzn/code/ast.scm"
    "dzn/code/shared.scm"
    "dzn/code/util.scm"

    ;; dzn/code/language/
    ;; NOTE: configure'd #%?languages handled separately
    "dzn/code/language/dot.scm"
    "dzn/code/language/dzn.scm"
    "dzn/code/language/makreel.scm"

    ;; dzn/code/legacy/
    "dzn/code/legacy/code.scm"
    "dzn/code/legacy/dzn.scm"

    ;; dzn/code/scmackerel/
    ;; NOTE: configure'd #%?languages handled separately
    "dzn/code/scmackerel/code.scm"
    "dzn/code/scmackerel/makreel.scm"

    ;; dzn/commands/
    "dzn/commands/anonymize.scm"
    "dzn/commands/code.scm"
    "dzn/commands/exec.scm"
    "dzn/commands/graph.scm"
    "dzn/commands/hash.scm"
    "dzn/commands/hello.scm"
    "dzn/commands/language.scm"
    "dzn/commands/lts.scm"
    "dzn/commands/parse.scm"
    "dzn/commands/simulate.scm"
    "dzn/commands/test.scm"
    "dzn/commands/trace.scm"
    "dzn/commands/traces.scm"
    "dzn/commands/verify.scm"

    ;; dzn/parse/
    "dzn/parse/complete.scm"
    "dzn/parse/location.scm"
    "dzn/parse/lookup.scm"
    "dzn/parse/peg.scm"
    "dzn/parse/stress.scm"
    "dzn/parse/tree.scm"
    "dzn/parse/util.scm"

    ;; dzn/peg/
    "dzn/peg/cache.scm"
    "dzn/peg/codegen.scm"
    "dzn/peg/simplify-tree.scm"
    "dzn/peg/string-peg.scm"
    "dzn/peg/using-parsers.scm"
    "dzn/peg/util.scm"

    ;; dzn/timing/
    "dzn/timing/instrument.scm"

    ;; dzn/verify/
    "dzn/verify/constraint.scm"
    "dzn/verify/pipeline.scm"

    ;; dzn/vm/
    "dzn/vm/ast.scm"
    "dzn/vm/compliance.scm"
    "dzn/vm/evaluate.scm"
    "dzn/vm/goops.scm"
    "dzn/vm/invariant.scm"
    "dzn/vm/normalize.scm"
    "dzn/vm/report.scm"
    "dzn/vm/run.scm"
    "dzn/vm/runtime.scm"
    "dzn/vm/step.scm"
    "dzn/vm/util.scm"))

(define no-compile-scm-files
  '("dzn/templates/code.scm"
    "dzn/templates/dot.scm"
    "dzn/templates/dzn.scm"
    "dzn/templates/javascript.scm"
    "dzn/templates/json.scm"
    "dzn/templates/scheme.scm"))

(define no-install-scm-files
  '("test/dzn/ast.scm"
    "test/dzn/automake.scm"
    "test/dzn/dzn.scm"
    "test/dzn/language.scm"
    "test/dzn/lts.scm"
    "test/dzn/makreel.scm"
    "test/dzn/normalize.scm"
    "test/dzn/parse.scm"))

(define c++-scm-files
  '("dzn/code/language/c++.scm"
    "dzn/code/scmackerel/c++.scm"))

(define c-scm-files
  '("dzn/code/language/c.scm"
    "dzn/code/scmackerel/c.scm"))

(define cs-scm-files
  '("dzn/code/language/cs.scm"
    "dzn/code/scmackerel/cs.scm"))

(define javascript-scm-files
  '("dzn/code/language/javascript.scm"))

(define scheme-scm-files
  '("dzn/code/language/scheme.scm"))

;;;

(define runtime-hh-files '())
(define have-c++-mutex? #%~#%?have-c++-mutex) ;FIXME: TODO
(define with-c++-thread-pool? #%~#%?with-c++-thread-pool?) ;FIXME:TODO
(define runtime-cc-files
  (append
   (if (not have-c++-mutex?) '()
       '("runtime/c++/coroutine.cc"
         "runtime/c++/pump.cc"
         "runtime/c++/runtime.cc"))
   (if with-c++-thread-pool? '("runtime/c++/thread-pool.cc")
       '("runtime/c++/std-async.cc"))))

(define extra-dist? ; FIXME: what about non-build: dist_runtime_cxx_DATA?
  '("runtime/c++/coroutine.cc"
    "runtime/c++/pump.cc"
    "runtime/c++/runtime.cc"
    "runtime/c++/std-async.cc"
    "runtime/c++/thread-pool.cc"))

(define runtime-h-files '())
(define runtime-c-files
  '("runtime/c/coroutine.c"
    "runtime/c/list.c"
    "runtime/c/locator.c"
    "runtime/c/map.c"
    "runtime/c/mem.c"
    "runtime/c/pump.c"
    "runtime/c/queue.c"
    "runtime/c/runtime.c"))

(define runtime-cs-files '())
(define runtime-js-files '())
(define runtime-scm-files '())
