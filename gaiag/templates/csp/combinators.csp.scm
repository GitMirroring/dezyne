;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014, 2015, 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

channel illegal
channel range_error
channel type_error
channel transition_begin, transition_end
channel extensions_over_empty_channels_is_undefined

COMPLETE'(A') = ([]x:A' @ x-> COMPLETE'(A'))
                []
                ([]x:A' @ x-> illegal->STOP)

datatype event_enumeration_alphabet = #
(pipe-join
 (delete-duplicates
  (sort
   (map (lambda (x) (if (symbol-prefix? 'int. x) 'int.Int x))
        (map (lambda (x) (if (symbol-prefix? 'bool. x) 'bool.Bool x))
             (append
              (interface-events model identity)
              (type-values model)
              (return-values model)
              (list 'bool.Bool 'int.Int 'blocked 'the_end' 'inevitable 'optional 'modeling 'silent))))
   symbol<)))

IQ'(in',out',link',size') = let
N' = size'
external chase
Back = in'?x' -> (link'.out'!x' -> Back [] in'?x' -> queue_full -> STOP)
Front = Cell[[link'.out' <- out']]
Cell = link'.in'?x' -> link'.out'!x' -> Cell
within
       if (N'==1) then (Back[[link'.out' <- out']])
       else if(N'==2) then chase(Back [link'.out' <-> link'.in'] Front  \ {|link'|})
       else chase((Back [link'.out' <-> link'.in'] ([link'.out'<->link'.in'] x : <1..N'-2> @ Cell)) [link'.out' <-> link'.in'] Front \ {|link'|})

-- end of combinators
