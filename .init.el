(add-hook 'c++-mode-hook
  '(lambda()
    (setq indent-tabs-mode nil)
    (setq c-basic-offset 2)
    (c-set-offset 'substatement-open 0)
    (c-set-offset 'member-init-intro 0)
    (c-set-offset 'innamespace [0])))

(push '("\\.dzn$" . c++-mode) auto-mode-alist)


(add-hook 'before-save-hook 'delete-trailing-whitespace)
