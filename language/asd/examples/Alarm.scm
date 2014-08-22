;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
     (in ((type void)) arm)
     (in ((type void)) disarm)
     (out ((type void)) detected)
     (out ((type void)) deactivated))
   (behaviour
     a
     (types (enum States
                  (Disarmed Armed Triggered Disarming)))
     (variables
       (variable
         (type States)
         state
         (value States Disarmed)))
     (functions)
     (compound
       (guard (value state Disarmed)
              (compound
                (on ((trigger #f arm))
                    (compound (assign state (value States Armed))))
                (on ((trigger #f disarm)) illegal)))
       (guard (value state Armed)
              (compound
                (on ((trigger #f disarm))
                    (compound
                      (assign state (value States Disarming))))
                (on (optional)
                    (compound
                      (action (trigger #f detected))
                      (assign state (value States Triggered))))
                (on ((trigger #f arm)) illegal)))
       (guard (value state Triggered)
              (compound
                (on ((trigger #f disarm))
                    (compound
                      (assign state (value States Disarming))))
                (on ((trigger #f arm)) illegal)))
       (guard (value state Disarming)
              (compound
                (on (inevitable)
                    (compound
                      (action (trigger #f deactivated))
                      (assign state (value States Disarmed))))
                (on ((trigger #f arm) (trigger #f disarm))
                    illegal))))))
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
       (variable
         (type States)
         state
         (value States Disarmed))
       (variable (type bool) sounding false))
     (functions)
     (compound
       (guard (value state Disarmed)
              (compound
                (on ((trigger console arm))
                    (compound
                      (action (trigger sensor enable))
                      (assign state (value States Armed))))
                (on ((trigger console disarm)
                     (trigger sensor triggered)
                     (trigger sensor disabled))
                    illegal)))
       (guard (value state Armed)
              (compound
                (on ((trigger console arm)) illegal)
                (on ((trigger console disarm))
                    (compound
                      (action (trigger sensor disable))
                      (assign state (value States Disarming))))
                (on ((trigger sensor triggered))
                    (compound
                      (action (trigger console detected))
                      (action (trigger siren turnon))
                      (assign sounding true)
                      (assign state (value States Triggered))))
                (on ((trigger sensor disabled)) illegal)))
       (guard (value state Disarming)
              (compound
                (on ((trigger console arm) (trigger console disarm))
                    illegal)
                (on ((trigger sensor triggered)) (compound))
                (on ((trigger sensor disabled))
                    (compound
                      (guard sounding
                             (compound
                               (action (trigger console deactivated))
                               (action (trigger siren turnoff))
                               (assign state (value States Disarmed))
                               (assign sounding false)))
                      (guard otherwise
                             (compound
                               (action (trigger console deactivated))
                               (assign state (value States Disarmed))))))))
       (guard (value state Triggered)
              (compound
                (on ((trigger console arm)) illegal)
                (on ((trigger console disarm))
                    (compound
                      (action (trigger sensor disable))
                      (action (trigger siren turnoff))
                      (assign sounding false)
                      (assign state (value States Disarming))))
                (on ((trigger sensor triggered)
                     (trigger sensor disabled))
                    illegal)))))))
