;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; To put Emacs in pre-inst-env environment:
;;; echo $GUIX_ENVIRONMENT => /gnu/store/...-profile
;;; M-x guix-set-emacs-environment RET /gnu/store/...-profile RET
;;; M-X ide:pre-inst-env
;;;
;;; Code:

(defun add-to-env-path (dir name)
  (let* ((current-value (getenv name))
         (new-path (if (not current-value) dir
                     (concat dir ":" current-value))))
    (setenv name new-path)
    (when (equalp name "PATH")
      (setq exec-path (split-string new-path ":")))
    new-path))

(defun ide:pre-inst-env ()
    (let* ((top (locate-dominating-file buffer-file-name ".dir-locals.el"))
           (top (expand-file-name top)))
      (mapcar
       (lambda (suffix)
         (let ((dir (concat top suffix)))
           (mapcar
            #'(lambda (name) (add-to-env-path dir name))
            '("GUILE_LOAD_PATH"
              "GUILE_LOAD_COMPILED_PATH"))))
       '(""))
      (add-to-env-path (concat top "/bin") "PATH")
      (setenv "DZN_PREFIX" top)
      (setenv "DZN_UNINSTALLED" "1")))

(ide:pre-inst-env)
