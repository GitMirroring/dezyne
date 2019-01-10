((makefile-mode . ((indent-tabs-mode . t)))
 (nil
  .
  ((indent-tabs-mode . nil)
   (eval
    .
    (progn
      (let ((top (locate-dominating-file default-directory ".dir-locals.el")))
        (push (concat top "/dzn/elisp") load-path))

      (when (and (require 'dzn-mode nil t)
                 (not (assoc "\\.dzn\\'" auto-mode-alist)))
        (push '("\\.dzn\\'" . dzn-mode) auto-mode-alist))

      (when (and (require 'c++-mode nil t)
                 (not (assoc "\\.hh.in\\'" auto-mode-alist)))
        (push '("\\.hh.in\\'" . dzn-mode) auto-mode-alist)
        (push '("\\.cc.in\\'" . dzn-mode) auto-mode-alist))

      (when (and (require 'javascript-mode nil t)
                 (not (assoc "\\.js.in\\'" auto-mode-alist)))
        (push '("\\.js.in\\'" . dzn-mode) auto-mode-alist))

      (defun guile--manual-look-up (id mod)
        (message "guile--manual-look-up id=%s => %s mod=%s" id (symbol-name id) mod)
        (let ((info-lookup-other-window-flag
               geiser-guile-manual-lookup-other-window-p))
          (info-lookup-symbol (symbol-name id) 'scheme-mode))
        (when geiser-guile-manual-lookup-other-window-p
          (switch-to-buffer-other-window "*info*"))
        (search-forward (format "%s" id) nil t))

      (add-hook 'before-save-hook 'delete-trailing-whitespace nil t)

      (defun guix-switch-profile (&optional profile)
        "reset Emacs' environment by snarfing PROFILE/etc/profile"

        (defun matches-in-string (regexp string)
          "return a list of matches of REGEXP in STRING."
          (let ((matches))
            (save-match-data
              (string-match "^" "")
              (while (string-match regexp string (match-end 0))
                (push (or (match-string 1 string) (match-string 0 string)) matches)))
            matches))

        (interactive "fprofile: ")
        (let* ((output (shell-command-to-string (concat "GUIX_PROFILE= /bin/sh -x " profile "/etc/profile")))
               (exports (matches-in-string "^[+] export \\(.*\\)" output)))
          (mapcar (lambda (line) (apply #'setenv (split-string line "="))) exports )))

      (defun dzn-setup-devel ()
        (interactive)
        (shell-command "killall -9 node nodejs")
        (let ((top (locate-dominating-file default-directory ".dir-locals.el")))
          (save-excursion
            (shell (get-buffer-create "*daemon*"))
            (insert (format "cd %s && ./pre-inst-env dzn start -ddd | bunyan" top))
            (comint-send-input))
          (save-excursion
            (shell (get-buffer-create "*server*"))
            (insert (format "cd %s && ./pre-inst-env dzn-server | bunyan" top))
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
        '("gaiag" "guix")))))
   ;; Guix
   (eval . (put 'modify-services 'scheme-indent-function 1))
   (eval . (put 'with-imported-modules 'scheme-indent-function 1))
   (eval . (put 'mlet* 'scheme-indent-function 2))
   (eval . (put 'mlet 'scheme-indent-function 2)))))
