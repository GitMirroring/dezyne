;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag json-trace)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (gaiag list match)

  :use-module (srfi srfi-1)

  :use-module (gaiag json)
  :use-module (gaiag misc)
  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)
  :use-module (gaiag evaluate)
  :use-module (gaiag run)  

  :use-module (gaiag ast)

  :export (
           json-init
           json-state
           json-trace
           ))

(cond-expand
 (goops-om
  (use-modules (gaiag goops om)))
 (else #t))

;; FIXME: remove accidental complexity from JSON spec
(define (model->node-alist model)
  `((model . ,(.name model))
    (type . ,(ast-name model))
    (state . ,(state->json (state-vector model)))))

(define (json-init model)
  (alist->hash-table
   `((type . init)
     (models . ,(map alist->hash-table
                     (map model->node-alist
                          (if (is-a? model <component>)
                              (cons model (map (compose om:import .type) (.elements (.ports model))))
                              (list model))))))))

(define (json-state model state)
  (alist->hash-table
   (append
    `((type . update)
      (comp . ,(.name model))
      (state . ,(state->json state))))))

(define (from model event statement)
  (if (is-a? statement <on>)
      (.name model)
      #f))

(define (to model statement)
  (if (is-a? statement <on>)
      (.name model)
      (or (and-let* (((is-a? statement <action>))
                     (trigger (.trigger statement))
                     ((.port trigger)))
                    (.port trigger))
          'out)))

(define (event statement)
  (if (is-a? statement <on>)
      (.event (.trigger statement))
      (or (and-let* (((is-a? statement <action>))
                     (trigger (.trigger statement))
                     ((.port trigger)))
                    (.port trigger))
          'out)))

(define (state->json state)
  (alist->hash-table
   (map
    (lambda (s)
      (cons ((@@(gaiag run) ->string) (car s))
            ((@@(gaiag run) ->string) (cdr s))))
    state)))

(define (json-trace model trace)
  (let ((name (.name model)))
    (let loop ((trace trace) (trigger (make <trigger>)) (state (state-vector model)) (trail '()))
      (stderr "JSON: ~a\n" (if (pair? trace) (car trace)))
      (cond
       ((null? trace) (list (alist->hash-table '())))
       ((eq? (ast-name (car trace)) 'state)
        (let ((state (car trace)))
         (cons
          (alist->hash-table
           `((type . state)
             (state . ,(state->json state))))
          (loop (cdr trace) trigger state trail))))
       ((eq? (caar trace) 'trail)
        (let ((trail (car trace)))
          (cons
           (alist->hash-table
            `((type . trail)
              (trail . ,trail)))
           (loop (cdr trace) trigger state trail))))
       ((is-a? (car trace) <trigger>)
        (loop (cdr trace) (car trace) state trail))
       (else
        (let* ((statement (car trace))
               (type (and=> statement ast-name))
               (location (alist->hash-table
                          `((begin . ,(json-location statement))
                            (end . ,(json-location (or (and (pair? trace) (last trace)) statement))))))
               (message
                (alist->hash-table
                 (let* ((instance (and (om:parent model statement) name))
                        (event
                         (match statement
                           (($ <on> ('triggers t h ...)) (->symbol t))
                           (($ <action>) (->symbol (.trigger statement)))
                           (($ <literal> scope type field) (symbol-append scope '. type '_ field))
                           (($ <return> #f)
                            (let ((port (source-property statement 'port)))
                              (if port
                                  (symbol-append port '.return)
                                  'return)))
                           (($ <return> 'return)
                            (let ((port (or (source-property statement 'port)
                                            (and (is-a? model <component>)
                                                 (.name (om:port model))))))
                              (if (and port ;;(is-a? model <component>)
                                       )
                                  (symbol-append (source-property statement 'port) '.return)
                                  'return)))
                           (($ <return> value)
                            (let ((port (and (source-property statement 'port)
                                             (is-a? model <component>)
                                             (.name (om:port model)))))
                              (if (and port
                                       (is-a? model <component>)
                                       (=1 (length (symbol-split value #\.))) ;; FIXME AARRGH
                                       )
                                  (symbol-append (source-property statement 'port) '. value)
                                  value)))
                           (_ #f))))
                   `((type . step)
                     (type . ,type)
                     (instance . ,instance)
                     (from . ,(from model trigger statement))
                     (to . ,(to model statement))
                     (event . ,event)
                     (state . ,(state->json state))
                     (trail . ,trail)
                     (location . ,location))))))
          (cons message (loop (cdr trace) trigger state trail))))))))
