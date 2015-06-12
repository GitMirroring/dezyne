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

(root
  (interface
    i23_I
    (types
    )
    (events
      (event i3_e (signature (type void)) in)
      (event i4_h (signature (type void)) out)
    )
    (behaviour
      #f
      (types
      )
      (variables
      )
      (functions
      )
      (compound
        (on
          (triggers
            (trigger #f i3_e) )
          (action
            (trigger #f i4_h))
        )
      )
    )
  )
  (component
    i103_nonrecursion
    (ports
      (port i24_i i23_I provides #f)
    )
    (behaviour
      #f
      (types
      )
      (variables
        (variable
          i28_b (type bool) (expression
            true)
        )
      )
      (functions
        (function
          i52_f
          (signature (type void) ) recursive
          (compound
            (call
              i60_g (arguments))
            (action
              (trigger i24_i i4_h))
            (return
            )
          )
        )
        (function
          i60_g
          (signature (type void) ) recursive
          (compound
            (assign
              i28_b (expression
                false)
            )
            (return
            )
          )
        )
      )
      (compound
        (on
          (triggers
            (trigger i24_i i3_e) )
          (compound
            (call
              i52_f (arguments))
            (if
              (expression
                (var i28_b))
              
              (compound
                (illegal
                )
              )
            )
          )
        )
      )
    )
  )
)
