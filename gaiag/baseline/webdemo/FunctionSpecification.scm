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
    i13_I
    (types
    )
    (events
      (event i3_e (signature (type void)) in)
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
          (compound
          )
        )
      )
    )
  )
  (component
    i84_function2
    (ports
      (port i14_i i13_I provides #f)
    )
    (behaviour
      #f
      (types
        (int i17_counter_t #f(range 0 2))
      )
      (variables
      )
      (functions
        (function
          i21_g
          (signature (type void)  (formals  (formal i18_counter (type i17_counter_t) in))) recursive
          (compound
            (return
            )
          )
        )
        (function
          i60_f
          (signature (type void)  (formals  (formal i24_counter (type i17_counter_t) in))) recursive
          (compound
            (if
              (expression
                (< (var i24_counter) 2))
              
              (call
                i21_g (arguments (expression
                  (+ (var i24_counter) 1))
              ))
            )
            (return
            )
          )
        )
      )
      (compound
        (on
          (triggers
            (trigger i14_i i3_e) )
          (compound
            (call
              i60_f (arguments (expression
                0)
            ))
          )
        )
      )
    )
  )
)
