;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag coverage)
  :use-module (ice-9 getopt-long)

  :use-module (system vm coverage)
  :use-module (system vm vm)

  :use-module (gaiag misc)
  :export (cover main))

(define (parse-opts args)
  (let* ((option-spec
	  '((help (single-char #\h))
	    (version (single-char #\v))))
	 (options (getopt-long args option-spec
		   :stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))
    (or
     (and version?
	  (stdout "0.1\n")
	  (exit 0))
      (and (or help? usage?)
	   ((or (and usage? stderr) stdout) "\
Usage: coverage [OPTION]... COMMAND
  -h, --help           display this help
  -v, --version        display version

Examples:
  ./coverage gaiag examples/Alarm.dzn
  ./coverage gaiag -l c++ examples/Alarm.dzn
  ./coverage gaiag -l csp examples/Alarm.dzn
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (cover thunk file-name)
  (call-with-values (lambda ()
                      (if (defined? 'the-vm (resolve-module '(system vm vm)))
                          (with-code-coverage (the-vm) thunk)
                          (with-code-coverage thunk)))
    (lambda (data result)
      (let ((port (open-output-file (->string file-name))))
        (coverage-data->lcov data port)
        (close port)))))

(define (main args)
  (let* ((options (parse-opts args))
	 (command (option-ref options '() '()))
         (script (string->symbol (car command)))
         (module (resolve-module (list 'gaiag script)))
         (procedure (module-ref module 'main))
         (args command))
    (cover (lambda () (procedure args)) (->string (list script '.info)))))
