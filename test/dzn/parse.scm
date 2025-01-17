;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
;;; Tests for the makreel module.
;;;
;;; Code:

(define-module (test dzn parse)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)

  #:use-module (test dzn automake)

  #:use-module (dzn misc)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse)
  #:use-module (dzn parse lookup)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse tree))

(test-begin "parse")

(test-assert "dummy"
  #t)

(parameterize ((%peg:locations? 'none))
  (let* ((marker "//*cached*\n")
         (ihello "test/all/hello_import/ihello.dzn")
         (hello-import "test/all/hello_import/hello_import.dzn")
         (ihello-alist (parse:file->content-alist ihello))
         (tainted-ihello-alist
          (match ihello-alist
            (((file-name . content))
             `((,file-name . ,(string-append marker content)))))))

    (test-assert "cache content-alist"
      (let* ((hello-content (parse:file->content-alist
                             hello-import
                             #:content-alist tainted-ihello-alist))
             (ihello-content (find (compose (cute equal? <> ihello) car)
                                   hello-content))
             (hello-tree (parse:file->tree-alist hello-import
                                                 #:content-alist tainted-ihello-alist)))
        (match ihello-content
          ((`,ihello . content)
           (string-prefix? marker content)))))

    (test-assert "cache tree-alist"
      (let* ((hello-content (parse:file->content-alist
                             hello-import
                             #:content-alist tainted-ihello-alist))
             (hello-tree (parse:file->tree-alist hello-import
                                                 #:content-alist tainted-ihello-alist))
             (ihello-tree (find (compose (cute equal? <> ihello) car)
                                hello-tree)))
        (match ihello-tree
          ((`,ihello . tree)
           (let ((comment (find (conjoin pair?
                                         (compose (cute eq?  <> 'comment) car))
                                tree)))
             (match comment
               (('comment comment)
                (string-prefix? marker comment))))))))

    (test-equal "string->tree"
      "ihello"
      (let* ((text (with-input-from-file hello-import read-string))
             (tree (parse:string->tree text))
             (port (and=> (context:collect tree (is? 'port)) car))
             (type-name (.type-name (.tree port)))
             (interface-name (and=> type-name tree:dotted-name)))
        interface-name))))

(test-end)
