;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2017, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; This code was initially taken from an early version of Gash.
;;;
;;; Code:

(define-module (dzn pipe)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (dzn misc)

  #:export (pipeline pipeline* pipeline->port pipeline->string pipeline*->string))

(define piped-process (@@ (ice-9 popen) piped-process))

(define (pipe->fdes)
  (let ((p (pipe)))
    (cons (port->fdes (car p))
          (port->fdes (cdr p)))))

(define* (pipeline commands #:key output-port)
  "Execute a pipeline of COMMANDS, feeding INPUT to the first command.
If the first command is a procedure, run that and take its output as
input for the pipeline, instead of INPUT.  Each command is a list of a
program and its arguments as strings.  Return three values: the input
port to write to the pipeline, the output port to read from the
pipeline, and the pids from all COMMANDS.  When OUTPUT-PORT, write to
that port; return output-port, #f and pids."
  (define (command pipe proc previous)
    (match previous
      ((pfrom . pids)
       (let* ((to pfrom)
	      (from pipe))
         (cond ((procedure? proc)
                (throw 'error "procedure inside pipeline" commands))
               (else
                (let ((pid (piped-process (car proc) (cdr proc) from to)))
	          (cons from (cons pid pids)))))))))
  (let* ((to (pipe->fdes))
         (pipes (map (lambda _ (pipe->fdes)) commands))
         (pipes (if (not output-port) pipes
                    (match pipes
                      (((x . y) pipes ...)
                       (append pipes
                               `((,x . ,(port->fdes output-port))))))))
	 (pipeline (fold command `(,to) pipes commands)))
    (match pipeline
      ((from . pids)
       (values (fdes->outport (cdr to))
               (and (not output-port) (fdes->inport (car from)))
               pids)))))

(define (pipeline* commands)
  "Execute a pipeline of COMMANDS, feeding INPUT to the first command.
If the first command is a procedure, run that and take its output as
input for the pipeline, instead of INPUT.  Each command is a list of a
program and its arguments as strings.  Return four values: the input
port to write to the pipeline, the output port to read from the
pipeline, the error port to read from the pipeline, and the pids from
all COMMANDS."
  (match (pipe)
    ((error-input-port . error-output-port)
     (move->fdes error-output-port 2)
     (let ((output-port input-port pids
                        (with-error-to-port error-output-port
                          (cute pipeline commands))))
       (close error-output-port)
       (let ((error (read-string error-input-port)))
         (values output-port input-port error-input-port pids))))))

(define* (pipeline->string commands #:key (input ""))
  "Execute a pipeline of COMMANDS, feeding INPUT to the first command.
If the first command is a procedure, run that and take its output as
input for the pipeline, instead of INPUT.  Each command is a list of a
program and its arguments as strings.  Return two values: the output
that the pipeline produced as a string, and a sum of the output stati of
the pipeline COMMANDS."
  (define (pipeline-with-input commands input)
    (let ((output-port input-port pids (pipeline commands)))
      (display input output-port)
      (close output-port)
      (let ((stdout (read-string input-port)))
        (false-if-exception (close input-port))
        (values stdout (apply + (map (compose (disjoin status:exit-val
                                                       status:term-sig)
                                              cdr waitpid)
                                     pids))))))
  (match commands
    (((? procedure? procedure) commands ...)
     (unless (string-null? input)
       (format (current-error-port) "pipeline*->string: warning: ignoring input: ~a\n" input))
     (let ((input (with-output-to-string procedure)))
       (pipeline-with-input commands input)))
    (_
     (pipeline-with-input commands input))))

(define* (pipeline->port commands #:key (input "") (output-port (current-output-port)))
  "Execute a pipeline of COMMANDS, feeding INPUT to the first command.
If the first command is a procedure, run that and take its output as
input for the pipeline, instead of INPUT.  Each command is a list of a
program and its arguments as strings.  Return two values: #f, and a sum
of the output stati of the pipeline COMMANDS."
  (define (pipeline-with-input commands input)
    (let ((output-port input-port pids
                       (pipeline commands #:output-port (current-output-port))))
      (display input output-port)
      (close output-port)
      (false-if-exception (close input-port))
      (values #f (apply + (map (compose (disjoin status:exit-val
                                                 status:term-sig)
                                        cdr waitpid) pids)))))
  (match commands
    (((? procedure? procedure))
     (parameterize ((current-output-port output-port))
       (procedure)
       (close output-port)
       (values #f 0)))
    (((? procedure? procedure) commands ...)
     (unless (string-null? input)
       (format (current-error-port) "pipeline*->string: warning: ignoring input: ~a\n" input))
     (let ((input (with-output-to-string procedure)))
       (pipeline-with-input commands input)))
    (_
     (pipeline-with-input commands input))))

(define* (pipeline*->string commands #:key (input ""))
  "Execute a pipeline of COMMANDS, feeding INPUT to the first command.
If the first command is a procedure, run that and take its output as
input for the pipeline, instead of INPUT.  Each command is a list of a
program and its arguments as strings.  Return two values: the output
that the pipeline produced as a string, a sum of the output stati of the
pipeline COMMANDS, and the error output that the pipeline procuded as a
string."
  (match (pipe)
    ((error-input-port . error-output-port)
     (move->fdes error-output-port 2)
     (let ((output status
                   (with-error-to-port error-output-port
                     (cut pipeline->string commands #:input input))))
       (close error-output-port)
       (let ((error (read-string error-input-port)))
         (values output status error))))))
