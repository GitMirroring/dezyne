;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag step normalize)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (gaiag misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag normalize)
  #:use-module (gaiag ast)
  #:export (
            step:normalize
            ))

(define (step:normalize root)
  ((compose
    set-blocking-reply-port
    transform-return
    (transform-action)
    (annotate-otherwise)
    purge-data
    ) root))

(define* (set-blocking-reply-port o #:optional (port #f) (block? #f))
  (match o
    (($ <reply>) (if (not block?) o
                     (let ((port? (.port o))) (if (and port? (not (symbol? port?))) o (clone o #:port.name (.name port))))))
    (($ <blocking>) (set-blocking-reply-port (.statement o) port #t))
    (($ <on>)
     (let* ((requires? (ast:requires? ((compose .port car ast:trigger*) o)))
            (block? (or block? requires?))
            (port (if port port
                      (if requires? (ast:provides-port (parent o <model>))
                          ((compose .port car ast:trigger*) o)))))
       (clone o #:statement (set-blocking-reply-port (.statement o) port block?))))
    (($ <guard>) (clone o #:statement (set-blocking-reply-port (.statement o) port block?)))
    (($ <compound>) (clone o #:elements (map (cut set-blocking-reply-port <> port block?) (ast:statement* o))))
    (($ <behaviour>) (clone o #:statement (set-blocking-reply-port (.statement o) port block?)))
    (($ <component>) (clone o #:behaviour (set-blocking-reply-port (.behaviour o) (if (= 1 (length (ast:provides-port* o))) (car (ast:provides-port* o)) #f) block?)))
    (($ <system>) o)
    (($ <foreign>) o)
    (($ <interface>) o)
    ((? (is? <ast>)) (tree-map (cut set-blocking-reply-port <> port block?) o))
    (_ o)))

(define* ((annotate-otherwise #:optional (statements '())) o) ;; FIXME *unspecified*
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*)))
  (match o
    ((and ($ <guard>) (= .expression (and ($ <otherwise>) (= .value value)))) (=> failure)
     (if (or (not (virgin-otherwise? value)) (null? statements)) (failure)
         (clone o #:expression ((annotate-otherwise statements) (.expression o)))))
    (($ <otherwise>)
     (or (let* ((guards (filter (is? <guard>) statements))
                (value (guards-not-or guards)))
           (and value (clone o #:value value)))
         o))
    ((and ($ <compound>) (= .elements (statements ...)))
     (clone o #:elements (map (annotate-otherwise statements) statements)))
    (($ <skip>) o)
    ((? (is? <ast>)) (tree-map (annotate-otherwise statements) o))
    (_ o)))

(define (guards-not-or o)
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (expression (reduce (lambda (g0 g1)
                               (if (ast:equal? g0 g1) g0 (make <or> #:left g0 #:right g1)))
                             '() others)))
    (match expression
      ((and ($ <not>) (= .expression expression)) expression)
      (_ (make <not> #:expression expression)))))

(define* ((transform-action #:optional model) o)
  (define (component? x) (is-a? model <component>))

  (define (system-port-event? trigger)
    ;; instance-path
    ;; port-name

    (and (ast:provides? (.port trigger))
         (ast:out? (.event trigger))))

  (define (add-flush o f)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) f)))
      ((? ast:imperative?)
       (make <compound> #:elements (cons o f) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-flush <> f) (ast:statement* o))))
      (($ <guard>) (clone o #:statement (add-flush (.statement o) f)))
      (($ <blocking>) (clone o #:statement (add-flush (.statement o) f)))
      ;;(($ <blocking>) (clone o #:statement (add-flush (.statement o) (append f (list (clone (make <block> #:location (.location (car f))) #:parent (.parent (car f))))))))
      ))

  (match o
    ((and ($ <on>) (= ast:trigger* triggers) (= .statement statement))
     (let* ((statement ((transform-action model) statement))
            (actions (tree-collect (is? <action>) statement))
            (blocking? (or (parent o <blocking>)
                           (pair? (tree-collect (is? <blocking>) o))))
            (statement (if (and (null? actions) (not blocking?)) statement
                           (add-flush statement (list (clone (make <flush> #:location (.location o)) #:parent statement))))))
       (clone o #:statement statement)))

    ((and ($ <action>) (? component?) (? system-port-event?))
     (clone (make <action-out> #:port.name (.port.name o) #:event.name (.event.name o) #:arguments (.arguments o) #:location (.location o)) #:parent o))

    ((and ($ <action>) (? (negate component?)))
     (clone (make <action-out> #:event.name (.event.name o) #:arguments (.arguments o) #:location (.location o)) #:parent o))

    (($ <interface>)
     (clone o #:behaviour ((transform-action o) (.behaviour o))))

    (($ <component>)
     (clone o #:behaviour ((transform-action o) (.behaviour o))))

    ((? (is? <ast>)) (tree-map (transform-action model) o))
    (_ o)))

(define (transform-return o)
  (define (add-return o r)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) r)))
      ((? ast:imperative?)
       (make <compound> #:elements (cons o r) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-return <> r) (ast:statement* o))))
      (($ <guard>) (clone o #:statement (add-return (.statement o) r)))
      ;; (($ <blocking>) (clone o #:statement (add-return (.statement o) r)))
      ;; @ flush/action
      (($ <blocking>) (clone o #:statement (add-return (.statement o) (cons (clone (make <block> #:location (.location (car r))) #:parent (.parent (car r))) r))))))

  (match o
    (($ <on>)
     (let* ((trigger ((compose car ast:trigger*) o))
            (return (list (clone (make (if (or (ast:out? (.event trigger))
                                               (is-a? (.event trigger) <modeling-event>)) <trigger-out-return> <trigger-return>) #:port.name (.port.name trigger) #:location (.location o)) #:parent (.statement o))))
            (blocking? (parent o <blocking>))
            (return (if blocking? (cons (clone (make <block> #:location (.location o)) #:parent (.statement o))  return) return))
            (statement (add-return (.statement o) return)))
       (clone o #:statement statement)))

    (($ <behaviour>)
     (clone o #:statement (transform-return (.statement o))))

    (($ <interface>)
     (clone o #:behaviour (transform-return (.behaviour o))))

    (($ <component>)
     (clone o #:behaviour (transform-return (.behaviour o))))

    ((? (is? <ast>)) (tree-map transform-return o))
    (_ o)))
