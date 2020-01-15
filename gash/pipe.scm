;;; Gash --- Guile As SHell
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@gmail.com>
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 popen)
  :use-module (ice-9 rdelim)
  :use-module (ice-9 regex)

  :use-module (srfi srfi-1)
  :use-module (srfi srfi-8)
  :use-module (srfi srfi-9)
  :use-module (srfi srfi-26)

  :use-module (gash job)
  :use-module (gaiag command-line)

  :export (handle-error pipeline pipeline+ pipeline->string pipeline->error-string substitute))

(define (handle-error job error)
  (let ((status (wait job)))
    (when (not (zero? status))
      (let* ((msg (if (or (string-contains error "std::bad_alloc")
                          (string-contains error "out-of-memory"))
                      "ERROR: Out of Memory.\nProbably your model has too many states."
                      "ERROR: Internal error."))
             (error (regexp-substitute/global #f "[ ]+" error 'pre " " 'post))
             (error (regexp-substitute/global #f "Generated .* linearisation method.\n" error 'pre "" 'post))
             (details (format #f "exit: ~a: ~a" status error)))
        (format (current-error-port) "~a\nPlease contact Verum support.\n\nInternal details: ~s\n" msg details)
        (exit status)))
    status))

(define (pipe*)
  (let ((p (pipe)))
    (values (car p) (cdr p))))

;;              lhs        rhs
;; [source] w[1] -> r[0] [filter] w[1] -> r[0] [sink]
;;          w[2]            ->            r[3] [sink]

(define (exec* command) ;; list of strings
  (catch #t (lambda () (apply execlp (cons (car command) command)))
    (lambda (key . args)
      (format (current-error-port) "exec* failed: ~s ~s\n" key args)
      (exit #f))))

(define* (spawn fg? job command #:optional (input '()))
  ;;(format #t "spawn: ~a\n" (length input))
  (let* ((ofd '(1)) ;; output file descriptors 1, ...
	 (ifd (cond
	       ((= (length input) 0) '())
	       ((= (length input) 1) '(0))))
	 (pipes (map (lambda (. _) (pipe)) ofd))
	 (r (map car pipes))
	 (w (map cdr pipes))
	 (pid (primitive-fork)))
    ;;(format (current-error-port) "INPUT: ~a\n" (length input))
    ;;(format (current-error-port) "OUTPUT: ~a\n" (length w))
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
                 ;;(format (current-error-port) "INPUT: ~a\n" (length input))
                 ;;(format (current-error-port) "OUTPUT: ~a\n" (length w))
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

(define ((tee-n file-names) inputs outputs)
  (let* ((files  (map open-output-file file-names))
         (tees (zip files inputs outputs)))
    (let loop ((tees tees))
      (loop (filter-map (lambda (tee)
                     (let ((file (first tee))
                           (input (second tee))
                           (output (third tee)))
                       (when (char-ready? input)
                         (let ((char (read-char input)))
                           (if (not (eof-object? char))
                               (begin (display char file)
                                      (display char output)
                                      (list file input output))
                               #f)))))
                        tees)))
    (map close outputs)))

(define (pipeline+ fg? . commands)
  ;; (format (current-error-port) "FOOBAR pipeline+: COMMANDS: ~s\n" commands)
  (let* (;;(error-port (set-current-error-port w))
         (debug? (> (gdzn:debugity) 0)) ;; REMOVE gdzn dependency
         (job (new-job))
         (debug-id (job-debug-id job))
         (commands
          (if (not debug?) commands
              (fold-right (lambda (command id lst)
                            (let ((file (string-append debug-id "." id)))
                              (cons* command `("tee" ,file) lst))) ;;(tee-n (map (cut string-append  file <>) '("-o" "-e"))) ;; `("tee" ,file)
                          '() commands (map number->string (iota (length commands))))))
         (foo (when debug? (with-output-to-file debug-id (cut format #t "COMMANDS: ~s\n" commands))))
         (ports (if (> (length commands) 1)
                    (let loop ((input (spawn fg? job (car commands) '())) ;; spawn-source
                               (commands (cdr commands)))
                      (if (null? (cdr commands))
                          (spawn fg? job (car commands) input) ;; spawn-sink
                          (loop (spawn fg? job (car commands) input) ;; spawn-filter
                                (cdr commands))))
                    (spawn fg? job (car commands) '())))) ;; spawn-sink
    (when fg? (wait job))
    (values job ports)))

(define (forked:pipeline commands)
  (apply pipeline+ (cons* #f commands)))

(define (forked:pipeline->string . commands)
  (receive (job ports)
      (forked:pipeline commands)
    (let ((output (read-string (car ports))))
      (wait job)
      output)))

;;(pipeline #f '("head" "-c128" "/dev/urandom") '("tr" "-dc" "A-Z0-9") (lambda () (display (read-string))))
;;(pipeline #f '("head" "-c128" "/dev/urandom") '("tr" "-dc" "A-Z0-9") '("cat"))
;;(pipeline #f (lambda () (display 'foo)) '("grep" "o") '("tr" "o" "e"))

;; (pipeline #f
;; 	  (lambda () (display "\nbin\nboot\nroot\nusr\nvar"))
;; 	  '("tr" "u" "a")
;; 	  (lambda () (display (string-map (lambda (c) (if (eq? c #\o) #\e c)) (read-string))))
;; 	  '("cat")
;; 	  (lambda () (display (read-string))))

;; (receive (job ports)
;;     (pipeline+ #f
;;                (lambda ()
;;                  (display "foo")
;;                  (display "bar" (current-error-port)))
;;                '("tr" "o" "e"))
;;   (map (compose display read-string) ports))

;; _
;;  \
;;   -
;; _/

;; (display (pipeline->string
;;   (lambda () (display "\nbin\nboot\nroot\nusr\nvar"))
;;   '("tr" "u" "a")
;;   (lambda () (display (string-map (lambda (c) (if (eq? c #\o) #\e c)) (read-string))))
;;   '("cat")
;;   (lambda () (display (read-string)) (newline))))

(define (substitute . commands)
  (string-trim-right
   (string-map (lambda (c)
                 (if (eq? #\newline c) #\space c))
               (apply pipeline->string commands))
   #\space))

;; (display (pipeline->string '("ls") '("cat"))) (newline)
;; (display (substitute '("ls") '("cat"))) (newline)


(define (pipe->fdes)
  (let ((p (pipe)))
    (cons (port->fdes (car p))
	  (port->fdes (cdr p)))))

(define (piped-process:pipeline procs) ;;-> (to from . pids)
  (let* ((to (pipe->fdes))
         (pipes (map (lambda _ (pipe->fdes)) procs))
	 (pipeline (fold (lambda (pipe proc previous)
			   (let* ((pfrom (car previous))
				  (pids (cdr previous))
				  (to pfrom)
				  (from pipe))
			     (cons from (cons ((@@ (ice-9 popen) piped-process) (car proc) (cdr proc) to from) pids))))
			 `(,to)
                         pipes
			 procs))
	 (from (car pipeline))
	 (pids (cdr pipeline)))
    (cons* (fdes->outport (cdr to)) (fdes->inport (car from)) pids)))

(define (piped-process:pipeline->string . procs)
  (let* ((proc? (procedure? (first procs)))
	 (input (if proc? (with-output-to-string (first procs)) ""))
	 (procs (if proc? (cdr procs) procs))
	 (pipeline (pipeline procs))
	 (pids (cddr pipeline))
	 (to (car pipeline))
	 (from (cadr pipeline)))
    (display input to)
    (catch #t (lambda _ (close to)) (const #f))
    (let ((output (read-string from)))
      (catch #t (lambda _ (close from)) (const #f))
      (values output (apply + (map (compose status:exit-val cdr waitpid) pids))))))

(define pipeline
  (if (module-defined? (resolve-module '(ice-9 popen)) 'piped-process) piped-process:pipeline
      forked:pipeline))

(define pipeline->string
  (if (module-defined? (resolve-module '(ice-9 popen)) 'piped-process) piped-process:pipeline->string
      forked:pipeline->string))
