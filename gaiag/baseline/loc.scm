;;; Dezyne --- Dezyne command line tools
;;;
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

(root (interface
        iloc
        (types)
        (events
          (in (signature (type void)) e)
          (out (signature (type void)) a))
        (behaviour
          #f
          (types)
          (variables)
          (functions)
          (compound
            (on (triggers (trigger #f e))
                (action (trigger #f a))))))
      (component
        loc
        (ports (provides iloc i #f))
        (behaviour
          #f
          (types)
          (variables)
          (functions)
          (compound
            (on (triggers (trigger i e))
                (action (trigger i a))))))
      (locations
        (root ((location "examples/loc.dzn" 0 0 0 #f)
               interface
               iloc
               (types)
               (events
                 (in (signature
                       ((location "examples/loc.dzn" 2 5 22 #f)
                        type
                        void))
                     e)
                 (out (signature
                        ((location "examples/loc.dzn" 2 5 22 #f)
                         type
                         void))
                      a))
               (behaviour
                 #f
                 (types)
                 (variables)
                 (functions)
                 (compound
                   ((location "examples/loc.dzn" 6 4 64 #f)
                    on
                    (triggers
                      ((location "examples/loc.dzn" 6 7 67 #f)
                       trigger
                       #f
                       e))
                    ((location "examples/loc.dzn" 6 10 70 #f)
                     action
                     (trigger #f a))))))
              ((location "examples/loc.dzn" 10 0 80 #f)
               component
               loc
               (ports (provides iloc i #f))
               (behaviour
                 #f
                 (types)
                 (variables)
                 (functions)
                 (compound
                   ((location "examples/loc.dzn" 15 4 135 #f)
                    on
                    (triggers
                      ((location "examples/loc.dzn" 15 7 138 #f)
                       trigger
                       i
                       e))
                    ((location "examples/loc.dzn" 15 12 143 #f)
                     action
                     (trigger i a)))))))))
