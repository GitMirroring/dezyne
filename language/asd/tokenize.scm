;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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
  ;;#:export (next-token make-tokenizer make-tokenizer/1 tokenize)
  #:export (make-tokenizer make-tokenizer/1)
  )

(define (string-symbol x) (cons (symbol->string x) x))
(define *keywords*
  (map string-symbol 
       '(
         behaviour
         component
         enum
         in
         int
         interface
         on
         out
         provides
         reply
         requires
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
    ("," . comma)
    (";" . semicolon)
    ("<" . <)
    (">" . >)
    ("<=" . <=)
    (">=" . >=)
    ("==" . ==)
    ("!=" . !=)
    ("+" . +)
    ("-" . -)
    ("*" . *)
    ("!" . !)
    ("&&" . &&)
    ("||" . or)
    (":" . colon)
    ("=" . =)))

(define *future-reserved-words* '())

(define *div-punctuation*
  '(("/" . /)))

(module-define! (resolve-module '(language ecmascript tokenize)) '*keywords* *keywords*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*future-reserved-words* *future-reserved-words*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*div-punctuation* *div-punctuation*)

(define (read-identifier port loc)
  ((@@ (language ecmascript tokenize) read-identifier) port loc))

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

(define (next-token port div?)
  ((@@ (language ecmascript tokenize) next-token) port div?))

(define (make-tokenizer port) (lambda () (next-token port #t)))
;;(define (make-tokenizer/1 port) (lambda () (next-token port #t)))

(define (xmake-tokenizer port)
  ((@@ (language ecmascript tokenize) make-tokenizer) port))

(define (make-tokenizer/1 port)
  ((@@ (language ecmascript tokenize) make-tokenizer/1) port))
