;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

-- both.csp.scm

#(string-if (pair? (om:functions model)) #{
datatype #(.name model)_call_return_alphabet =
  #((->join "  |")
    (apply
     append
     (map
      (lambda (f)
        (let* ((parameters ((compose .elements .parameters .signature) f))
               (p-types (if (pair? parameters)
                            (->string (list "." (csp-comma-list (map (compose .name .type) ((compose .elements .parameters .signature) f)))  "\n"))
                            "")))
     (append
      (list (->string (.name model) "_" (.name f) "_return\n")
            (->string (.name model) "_" (.name f) "_call" p-types)
            (list (if (.recursive f)
                      (->string (list (.name model) "_" (.name f) "_forward" p-types))))))))
     (om:functions model))))
channel #(.name model)_call_return: #(.name model)_call_return_alphabet
#})
#(string-if (pair? (om:member-types model)) #{
datatype #(.name model)_glob_alphabet = #(.name model)_get.#(csp-comma-list (om:member-types model))  | #(.name model)_set.#(csp-comma-list (om:member-types model))
channel #(.name model)_glob: #(.name model)_glob_alphabet
#}
#{
datatype #(.name model)_glob_alphabet = <> -- FIXME no globals
channel #(.name model)_glob: #(.name model)_glob_alphabet
#})
-- end of both.csp.scm
