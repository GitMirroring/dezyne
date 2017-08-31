((nil
  .
  ((indent-tabs-mode . nil)
   (eval
    .
    (progn
      (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)
      (defun dzn-setup-devel ()
        (interactive)
        (let ((top (locate-dominating-file default-directory ".dir-locals.el")))
          (save-excursion
            (shell (get-buffer-create "*daemon*"))
            (insert (format "cd %sdzn-daemon && make debug" top))
            (comint-send-input))
          (save-excursion
            (shell (get-buffer-create "*server*"))
            (insert (format "cd %sserver && make debug" top))
            (comint-send-input))
          (shell)
          (insert (format "cd %s && make VERBOSE= hello" top))
          (comint-send-input)))))))
 ("gaiag/templates"
  .
  ((nil
    .
    ((eval
      .
      (remove-hook 'before-save-hook 'delete-trailing-whitespace t))))))
 (c++-mode
  .
  ((c-basic-offset . 2)
   (eval
    .
    (progn
      (c-set-offset 'substatement-open 0)
      (c-set-offset 'member-init-intro 0)
      (c-set-offset 'innamespace [0])))))
 (js-mode
  .
  ((js-indent-level . 2)))
 (scheme-mode
  .
  ((geiser-active-implementations . '(guile))
   (eval
    .
    (progn
      (defun prefix-dir-locals-dir (elt)
        (concat (locate-dominating-file buffer-file-name ".dir-locals.el") elt))
      (mapcar
       (lambda (dir) (add-to-list 'geiser-guile-load-path dir))
       (mapcar
        #'prefix-dir-locals-dir
        '("gaiag"))))))))
