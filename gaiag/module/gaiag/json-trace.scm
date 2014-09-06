;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (srfi srfi-1)

  :use-module (gaiag ast:)
  :use-module (gaiag misc)
  :use-module (language asd parse)
  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)
  :use-module (gaiag simulate)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (json-init
           json-state
           json-trace))

;; JSON output mangling disaster area

;; FIXME: mangling the trace output into the current json format takes
;; about as much effort as producing it?

(define *model* #f)

(define (ast->node-alist ast)
  `((key . ,(.name ast))
    (name . ,(.name ast)) ;; duh!
    (state . "") ;; duh!
    ))

(define (json-init model)
  (set! *model* model)
  (alist->hash-table
   `((type . init)
     (nodes . ,(map alist->hash-table
                    (map ast->node-alist (if (is-a? *model* <component>)
                                             (cons *model* (.elements (.ports *model*)))
                                             (list *model*))))))))

(define (json-state state)
  (stderr "json-state: ~a\n" state)
  (alist->hash-table
   (append
    `((type . update)
      (comp . ,(.name *model*)))
    (map (lambda (variable) (cons (car variable) (->symbol (cdr variable))))
         state))))

(define (from event statement)
  (if (is-a? statement <on>)
      (if (.port (event->ast event))
          (.port (event->ast event))
          'in)
      (.name *model*)))

(define (to statement)
  (if (is-a? statement <on>)
      (.name *model*)
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

(define (json-location ast)
  (alist->hash-table
   (or (and-let* ((loc (source-location ast))
                  (properties (source-location->source-properties loc)))
                 `((file . ,(assoc-ref properties 'filename))
                   (line . ,(assoc-ref properties 'line))
                   (colum . ,(assoc-ref properties 'column))))
      '())))

(define (json-trace tracepoint)
  (let* ((event (car tracepoint))
         (state (cadr tracepoint))
         (steps (cddr tracepoint))
         (model (.name *model*)))
    (let loop ((statements steps))
      (let* ((statement (if (null? statements) #f (car statements)))
             (class (and=> statement ast-name))
             (type (if (eq? class 'assign) 'update 'transition))
             (message
              (alist->hash-table
               (if (eq? type 'update)
                   (let ((variable (.identifier statement)))
                     `((type . update)
                       (comp . ,model)
                       (,variable . ,(->symbol (var state variable)))))
                   (let ((kind (assoc-ref '((#f . return)
                                            (on . call)
                                            (action . call))
                                          (and=> statement ast-name)))
                         (json-event (cond
                                      ((is-a? statement <on>) (->symbol event))
                                      ((is-a? statement <action>) (->symbol (.trigger statement)))
                                      (else 'return))))
                     `((type . transition)
                       (kind . ,kind)
                       (from . ,(from event statement))
                       (to  . ,(to statement))
                       (event . ,json-event)
                       (location .
                                 ,(alist->hash-table
                                   `((begin . ,(json-location statement))
                                     (end . ,(json-location (or (and (pair? statements) (last statements)) statement))))))))))
              )) ;;TODO
        (if (not statement)
            (list message)
            (cons message (loop (cdr statements))))))))
