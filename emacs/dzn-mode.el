;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016, 2018 Rutger van Beusekom <rutger@dezyne.org>
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

;; Installation
;;
;; * Add to your ~/.config/emacs/init.el
;;
;;   (when (require 'dzn-mode nil t)
;;     (push '("\\.dzn\\'" . dzn-mode) auto-mode-alist))
;;
;; * Evaluate ~/.config/emacs/init.el or restart Emacs

;;; Code:

(require 'compile)
(require 'easymenu)

(defconst dzn-windows-p (eq system-type 'windows-nt)
  "Is Emacs running on Windows?")

(defun PATH-search-path (file-name)
  (locate-file file-name (split-string (getenv "PATH") ":") nil 'executable))

(defcustom dzn-program
  (if (or (PATH-search-path "dzn")
          (not load-file-name) dzn-windows-p) "dzn"
    (let* ((dir (file-name-directory load-file-name))
           (pre-inst-env (concat dir "../pre-inst-env")))
      (if (file-exists-p pre-inst-env) (concat pre-inst-env " dzn")
        (concat dir "../bin/dzn"))))
  "dzn command.")
;;(setq dzn-program "~/src/verum/ide/daemon/pre-inst-env dzn")

(defcustom dzn-dot-program "dot"
  "The name of the dot executable.")

(defvar dzn-ticket nil
  "The session.")
(setq dzn-ticket nil)

(defcustom dzn-include-dirs nil
  "Current list of include directories.")

(defcustom dzn-model ""
  "Current model.")

(defcustom dzn-models nil
  "Current models.")
(setq dzn-models nil)

(defvar dzn-guess-model nil
  "Current model.")

(defun dzn-command-p (command)
  (zerop (call-process-shell-command command nil nil nil)))

(defun dzn-hello-p ()
  (and dzn-program
       (dzn-command-p (concat dzn-program " hello"))))

(defun dzn-after-save ()
  (when (eq major-mode 'dzn-mode)
    (if (not dzn-ticket) (message "no ticket!")
      (if (not (member 'dzn-handle-parse compilation-finish-functions))
          (push 'dzn-handle-parse compilation-finish-functions))
      (dzn-parse))))

(defun dzn-save (&optional add-p)
  "Parse for syntax errors after saving buffer.
Toggle on/off: M-x dzn-save RET."
  (interactive)
  (let ((active-p (member 'dzn-after-save after-save-hook)))
    (if (and active-p (not add-p))
        (remove-hook 'after-save-hook 'dzn-after-save t)
      (add-hook 'after-save-hook 'dzn-after-save t t))))

(defun get-models ()
  (let ((text (buffer-string))
        (result nil))
    (string-match "" text)
    (while (string-match "^\\(component\\|interface\\|system\\)\\s *\\([_A-Za-z][_0-9A-Za-z]*\\)[^{}]*{[^{}]*?\\(behavior\\|system\\)" text (match-end 0))
      (push (list (match-string 1 text) (match-string 2 text) (match-string 3 text)) result))
    (reverse result)))

(defun dzn-get-models ()
  (interactive)
  (let* ((models (get-models))
         (model-names (mapcar #'cadr models)))
    (setq dzn-models model-names)
    (message "models: %s" dzn-models)
    dzn-models))

(defun dzn-compile (command &optional buffer input)
  (lexical-let* ((current (current-buffer))
                 (buffer (or buffer (get-buffer-create "*dzn-compilation*"))))
    (display-buffer-in-side-window buffer nil)
    (let* ((buffer (compilation-start command nil (lambda (x) (buffer-name buffer))))
           (proc (get-buffer-process buffer)))
      (when (and proc input)
        (process-send-string proc (concat input "\n"))
        (process-send-eof proc)))))

(defun dzn-command (name options &optional buffer input)
  (dzn-compile (dzn-command-string name options) buffer input))

(defun dzn-pipe (commands &optional buffer input)
  (let ((command (mapconcat 'identity commands " | ")))
    (dzn-compile command buffer input)))

(defun dzn-add-include (dir)
  (interactive "D")
  (push dir dzn-include-dirs))

(defun dzn-command-list (name &optional options)
  (let* ((simple-p (member name '("hello")))
         (file (if simple-p ""
                 (buffer-file-name)))
         (includes (if simple-p nil
                     (mapcar (lambda (x) (concat "-I " x)) dzn-include-dirs))))
    `(,dzn-program ,name
                  ,@includes ,@options ,file)))

(defun dzn-command-string (name &optional options)
  (mapconcat 'identity (dzn-command-list name options) " "))

(defun dzn-hello ()
  (interactive)
  (setq dzn-ticket (dzn-hello-p)))

(defun dzn-handle-parse (buffer msg)
  (when (string-match "\*dzn-compil" (buffer-name buffer))
    (let ((success-p (string= msg "finished\n"))
          (window (get-buffer-window buffer)))
      (when (and success-p window)
        (delete-window window)))))

(defun dzn-parse ()
  (interactive)
  (when (not (member 'dzn-handle-parse compilation-finish-functions))
    (push 'dzn-handle-parse compilation-finish-functions))
  (dzn-command "parse" '() (get-buffer-create "*dzn-compile-parse*")))

(defun dzn-system ()
  (interactive)
  (let* ((name (concat (file-name-base (buffer-file-name)) ".png"))
         (buffer (get-buffer-create name))
         (graph (dzn-command-string "graph" '("--backend=system")))
         (dot (concat dzn-dot-program " -T png"))
         (commands (list graph dot))
         (command (mapconcat 'identity commands " | ")))
    (switch-to-buffer-other-window buffer)
    (call-process-shell-command command nil buffer t)
    (goto-char 0)
    (image-mode)))

(defun dzn-verify (model)
  (setq dzn-indexes nil)
  (setq dzn-eligible nil)
  (interactive (list (let ((prompt (format "model: ")))
                       (completing-read prompt
                                        (cons "" (or dzn-models (dzn-get-models)))
                                        nil t nil
                                        'dzn-model
                                        dzn-guess-model))))
  (let* ((model-option (if (and (stringp model)
                                (not (string= model "")))
                           (concat " --model=" model) ""))
         (verify (dzn-command-string "verify" (list model-option)))
         (simulate (dzn-command-string "simulate" '("--locations"))))
    (dzn-pipe (list verify simulate))
    (setq compilation-finish-functions '())))

(setq dzn-mode-map nil)
(defvar dzn-mode-map ()
  "Keymap used in `dzn-mode' buffers.")

(if dzn-mode-map ()
  (setq dzn-mode-map (make-sparse-keymap))
  (define-key dzn-mode-map "\C-c\C-c" 'compile)
  (define-key dzn-mode-map "\C-c\C-p" 'dzn-parse)
  (define-key dzn-mode-map "\C-c\C-s" 'dzn-system)
  (define-key dzn-mode-map "\C-c\C-v" 'dzn-verify))

(easy-menu-define dzn-command-menu
  dzn-mode-map
  "Menu used in dzn-mode."
  (append '("Dezyne")
          '([ "Compile" compile t])
          '([ "Parse" dzn-parse t])
          '([ "system" dzn-system t])
          '([ "Verify" dzn-verify t])))

(when (require 'cc-mode nil t)
  (unless (assoc "dezyne" c-style-alist)
    (push '("dezyne"
            (c-basic-offset . 2)
            (c-comment-only-line-offset . 0)
            (c-offsets-alist . ((statement-block-intro . +)
                                (substatement-open . 0)
                                (substatement-label . 0)
                                (label . 0)
                                ;; This helps with guards; Guards lack a
                                ;; semicolon
                                (statement-cont . 0))))
          c-style-alist)))

;; (setq c-style-alist (assoc-delete-all "dezyne" c-style-alist))

;;;###autoload
(defun dzn-mode ()
  "Major mode for editing Dezyne files.

COMMANDS
\\{dzn-mode-map}
VARIABLES

dzn-command-alist\t\talist from name to command"
  (interactive)
  (c++-mode)
  (c-set-style "dezyne")
  (setq major-mode 'dzn-mode)
  (setq mode-name "Dezyne")
  (use-local-map dzn-mode-map)
  (unless (ignore-errors (require 'dzn-ls nil t))
    (dzn-save t))
  (dzn-hello)
  (run-hooks 'dzn-mode-hook))

(require 'dzn-ide nil t)
(ignore-errors
  (require 'dzn-ls nil t))
(provide 'dzn-mode)
;;; dzn-mode.el ends here
