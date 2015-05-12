;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2012--2014  Jan Nieuwenhuizen <janneke@gnu.org>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (g fifo)
  :use-module (ice-9 receive)
  :use-module (rnrs io ports)

  :use-module (g misc)
  :export (fifo))

(define (fifo string)
  (let ((file-name (tmpnam)))
    (mknod file-name 'fifo #o600 0)
    (if (=0 (primitive-fork))
        (let ((port (open-output-file file-name)))
          (display string port)
          (flush-output-port port)
          (close port)
          (delete-file file-name)
          (primitive-exit 0))
        file-name)))
