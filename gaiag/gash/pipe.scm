;;; Gash --- Guile As SHell
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@gmail.com>
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (ice-9 popen)
  :use-module (ice-9 rdelim)

  :use-module (srfi srfi-1)
  :use-module (srfi srfi-8)
  :use-module (srfi srfi-9)
  :use-module (srfi srfi-26)

  :use-module (gash job)
  :use-module (gash io)

  :export (pipeline pipeline->string))

(define (pipe*)
  (let ((p (pipe)))
    (values (car p) (cdr p))))

;;              lhs        rhs
;; [source] w -> r [filter] w -> r [sink]

(define (exec* command) ;; list of strings
  (catch #t (lambda () (apply execlp (cons (car command) command)))
    (lambda (key . args) (display (string-append (caaddr args) "\n"))
            (exit #f))))

(define (setup-process fg? job)
  (when (isatty? (current-error-port))
    (add-to-process-group job (getpid))
    ;(when fg? (tcsetpgrp (current-error-port) (add-to-process-group job (getpid))))
    (map (cut sigaction <> SIG_DFL)
         (list SIGINT SIGQUIT SIGTSTP SIGTTIN SIGTTOU SIGCHLD)))
  (fdes->inport 0) (map fdes->outport '(1 2))) ;; reset stdin/stdout/stderr

(define (spawn-source fg? job command)
  (receive (r w) (pipe*)
    (let ((pid (primitive-fork)))
      (cond ((= 0 pid) (close r)
             (setup-process fg? job)
             (move->fdes w 1)
             (exec* command))
            (#t
             (job-add-process fg? job pid command)
             (close w)
             r)))))

(define (spawn-filter fg? job src command)
  (receive (r w) (pipe*)
    (let ((pid (primitive-fork)))
      (cond ((= 0 pid)
             (setup-process fg? job)
             (if src (move->fdes src 0))
             (close r)
             (move->fdes w 1)
             (exec* command))
            (#t
             (job-add-process fg? job pid command)
             (close w)
             r)))))

(define (spawn-sink fg? job src command)
  (let ((pid (primitive-fork)))
    (cond ((= 0 pid)
           (setup-process fg? job)
           (if src (move->fdes src 0))
           (exec* command))
          (#t
           (job-add-process fg? job pid command)
           (and src (close src))))))


(define (pipeline fg? . commands)
  (let ((job (new-job)))
    (if (> (length commands) 1)
        (let loop ((src (spawn-source fg? job (car commands)))
                   (commands (cdr commands)))
          (if (null? (cdr commands))
              (spawn-sink fg? job src (car commands))
              (loop (spawn-filter fg? job src (car commands))
                    (cdr commands))))
        (spawn-sink fg? job #f (car commands)))
    (if fg? (wait job))))

;;(pipeline #f (list "ls" "/"))
;;(pipeline #f (list "ls" "/") (list "grep" "o") (list "tr" "o" "e"))


(define (pipeline->string . commands)

  (let* ((gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (foo (if gdzn-debug? (stderr "pipeline->string: " commands)))
         (fg? #f)
         (job (new-job))
         (output (read-string
                  (if (> (length commands) 1)
                      (let loop ((src (spawn-source fg? job (car commands)))
                                 (commands (cdr commands)))
                        (if (null? (cdr commands))
                            (spawn-filter fg? job src (car commands))
                            (loop (spawn-filter fg? job src (car commands))
                                  (cdr commands))))
                      (spawn-filter fg? job #f (car commands))))))
    (let* ((status (wait job))
           (status (or (status:term-sig status) (status:exit-val status))))
      (if (zero? status) output status))))

;;(display (pipeline->string '("ls") '("cat")))
