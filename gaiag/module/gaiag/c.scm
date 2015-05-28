;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag c)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (gaiag list match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag code)
  :use-module (gaiag gaiag)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
;;  :use-module (gaiag wfc)

  :use-module (gaiag ast)

  :export (ast->))

(define (ast-> ast)
  (let ((om ((om:register code:om) ast #t)))
    (parameterize ((indenter (lambda () (indent 1))))
      (map dump (filter (negate om:imported?) ((om:filter <model>) om)))))
  "")

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    (($ <component>) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  (let ((name (.name o)))
    (dump-indented (symbol-append name (code:extension o))
                   (lambda () (c-file (c-name o) (code:module o))))
    (and-let* ((code-name (symbol-append name (code:extension (make <component>))))
               (template (template-file `(,(language) interface ,(symbol-append (code:extension (make <component>)) '.scm))))
               ((file-exists? (components->file-name template))))

              (dump-indented code-name
                             (lambda () (c-file (c-code o) (code:module o)))))))

(define (dump-component o)
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append name (code:extension (make <interface>)))
                   (lambda ()
                     (c-file (c-header o) (code:module o))))
    (if (.behaviour o)
        (dump-indented (symbol-append name (code:extension o))
                       (lambda ()
                         (c-file (c-name o) (code:module o)))))
    (dump-main o)))

(define (dump-system o)
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o))))
        (components (map code:import (map .component ((compose .elements .instances) o)))))
    (dump-indented (symbol-append name (code:extension (make <interface>)))
                   (lambda ()
                     (c-file (c-header o) (code:module o))))
    (dump-indented (symbol-append name (code:extension o))
                   (lambda ()
                     (c-file (c-name o) (code:module o))))
    (dump-main o)))

(define (dump-main o)
  (and-let* ((name (.name o))
             (model (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                                string->symbol)))
             ((eq? model name)))
            (dump-indented (symbol-append 'main (code:extension o))
                           (lambda ()
                             (c-file (symbol-append 'main (code:extension o) '.scm)  (code:module o))))))


(define (c-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (animate-file file-name module)))

(define (c-name o)
  (symbol-append (ast-name o) (code:extension o) '.scm))

(define (c-code o)
  (symbol-append (ast-name o) (code:extension (make <component>)) '.scm))

(define (c-header o)
  (symbol-append (ast-name o) (code:extension (make <interface>)) '.scm))
