;;; Gash --- Guile As SHell
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@gmail.com>
;;; Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gash.
;;;
;;; Gash is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Gash is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Gash.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gash pipe)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-8)

  #:use-module (gash job)

  #:export (pipeline pipeline->string))

;;              lhs        rhs
;; [source] w[1] -> r[0] [filter] w[1] -> r[0] [sink]
;;          w[2]            ->            r[3] [sink]

(define (exec* command)                 ; list of strings
  (catch #t (lambda () (apply execlp (cons (car command) command)))
    (lambda (key . args)
      (format (current-error-port) "exec* failed: ~s ~s\n" key args)
      (exit #f))))

(define* (spawn fg? job command #:optional (input '()))
  (let* ((ofd '(1))                     ; output file descriptors 1, ...
	 (ifd (cond
	       ((= (length input) 0) '())
	       ((= (length input) 1) '(0))))
	 (pipes (map (lambda (. _) (pipe)) ofd))
	 (r (map car pipes))
	 (w (map cdr pipes))
	 (pid (primitive-fork)))
    (cond ((= 0 pid)
           (job-setup-process fg? job)
           (map close r)
           (if (procedure? command)
               (begin
                 (when (pair? input)
                   (close-port (current-input-port))
                   (set-current-input-port (car input)))
                 (when (pair? w)
                   (close-port (current-output-port))
                   (set-current-output-port (car w)))
                 (if (thunk? command) (command)
                     (command input w))
                 (exit 0))
               (begin
                 (map dup->fdes w ofd)
                 (map dup->fdes input ifd)
                 (exec* command))))
          (#t
           (job-add-process fg? job pid command)
           (map close w)
           r))))

(define (pipeline commands)
  (let* ((job (new-job))
         (ports (if (> (length commands) 1)
                    (let loop ((input (spawn #f job (car commands) '())) ; spawn-source
                               (commands (cdr commands)))
                      (if (null? (cdr commands))
                          (spawn #f job (car commands) input) ; spawn-sink
                          (loop (spawn #f job (car commands) input) ; spawn-filter
                                (cdr commands))))
                    (spawn #f job (car commands) '())))) ; spawn-sink
    (values job ports)))

(define (pipeline->string commands)
  (receive (job ports)
      (pipeline commands)
    (let ((output (read-string (car ports))))
      (wait job)
      output)))
