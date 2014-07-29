;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;;
;;; This file is part of Gaiag.
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(define-module (language asd tokenize)
  #:use-module (language ecmascript tokenize)
  #:use-module (system base lalr)

  #:export (make-tokenizer make-tokenizer/1))

(define (syntax-error what loc form . args)
  (throw 'syntax-error #f what
         (and=> loc source-location->source-properties)
         form #f args))

(module-define! (resolve-module '(language ecmascript tokenize)) 'syntax-error syntax-error)

(define (string-symbol x) (cons (symbol->string x) x))
(define *keywords*
  (map string-symbol 
       '(
         behaviour
         component
         else
         enum
         if
         import
         in
         inevitable
         int
         interface
         on
         optional
         otherwise
         out
         provides
         reply
         requires
         return
         system
         typedef
         void
         )))

(define *punctuation*
  '(
    ("{" . lbrace)
    ("}" . rbrace)
    ("(" . lparen)
    (")" . rparen)
    ("[" . lbracket)
    ("]" . rbracket)
    ("." . dot)
    (".." . ..)
    ("," . comma)
    (";" . semicolon)
    ("<" . <)
    (">" . >)
    ("<=>" . <=>)
    ("<=" . <=)
    (">=" . >=)
    ("==" . ==)
    ("!=" . !=)
    ("+" . +)
    ("-" . -)
    ("*" . *)
    ("!" . !)
    ("&&" . and)
    ("||" . or)
    (":" . colon)
    ("=" . =)))

(define *future-reserved-words* '())

(define *div-punctuation*
  '(("/" . /)))

(module-define! (resolve-module '(language ecmascript tokenize)) '*keywords* *keywords*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*punctuation* *punctuation*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*future-reserved-words* *future-reserved-words*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*div-punctuation* *div-punctuation*)

;; FIXME: unchanged copy from ecmascript
;; find a way to have it use our punctuation
(define read-punctuation
  (let ((punc-tree (let lp ((nodes '()) (puncs *punctuation*))
                     (cond ((null? puncs)
                            nodes)
                           ((assv-ref nodes (string-ref (caar puncs) 0))
                            => (lambda (node-tail)
                                 (if (= (string-length (caar puncs)) 1)
                                     (set-car! node-tail (cdar puncs))
                                     (set-cdr! node-tail
                                               (lp (cdr node-tail)
                                                   `((,(substring (caar puncs) 1)
                                                      . ,(cdar puncs))))))
                                 (lp nodes (cdr puncs))))
                           (else
                            (lp (cons (list (string-ref (caar puncs) 0) #f) nodes)
                                puncs))))))
    (lambda (port loc)
      (let lp ((c (peek-char port)) (tree punc-tree) (candidate #f))
        (cond
         ((assv-ref tree c)
          => (lambda (node-tail)
               (read-char port)
               (lp (peek-char port) (cdr node-tail) (car node-tail))))
         (candidate
          (make-lexical-token candidate loc #f))
         (else
          (syntax-error "bad syntax: character not allowed" loc c)))))))

(module-define! (resolve-module '(language ecmascript tokenize)) 'read-punctuation read-punctuation)

(define (read-identifier port loc)
  (let lp ((c (peek-char port)) (chars '()))
    (if (or (eof-object? c)
            (not (or (char-alphabetic? c)
                     (char-numeric? c)
                     (char=? c #\$)
                     (char=? c #\_))))
        (let ((word (list->string (reverse chars))))
          (cond ((assoc-ref *keywords* word)
                 => (lambda (x) (make-lexical-token x loc (string->symbol word))))
                (else (make-lexical-token 'Identifier loc
                                          (string->symbol word)))))
        (begin (read-char port)
               (lp (peek-char port) (cons c chars))))))

(module-define! (resolve-module '(language ecmascript tokenize)) 'read-identifier read-identifier)

(define (digit->number c)
  (- (char->integer c) (char->integer #\0)))

(define (read-numeric port loc)
  (let loop ((c (peek-char port)) (num 0))
    (if (or (eof-object? c)
            (not (char-numeric? c)))
        num
        (begin
          (read-char port)
          (loop (peek-char port) (+ (* 10 num) (digit->number c)))))))

(module-define! (resolve-module '(language ecmascript tokenize)) 'read-numeric read-numeric)

(define (port-source-location port)
  ((@@ (language ecmascript tokenize) port-source-location) port))

(define (next-token port div?)
  ((@@ (language ecmascript tokenize) next-token) port div?))

(define (make-tokenizer port)
  ((@@ (language ecmascript tokenize) make-tokenizer) port))

(define (make-tokenizer/1 port)
  ((@@ (language ecmascript tokenize) make-tokenizer/1) port))
