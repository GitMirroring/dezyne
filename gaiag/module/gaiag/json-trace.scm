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
  :use-module (gaiag simulate)  

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

;; JSON output mangling disaster area

;; FIXME: mangling the trace output into the current json format takes
;; about as much effort as producing it?

(define (ast->node-alist ast)
  `((key . ,(.name ast))
    (name . ,(.name ast)) ;; duh!
    (state . "") ;; duh!
    ))

(define (json-init model)
  (alist->hash-table
   `((type . init)
     (nodes . ,(map alist->hash-table
                    (map ast->node-alist (if (is-a? model <component>)
                                             (cons model (.elements (.ports model)))
                                             (list model))))))))

(define (json-state model state)
  (alist->hash-table
   (append
    `((type . update)
      (comp . ,(.name model)))
    (map (lambda (variable) (cons (car variable) (->symbol (cdr variable))))
         state))))

(define (from model event statement)
  (if (is-a? statement <on>)
      (if (.port (event->ast event))
          (.port (event->ast event))
          'in)
      (.name model)))

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

(define (state->hash state)
   (alist->hash-table
    (map
     (lambda (s)
       (cons ((@@(gaiag simulate) ->string) (car s))
             ((@@(gaiag simulate) ->string) (cdr s))))
     state)))

(define ((json-trace model) tracepoint)
  (let* ((event (car tracepoint))
         (state (cadr tracepoint))
         (steps (cddr tracepoint))
         (name (.name model)))
    (let loop ((statements steps))
      (if (null? statements)
          (list (alist->hash-table '()))
      (let* ((statement (car statements))
             (class (and=> statement ast-name))
             (type (if (eq? class 'assign) 'update 'transition))
             (location (alist->hash-table
                        `((begin . ,(json-location statement))
                          (end . ,(json-location (or (and (pair? statements) (last statements)) statement))))))
             (message
              (alist->hash-table
               (if (eq? type 'update)
                   (let ((variable (.identifier statement)))
                     `((type . update)
                       (comp . ,name)
                       (,variable . ,(->symbol (var state variable)))
                       (location . ,location)))
                   (let ((kind
                          (match statement
                            (($ <compound>) 'step)
                            (_ class)))
                         (json-event
                          (match statement
                            (($ <on>) (->symbol event))
                            (($ <action>) (->symbol (.trigger statement)))
                            (_ #f))))
                     `((type . transition)
                       (kind . ,kind)
                       (from . ,(from model event statement))
                       (to  . ,(to model statement))
                       (event . ,json-event)
                       (state . ,(state->hash state))
                       (location . ,location)))))))
        (cons message (loop (cdr statements))))))))
