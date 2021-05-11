;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019, 2020, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn ast equal)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (dzn ast accessor)
  #:use-module (dzn ast goops)
  #:use-module (dzn misc)

  #:export (ast:eq?
            ast:equal?
            ast:empty-namespace?
            ast:name-equal?))

;;;
;;; ast:eq?
;;;
(define-method (ast:eq? (a <ast>) (b <ast>))
  (or (eq? a b)
      (and (eq? (.node a) (.node b))
           (ast:eq? (.parent a) (.parent b)))))

(define-method (ast:eq? (a <ast>) b)
  #f)

(define-method (ast:eq? a (b <ast>))
  #f)

(define-method (ast:eq? a b)
  (eq? a b))


;;;
;;; ast:empty-namespace?
;;;
(define-method (ast:empty-namespace? (o <string>))
  (equal? o "/"))


;;;
;;; ast:name-equal?
;;;
(define-method (ast:name-equal? (a <string>) (b <string>))
  (equal? a b))

(define-method (ast:name-equal? (a <scope.name>) (b <string>))
  (and=> (ast:name a) (cut ast:name-equal? <> b)))

(define-method (ast:name-equal? (b <string>) (a <scope.name>))
  (ast:name-equal? a b))

(define-method (ast:name-equal? (a <scope.name>) (b <scope.name>))
  (and (pair? (.ids a)) (pair? (.ids b)) (ast:name-equal? (ast:name a) (ast:name b))))

(define-method (ast:name-equal? (a <named>) (b <string>))
    (ast:name-equal? (.name a) b))

(define-method (ast:name-equal? (b <string>) (a <named>))
    (ast:name-equal? a b))

(define-method (ast:name-equal? a b)
  #f)


;;;
;;; ast:equal?
;;;
(define-method (ast:equal? a b)
  (equal? a b))

(define-method (ast:equal? (a <pair>) (b <pair>))
  (and (ast:equal? (car a) (car b))
       (ast:equal? (cdr a) (cdr b))))

(define-method (ast:equal? (a <ast>) (b <ast>))
  (eq? (.node a) (.node b)))

(define-method (ast:equal? (a <declaration>) (b <declaration>))
  (and (eq? (class-of a) (class-of b))
   (equal? (ast:full-name a) (ast:full-name b))))

(define-method (ast:equal? (a <named>) (b <named>))
  (ast:equal? (.name a) (.name b)))

(define-method (ast:equal? (a <scope.name>) (b <scope.name>))
  (equal? (.ids a) (.ids b)))

(define-method (ast:equal? (a <enum-literal>) (b <enum-literal>))
  (and (ast:equal? (.type.name a) (.type.name b))
       (equal? (.field a) (.field b))))

(define-method (ast:equal? (a <end-point>) (b <end-point>))
  (and (equal? (.instance.name a) (.instance.name b))
       (equal? (.port.name a) (.port.name b))))

(define-method (ast:equal? (a <field-test>) (b <field-test>))
  (and (ast:equal? (.variable.name a) (.variable.name b))
       (equal? (.field a) (.field b))))

(define-method (ast:equal? (a <literal>) (b <literal>))
  (equal? (.value a) (.value b)))

(define-method (ast:equal? (a <not>) (b <not>))
  (ast:equal? (.expression a) (.expression b)))

(define-method (ast:equal? (a <binary>) (b <binary>))
  (and
   (eq? (class-of a) (class-of b))
   (ast:equal? (.left a) (.left b))
   (ast:equal? (.right a) (.right b))))

(define-method (ast:equal? (a <unary>) (b <unary>))
  (and
   (eq? (class-of a) (class-of b))
   (ast:equal? (.expression a) (.expression b))))

(define-method (ast:equal? (a <expression>) (b <expression>))
  (if (eq? (class-of a) (class-of b))
      (throw 'add-ast:equal?-overload-for-type (class-of a))
      #f))

(define-method (ast:equal? (a <reply>) (b <reply>))
  (ast:equal? (.expression a) (.expression b)))

(define-method (ast:equal? (a <signature>) (b <signature>))
  (and
   (ast:equal? (.type.name a) (.type.name b))
   (= (length (ast:formal* a)) (length (ast:formal* b)))
   (every ast:equal? (map .type.name (ast:formal* a))
          (map .type.name (ast:formal* b)))))

(define-method (ast:equal? (a <action>) (b <action>))
  (and (equal? (.port.name a) (.port.name b))
       (equal? (.event.name a) (.event.name b))))

(define-method (ast:equal? (a <trigger>) (b <trigger>))
  (and (equal? (.port.name a) (.port.name b))
       (equal? (.event.name a) (.event.name b))))

(define-method (ast:equal? (a <shared-var>) (b <shared-var>))
  (and (ast:equal? (.port.name a) (.port.name b))
       (ast:equal? (.name a) (.name b))))

(define-method (ast:equal? (a <the-end>) (b <the-end>))
  #t)
