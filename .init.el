(add-hook 'c++-mode-hook
  '(lambda()
    (setq indent-tabs-mode nil)
    (setq c-basic-offset 2)
    (c-set-offset 'substatement-open 0)
    (c-set-offset 'member-init-intro 0)
    (c-set-offset 'innamespace [0])))

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(defun dzn-setup-devel ()
  (interactive)
  (save-excursion
    (shell (get-buffer-create "*daemon*"))
    (insert "cd ~/development.git/daemon && make debug")
    (comint-send-input))
  (save-excursion
    (shell (get-buffer-create "*server*"))
    (insert "cd ~/development.git/server && make debug")
    (comint-send-input))
  (shell)
  (insert "cd ~/development.git && make hello")
  (comint-send-input))
