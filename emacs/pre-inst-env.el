;;; To put Emacs in pre-inst-env environment:
;;; echo $GUIX_ENVIRONMENT => /gnu/store/...-profile
;;; M-x guix-set-emacs-environment RET /gnu/store/...-profile RET
;;; M-X ide:pre-inst-env

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
