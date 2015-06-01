;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
        (let* ((signature (.signature f))
               (parameters (filter (lambda (x) (not (is-a? (om:extern model (.type x)) <extern>))) ((compose .elements .parameters) signature)))
               (p-types (if (pair? parameters)
                            (->string 
                             (list 
                              "."
                              (csp-comma-list
                                (map (lambda (x) (if (is-a? x <enum>) (->string (or (.scope x) (.name model)) '_ (.name x)) (.name x))) 
                                     (map (compose (om:type model) .type) parameters)))
                              "\n"))
                            ""))
               (type (.type signature))
               (r-type (if (and (not (eq? (.name type) 'void))
                                (not (is-a? (om:extern model type) <extern>)))
                            (->string (list "." (if (is-a? (om:type model type) <enum>) (->string (or (.scope type) (.name model)) '_ (.name type)) (.name type))))
                            "")))
     (append
      (list (->string (.name model) "_" (.name f) "_return" r-type "\n")
            (->string (.name model) "_" (.name f) "_call" p-types)
            (list (if (.recursive f)
                      (->string (list (.name model) "_" (.name f) "_forward" p-types))))))))
     (om:functions model))))
channel #(.name model)_call_return: #(.name model)_call_return_alphabet  
#}
#{
datatype #(.name model)_call_return_alphabet = #(.name model)_empty_call_return_alphabet
channel #(.name model)_call_return: #(.name model)_call_return_alphabet
#})
#(string-if (pair? (csp-members-get-set-alphabet model)) #{
datatype #(.name model)_glob_alphabet  = #((->join "|\n  ") (csp-members-get-set-alphabet model))
channel #(.name model)_set: #(.name model)_glob_alphabet
channel #(.name model)_get: #(.name model)_glob_alphabet
#}
#{
channel #(.name model)_set
channel #(.name model)_get
#})
-- end of both.csp.scm
