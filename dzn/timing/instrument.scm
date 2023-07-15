;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn timing instrument)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (oop goops)

  #:use-module (dzn misc)
  #:use-module (dzn timing)

  #:export (display-measurements
            instrument-timings))

;;;
;;; Resolvers.
;;;
(define-method (resolve-method (module <module>) (name <symbol>) (specializers <list>))
  (let* ((procedure (module-ref module name))
         (method? (is-a? procedure <generic>))
         (generic procedure)
         (methods (slot-ref generic 'methods)))
    (or (find (compose (cute equal? <> specializers)
                       (cute slot-ref <> 'specializers))
              methods)
        (throw 'no-such-method (format #f "(~a ~a) in module ~a"
                                       name
                                       (map class-name specializers)
                                       (module-name module))))))

(define (resolve-module* name)
  (let* ((module (resolve-module name))
         (variables (module-map cons module)))
    (when (null? variables)
      (throw 'no-such-module module))
    module))


;;;
;;; Wrapping.
;;;
(define-method (wrap (module <module>) (procedure <procedure>) (wrapper-generator <procedure>))
  (let ((name (procedure-name procedure))
        (wrapper (wrapper-generator module procedure)))
    (module-define! module name wrapper)))

(define-method (wrap (module <module>) (method <method>) (wrapper-generator <procedure>))
  (let* ((procedure (slot-ref method 'procedure))
         (generic (slot-ref method 'generic-function))
         (name (procedure-name generic)))
    (set-procedure-property! procedure 'name name)
    (let ((wrapper (wrapper-generator module procedure)))
      (slot-set! method 'procedure wrapper))))

(define-method (wrap (module <module>) (name <symbol>) (wrapper-generator <procedure>))
  (wrap module (module-ref module name) wrapper-generator))

(define-method (wrap (wrapper-generator <procedure>) (module <list>) (name <symbol>))
  (wrap (resolve-module* module) name wrapper-generator))

(define-method (wrap (module <module>) (name <symbol>) (specializers <list>) (wrapper-generator <procedure>))
  (wrap module (resolve-method module name specializers) wrapper-generator))

(define-method (wrap (wrapper-generator <procedure>) (module <list>) (name <symbol>) (specializers <list>))
  (wrap (resolve-module* module) name specializers wrapper-generator))


;;;
;;; Timing.
;;;
(define-method (display-duration-wrapper (module <module>) (o <procedure>))
  (let* ((label (procedure-name o))
         (wrapper (lambda args
                    (display-duration label (apply o args)))))
    (set-procedure-property! wrapper 'name label)
    wrapper))


;;;
;;; Measuring.
;;;
(define-method (name->accu (name <symbol>))
  (string->symbol (format #f "%~a" name)))

(define-method (name->accu (module <module>) (name <symbol>))
  (module-ref module (name->accu name)))

(define-method (module-define-accu! (module <module>) (name <symbol>))
  (let ((accu (name->accu name)))
    (module-define! module accu 0)))

(define-method (module-define-accu! (module <list>) (name <symbol>) . rest)
  (module-define-accu! (resolve-module* module) name))

(define-method (measure-duration-wrapper (module <module>) (o <procedure>))
  (let* ((label (procedure-name o))
         (accu (name->accu label))
         (wrapper (lambda args
                    (let ((result t1 t2 (measure-duration module accu
                                                          (apply o args))))
                      (apply values result)))))
    (set-procedure-property! wrapper 'name label)
    wrapper))


;;;
;;; Display.
;;;
(define-method (measure-display-wrapper (module <module>) (o <procedure>)
                                        (display-measurements <procedure>))
  (let* ((label (procedure-name o))
         (wrapper (lambda args
                    (catch 'quit
                      (lambda _
                        (apply o args)
                        (display-measurements))
                      (lambda (key . args)
                        (display-measurements)
                        (apply throw key args))))))
    (set-procedure-property! wrapper 'name label)
    wrapper))

(define-method (display-measurement (module <module>) (name <symbol>))
  (let ((accu (name->accu module name)))
    (display-runtime name accu)))

(define-method (display-measurement (module <list>) (name <symbol>) . rest)
  (display-measurement (resolve-module* module) name))


;;;
;;; Entry points.
;;;
(define-method (instrument-timings (time <list>) measure)
  (for-each (cute apply module-define-accu! <>) measure)
  (for-each (cute apply wrap (cute measure-duration-wrapper <> <>) <>) measure)
  (apply wrap (cute measure-display-wrapper <> <> (cute display-measurements measure))
         `(,@(car time)))
  (for-each (cute apply wrap (cute display-duration-wrapper <> <>) <>) time))

(define-method (instrument-timings (time <list>))
  (instrument-timings (time '())))

(define-method (display-measurements (measure <list>))
  (for-each (cute apply display-measurement <>) measure))
