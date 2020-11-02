;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <johri.van.eerd@verum.com>
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
;;; Tests for the language module.
;;;
;;; Code:

;;USAGE: in dzn.git root: make check TESTS=test/dzn/language

(define-module (test dzn language)
  #:use-module (dzn commands language)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (test dzn automake))

(define (assert-completion-options options dzn-file)
  (let* ((output (with-output-to-string (cut main (append (list "dzn/commands/language.scm") options (list dzn-file)))))
         (baseline (call-with-input-file (string-append dzn-file ".baseline") read-string)))
    (unless (equal? output baseline)
      (begin (format #t "\t\t**ERROR**\t\t\n\tExpected: ~s\n\tGot: ~s\n" baseline output) #f))))

(define (assert-completion dzn-file)
  (let ((output (with-output-to-string (cut main (list "dzn/commands/language.scm" dzn-file))))
        (baseline (call-with-input-file (string-append dzn-file ".baseline") read-string)))
    (equal? output baseline)))

(define (assert-completion-offset offset dzn-file)
  (assert-completion-options (list (string-append "--offset=" (number->string offset))) dzn-file))

(test-begin "language")

(test-assert "language interface0"
  (assert-completion "test/language/interface0.dzn"))

(test-assert "language interface1"
  (assert-completion "test/language/interface1.dzn"))

(test-assert "language interface1b"
  (assert-completion "test/language/interface1b.dzn"))

(test-assert "language interface2"
  (assert-completion "test/language/interface2.dzn"))

(test-assert "language interface3"
  (assert-completion "test/language/interface3.dzn"))

(test-assert "language interface4"
  (assert-completion "test/language/interface4.dzn"))

(test-assert "language interface5"
  (assert-completion "test/language/interface5.dzn"))

(test-assert "language interface5b"
  (assert-completion "test/language/interface5b.dzn"))

(test-assert "language interface6"
  (assert-completion "test/language/interface6.dzn"))

(test-assert "language interface7"
  (assert-completion "test/language/interface7.dzn"))

(test-assert "language interface8"
  (assert-completion "test/language/interface8.dzn"))

(test-assert "language interface9"
  (assert-completion "test/language/interface9.dzn"))

(test-assert "language interface9b"
  (assert-completion "test/language/interface9b.dzn"))

(test-assert "language component0"
  (assert-completion "test/language/component0.dzn"))

(test-assert "language component1"
  (assert-completion "test/language/component1.dzn"))

(test-assert "language component2"
  (assert-completion "test/language/component2.dzn"))

(test-assert "language component3"
  (assert-completion "test/language/component3.dzn"))

(test-assert "language component4"
  (assert-completion "test/language/component4.dzn"))

(test-assert "language component5"
  (assert-completion "test/language/component5.dzn"))

(test-assert "language component6"
  (assert-completion "test/language/component6.dzn"))

(test-assert "language component7"
  (assert-completion "test/language/component7.dzn"))

(test-assert "language component8"
  (assert-completion-offset 170 "test/language/component8.dzn"))

(test-assert "language typo"
  (assert-completion-offset 219 "test/language/typo.dzn"))

(test-end)
