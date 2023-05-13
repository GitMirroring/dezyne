;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2021, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger@dezyne.org>
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
;; The GNU project defaults.  These are also the GNU Emacs defaults.
;; Re-asserting theme here, however, as a courtesy for setups that use
;; a global override.
(
 ;; For writing GNU C code, see
 ;; https://www.gnu.org/prep/standards/html_node/Writing-C.html
 (c-mode . ((c-file-style . "gnu")
            (indent-tabs-mode . nil)))

 (makefile-mode . ((indent-tabs-mode . t)))

 (nil . ((indent-tabs-mode . nil)
         (fill-column . 72)
         (eval
          .
          (progn
            (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)))))

 (diff-mode . (eval (progn (remove-hook 'before-save-hook 'delete-trailing-whitespace t))))

 (java-mode . ((c-basic-offset 2)))

 (c-mode . ((c-file-style . "gnu")))

 (c++-mode
  .
  ((c-file-style . "gnu")
   (eval
    .
    (setq c-offsets-alist `((innamespace 0)
                            ,@c-offsets-alist)))))

 (scheme-mode
  .
  ((geiser-active-implementations . (guile))
   (eval
    .
    (progn
      (unless (boundp 'geiser-guile-load-path)
        (defvar geiser-guile-load-path '()))
      (defun prefix-dir-locals-dir (elt)
        (let* ((root-dir (locate-dominating-file buffer-file-name
                                                 ".dir-locals.el"))
               (root-dir (expand-file-name root-dir)))
          (concat root-dir elt)))
      (mapcar
       (lambda (dir) (add-to-list 'geiser-guile-load-path dir))
       (mapcar
        #'prefix-dir-locals-dir
        '(".")))))

   ;; Fixup for non-Guix Emacsen
   (eval . (put 'match 'scheme-indent-function 1))

   ;; Guix
   (eval . (put 'modify-phases 'scheme-indent-function 1))
   (eval . (put 'replace 'scheme-indent-function 1))
   (eval . (put 'add-before 'scheme-indent-function 2))
   (eval . (put 'add-after 'scheme-indent-function 2))
   (eval . (put 'wrap-program 'scheme-indent-function 1))
   (eval . (put 'substitute* 'scheme-indent-function 1))
   (eval . (put 'substitute-keyword-arguments 'scheme-indent-function 1))

   (eval . (put 'package 'scheme-indent-function 0))
   (eval . (put 'origin 'scheme-indent-function 0))
   (eval . (put 'with-directory-excursion 'scheme-indent-function 1))

   ;; SCMackerel
   (eval . (put 'process 'scheme-indent-function 0))))
   (eval . (put 'entity 'scheme-indent-function 0))

 (texinfo-mode    . ((indent-tabs-mode . nil)
                     (fill-column . 72))))
