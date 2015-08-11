;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

assert COMPLETE'({#
(comma-join (append (map (lambda (event) (list .scope_model "." (.name event))) (filter om:in? (.elements (.events model))))
                    (map (lambda (event) (list .scope_model "_'''." (.event event))) (modeling-events model))))}) [F= IF_#.scope_model _(true,true)[[range_error<-illegal]] \ diff(Events,{#
(comma-join (append (map (lambda (event) (list .scope_model "." (.name event))) (filter om:in? (.elements (.events model))))
                    (map (lambda (event) (list .scope_model "_'''." (.event event))) (modeling-events model))
                    (list 'illegal)))})
