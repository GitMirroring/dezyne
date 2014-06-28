;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

((imports (import Sensor) (import Siren))
 (interface
   Console
   (types)
   (events
     (in void arm)
     (in void disarm)
     (out void detected)
     (out void deactivated))
   (behaviour
     a
     (types (enum States
                  (Disarmed Armed Triggered Disarming)))
     (variables
       (declare States state (field States Disarmed)))
     (compound
       (guard (field state Disarmed)
              (compound
                (on (arm)
                    (compound (assign state (field States Armed))))
                (on (disarm) (action illegal))))
       (guard (field state Armed)
              (compound
                (on (disarm)
                    (compound
                      (assign state (field States Disarming))))
                (on (optional)
                    (compound
                      (action detected)
                      (assign state (field States Triggered))))
                (on (arm) (action illegal))))
       (guard (field state Triggered)
              (compound
                (on (disarm)
                    (compound
                      (assign state (field States Disarming))))
                (on (arm) (action illegal))))
       (guard (field state Disarming)
              (compound
                (on (inevitable)
                    (compound
                      (action deactivated)
                      (assign state (field States Disarmed))))
                (on (arm disarm) (action illegal)))))))
 (component
   Alarm
   (ports (provides Console console)
          (requires Sensor sensor)
          (requires Siren siren))
   (behaviour
     d
     (types (enum States
                  (Disarmed Armed Triggered Disarming)))
     (variables
       (declare States state (field States Disarmed))
       (declare bool sounding false))
     (compound
       (guard (field state Disarmed)
              (compound
                (on ((field console arm))
                    (compound
                      (action (field sensor enable))
                      (assign state (field States Armed))))
                (on ((field console disarm)
                     (field sensor triggered)
                     (field sensor disabled))
                    (action illegal))))
       (guard (field state Armed)
              (compound
                (on ((field console arm)) (action illegal))
                (on ((field console disarm))
                    (compound
                      (action (field sensor disable))
                      (assign state (field States Disarming))))
                (on ((field sensor triggered))
                    (compound
                      (action (field console detected))
                      (action (field siren turnon))
                      (assign sounding true)
                      (assign state (field States Triggered))))
                (on ((field sensor disabled)) (action illegal))))
       (guard (field state Disarming)
              (compound
                (on ((field console arm) (field console disarm))
                    (action illegal))
                (on ((field sensor triggered)) (compound))
                (on ((field sensor disabled))
                    (compound
                      (guard sounding
                             (compound
                               (action (field console deactivated))
                               (action (field siren turnoff))
                               (assign state (field States Disarmed))
                               (assign sounding false)))
                      (guard otherwise
                             (compound
                               (action (field console deactivated))
                               (assign state (field States Disarmed))))))))
       (guard (field state Triggered)
              (compound
                (on ((field console arm)) (action illegal))
                (on ((field console disarm))
                    (compound
                      (action (field sensor disable))
                      (action (field siren turnoff))
                      (assign sounding false)
                      (assign state (field States Disarming))))
                (on ((field sensor triggered)
                     (field sensor disabled))
                    (action illegal))))))))
