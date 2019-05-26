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

 (scheme-mode
  .
  ((geiser-active-implementations . (guile))
   (eval
    .
    (progn
      (defun prefix-dir-locals-dir (elt)
        (concat (locate-dominating-file buffer-file-name ".dir-locals.el") elt))
      (mapcar
       (lambda (dir) (add-to-list 'geiser-guile-load-path dir))
       (mapcar
        #'prefix-dir-locals-dir
        '(".")))))

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

   ;; Emacsy
   (eval . (put 'with-current-buffer 'scheme-indent-function 1))
   (eval . (put 'save-excursion 'scheme-indent-function 1))))

 (texinfo-mode    . ((indent-tabs-mode . nil)
                     (fill-column . 72))))
