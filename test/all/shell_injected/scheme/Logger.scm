;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (Logger)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn runtime)
  #:use-module (shell_injected)
  #:export (<Logger>
            .out_log
            .log))

(define-class <Logger> (<dzn:component>)
  (out_log #:accessor .out_log #:init-value #f #:init-keyword #:out_log)
  (log #:accessor .log #:init-form (make <ILogger>) #:init-keyword #:log))

(define-method (initialize (o <Logger>) args)
  (next-method o (cons* #:flushes? #t args))
  (set! (.log o)
    (make <ILogger>
      #:in (make <ILogger.in>
        #:name 'log
        #:self o
        #:log (lambda args (call-in o (lambda _ (apply log-log (cons o args))) `(,(.log o) log))))
      #:out (make <ILogger.out>))))

(define-method (log-log (o <Logger>) m)
  *unspecified*)
