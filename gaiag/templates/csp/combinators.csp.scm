;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014, 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

-- provided ports: #(comma-join (map .name (om:provided model)))
nametype bool = {false, true}

channel illegal
channel range_error
channel transition_begin, transition_end
channel extensions_over_empty_channels_is_undefined

COMPLETE'(A') = ([]x:A' @ x-> COMPLETE'(A'))
                []
                ([]x:A' @ x-> illegal->STOP)

datatype event_enumeration_alphabet = #
(pipe-join
  (delete-duplicates
   (sort
    (append
     (interface-events model identity)
     (enum-values model)
     (return-values model)
     (list 'blocked 'the_end' 'inevitable 'optional 'modeling))
    symbol<)))

-- end of combinators
