;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2015 David Thompson <davet@gnu.org>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2017 Mathieu Othacehe <m.othacehe@gmail.com>
;;; Copyright © 2019 Guillaume Le Vaillant <glv@posteo.net>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gaiag syscall)
  #:use-module (system foreign)
  #:use-module (srfi srfi-11)
  #:export (
            mkdtemp!
            ))

;;; Commentary:
;;;
;;; This module provides bindings to libc's syscall wrappers.  It uses the
;;; FFI, and thus requires a dynamically-linked Guile.
;;;
;;; Some syscalls are already defined in statically-linked Guile by applying
;;; 'guile-linux-syscalls.patch'.
;;;
;;; Visibility of syscall's symbols shared between this module and static Guile
;;; is a bit delicate. It is handled by 'define-as-needed' macro.
;;;
;;; This macro is used to export symbols in dynamic Guile context, and to
;;; re-export them in static Guile context.
;;;
;;; This way, even if they don't appear in #:export list, it is safe to use
;;; syscalls from this module in static or dynamic Guile context.
;;;
;;; Code:

(define (syscall->procedure return-type name argument-types)
  "Return a procedure that wraps the C function NAME using the dynamic FFI,
and that returns two values: NAME's return value, and errno.

If an error occurs while creating the binding, defer the error report until
the returned procedure is called."
  (catch #t
    (lambda ()
      (let ((ptr (dynamic-func name (dynamic-link))))
        ;; The #:return-errno? facility was introduced in Guile 2.0.12.
        (pointer->procedure return-type ptr argument-types
                            #:return-errno? #t)))
    (lambda args
      (lambda _
        (throw 'system-error name  "~A" (list (strerror ENOSYS))
               (list ENOSYS))))))

(define mkdtemp!
  (let ((proc (syscall->procedure '* "mkdtemp" '(*))))
    (lambda (tmpl)
      "Create a new unique directory in the file system using the template
string TMPL and return its file name.  TMPL must end with 'XXXXXX'."
      (let-values (((result err) (proc (string->pointer tmpl))))
        (when (null-pointer? result)
          (throw 'system-error "mkdtemp!" "~S: ~A"
                 (list tmpl (strerror err))
                 (list err)))
        (pointer->string result)))))
