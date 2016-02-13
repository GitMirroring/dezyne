;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (ice-9 pretty-print)
  :use-module (gaiag list match)

  :use-module (srfi srfi-1)

  :use-module (gaiag om)

  :use-module (gaiag evaluate)
  :use-module (gaiag json)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag run)

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
  `((type . init)
    (models . ,(map model->node-alist
                    (if (is-a? model <component>)
                        (cons model (map (compose om:import .type) (.elements (.ports model))))
                        (list model))))))

(define (json-state model state)
  (append
   `((type . update)
     (comp . ,(.name model))
     (state . ,(state->json state)))))

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
  (map
   (lambda (s)
     (cons ((@@(gaiag run) ->string) (car s))
           ((@@(gaiag run) ->string) (cdr s))))
   state))

(define (json-trace model trace)
  ;;  (stderr "json-trace: ~a\n" (.name model))
  (let ((name ((om:scope-name '.) model)))
    (let loop ((trace trace) (trigger (make <trigger>)) (state (state-vector model)) (trail '()))
      ;;(stderr "JSON: ~a\n" (if (pair? trace) (car trace)))
      (cond
       ((null? trace) (list '()))

       ;; FIXME
       ((eq? (ast-name (car trace)) 'eligible)
        (let ((eligible (cdar trace)))
          (cons `((type . eligible)
                  (events . ,(map ->symbol eligible)))
                (loop (cdr trace) trigger state trail))))
       ((eq? (ast-name (car trace)) 'state)
        (let ((state (cadar trace)))
         (cons
          `((type . state)
            (state . ,(state->json state)))
          (loop (cdr trace) trigger state trail))))
       ((eq? (ast-name (car trace)) 'trail)
        (let ((trail (cdar trace)))
          (cons
           `((type . trail)
             (trail . ,trail))
           (loop (cdr trace) trigger state trail))))
       ((eq? (ast-name (car trace)) 'matched)
        (let ((matched (cdar trace)))
          (cons
           `((type . matched)
             (trail . ,matched))
           (loop (cdr trace) trigger state trail))))
       ((eq? (ast-name (car trace)) 'error)
        (let ((error (cdar trace)))
          (cons
           `((type . error)
             (trail . ,error))
           (loop (cdr trace) trigger state trail))))
       ((is-a? (car trace) <trigger>)
        (loop (cdr trace) (car trace) state trail))
       (else
        (let* ((statement (car trace))
               (type (and=> statement ast-name))
               (location
                `((begin . ,(json-location statement))
                  (end . ,(json-location (or (and (pair? trace) (last trace)) statement)))))
               (message
                (let* ((component (and (om:parent model statement) name))
                       (instance (if (is-a? model <interface>) name
                                     component))
                       (event
                        (match statement
                          (($ <on> ('triggers t h ...))
                           (if (and component (.event trigger)) (->symbol trigger)
                               (.event trigger)))
                          (($ <action> trigger)
                           (if (and (is-a? model <component>)
                                    (.port trigger))
                               (set! instance name))
                           (->symbol (.trigger statement)))
                          (($ <illegal>) 'illegal)
                          (($ <literal> scope type field) (symbol-append scope '. type '_ field))
                          (($ <return> ($ <expression>)) #f)
                          (($ <return> 'return)
                           (and (is-a? model <interface>) 'return))
                          (($ <return> #f) #f)
                          (($ <return> value)
                           (cond
                            ((and (is-a? model <component>)
                                  (symbol? value)
                                  (let ((split (symbol-split value #\.)))
                                    (=2 (length split))))
                             (set! instance name)
                             value)
                            ((is-a? model <interface>) value)
                            (else #f)))
                          (_ #f))))
                  `((type . step)
                    (type . ,type)
                    (instance . ,instance)
                    (event . ,event)
                    (state . ,(state->json state))
                    (trail . ,trail)
                    (location . ,location)))))
          (cons message (loop (cdr trace) trigger state trail))))))))
