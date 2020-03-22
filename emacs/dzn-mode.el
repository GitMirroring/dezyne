;;; dzn-mode.el -- Minor mode for editing Dezyne files.
;;;
;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

;;; Installation
;;;
;;; * Add to your ~/.emacs
;;;
;;;   (require 'package)
;;;   (package-initialize)
;;;   (push '("\\.dzn\\'" . dzn-mode) auto-mode-alist)
;;;   (require 'dzn-mode)
;;;
;;; * Evaluate ~/.emacs or restart Emacs
;;;
;;; * Install websocket package from Elpa
;;;
;;;   select: Options/Manage Emacs Packages, or M-x list-packages
;;;

;;;; Code:

(require 'compile)
(require 'easymenu)

(setq dzn-daemon-p nil)
(when dzn-daemon-p
  (require 'json)
  (require 'websocket nil t))

(defconst dzn-windows-p (eq system-type 'windows-nt)
  "Is Emacs running on Windows?")

(defun PATH-search-path (file-name)
  (locate-file file-name (split-string (getenv "PATH") ":") nil 'executable))

(defcustom dzn-program (if (or (PATH-search-path "dzn")
                               (not load-file-name) dzn-windows-p) "dzn"
                         (let* ((dir (file-name-directory load-file-name))
                                (pre-inst-env (concat dir "../pre-inst-env")))
                           (if (file-exists-p pre-inst-env) (concat pre-inst-env " dzn")
                             (concat dir "../bin/dzn"))))
  "dzn command.")
;;(setq dzn-program "~/src/verum/ide/daemon/pre-inst-env dzn")

(defcustom dzn-daemon-url "http://localhost:4000" "the daemon url")
(setq dzn-daemon-url "htttp://localhost:0")

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

(setq dzn-browser-p nil)
(defvar dzn-browser-p ()
  "Have browser?.")

(defun dzn-command-p (command)
  ;; XXX dzn-program can be a shell command: "~/src/verum/ide/pre-inst-env dzn"
  ;;(zerop (call-process (PATH-search-path dzn-program) nil nil nil "check" "--help"))
  (zerop (call-process-shell-command command nil nil nil)))

(defun dzn-check-p ()
  (and dzn-program
       (dzn-command-p (concat dzn-program " check --help"))))

(defun dzn-hello-p ()
  (and dzn-program
       (dzn-command-p (concat dzn-program " hello"))))

(defun dzn-system-p ()
  (and dzn-program
       (dzn-command-p (concat dzn-program " system --help"))))

(defun assoc-ref (alist key &optional default)
  (let ((value (assoc-string key alist)))
    (if value (cdr value)
      default)))

(setq dzn-ws nil)
(setq dzn-ws-view-location nil)
(setq dzn-ws-select-view nil)
(setq dzn-ws-selected-view nil)
(setq dzn-guess-view 'system)
(setq dzn-guess-location 'i0)
(setq dzn-indexes '())

(defun dzn-goto-index (index)
  (interactive
   (list (let ((prompt (format "index: ")))
           (completing-read prompt
                            dzn-indexes
                            nil t nil
                            'dzn-selected-location
                            dzn-guess-location))))
  (if dzn-ws-select-view (funcall dzn-ws-select-view 'trace)
    (message "no socket"))
  (if dzn-ws-view-location (funcall dzn-ws-view-location `((id . ,index)))
    (message "no socket")))

(defun dzn-select-view (view)
  (interactive
   (list (let ((prompt (format "view: ")))
           (completing-read prompt
                            '(system trace diagram-state table-state table-event command)
                            nil t nil
                            'dzn-selected-view
                            dzn-guess-view))))
  (if dzn-ws-select-view (funcall dzn-ws-select-view view)
    (message "no socket")))

(defun dzn-register ()
  (interactive)
  (unless (and dzn-daemon-p
               (fboundp 'websocket-open))
    (require 'websocketxx nil t))
  (if (and dzn-daemon-p
           (fboundp 'websocket-open))
      (websocket-open
       (if (string-match "^[^:]+://" dzn-daemon-url)
           (message (replace-match "ws://" nil nil dzn-daemon-url)))
       :on-open (lambda (ws)
                  (message "OPEN! session=%s" dzn-session)
                  (websocket-send-text
                   ws
                   (json-encode
                    `((register . ((session . ,dzn-session)
                                   (type . editor)
                                   (name . emacs))))))
                  (setq dzn-ws ws)
                  (setq dzn-ws-select-view
                        (lambda (view)
                          (let ((msg (json-encode
                                      `((editor . ((view . ,(append
                                                             `((session . ,dzn-session)
                                                               (view . ,view))))))))))
                            ;;(message "SENDING: %s" msg)
                            (websocket-send-text dzn-ws msg))))
                  (setq dzn-ws-view-location
                        (lambda (location)
                          (let ((msg (json-encode
                                      `((editor . ((selection . ,(list
                                                                  (append
                                                                   `((session . ,dzn-session))
                                                                   location)))))))))
                            ;;(message "SENDING: %s" msg)
                            (websocket-send-text dzn-ws msg)))))
       :on-message (lambda (ws frame)
                     (message "FRAME: %s" frame)
                     ;;(message "ws msg: %s" (websocket-frame-payload frame))
                     (if frame
                         (let ((msg (websocket-frame-payload frame)))
                           ;;(message "ws msg: %s" msg)
                           (if msg
                               (let* ((envelope
                                       (let ((json-array-type 'list)) (json-read-from-string msg)))
                                      (type (caar envelope))
                                      (data (cdar envelope)))
                                 ;;(message "envelope: %s" envelope)
                                 ;;(message "type: %s" type)
                                 ;;(message "data: %s" data)
                                 (cond ((eq type 'editor)
                                        (let* ((selection (assoc-ref data 'selection))
                                               (location (and selection (car selection))))
                                          (goto-location location)))))))))
       :on-close (lambda (ws)
                   (setq dzn-ws nil)
                   (setq dzn-ticket nil)
                   (setq dzn-ws-view-location nil)
                   (setq dzn-ws-select-view nil)
                   (setq dzn-last-buffer nil)
                   (setq dzn-browser-p nil)
                   (message "CLOSE"))
       :on-error (lambda (ws type err)
                   (message "ERROR: type:%s, err:%s" type err)))
    (if dzn-daemon-p (message "warning: websocket-open not available"))))

(defun dzn-close ()
  (interactive)
  (when dzn-ws
    (websocket-close dzn-ws))
  (setq dzn-ticket nil)
  (setq dzn-ws nil))

(setq dzn-mode-debug-p t)

(defun goto-location (location)
  (when (assoc-ref location 'file)
      (with-temp-buffer
        (let* ((file (assoc-ref location 'file "*scratch*"))
               (line (assoc-ref location 'line 0))
               (column (assoc-ref location 'column 0))
               (focus-p (assoc-ref location 'focus nil))
               (id (assoc-ref location 'index nil))
               (offset (assoc-ref location 'offset 0))
               (length (assoc-ref location 'length 0))
               (length (and (> length 0) length))
               (end (assoc-ref location 'end nil)))
          (when dzn-mode-debug-p
            (message "file %s [%s]" file (type-of file))
            (message "line %s [%s]" line (type-of line))
            (message "column %s [%s]" column (type-of column))
            (message "offset %s [%s]" offset (type-of offset))
            (message "focus-p %s [%s]" focus-p (type-of focus-p))
            (if (and (= line 0) (not (= offset 0)))
                (message "%s:@%s" file offset)
              (message "%s:%s:%s" file line column)))
          (if (not (file-exists-p file))
              (message "no such file: %s" file)
            ;;(or dzn-location-trigger-p (setq dzn-location-trigger-p (current-buffer)))
            (if (find-buffer-visiting file)
                (pop-to-buffer (find-buffer-visiting file))
              (find-file file))
            (when (and (or end length) (mark))
              (setq mark-active (or end length)))
            (when (or end length)
              (goto-char 0)
              (let ((end-line (assoc-ref end 'line 0))
                    (end-column (assoc-ref end 'column 0))
                    (end-offset (or (assoc-ref end 'offset nil)
                                    (and length offset (+ offset (- length 1)))
                                    offset)))
                (if (and (= end-line 0) (not (= end-offset 0)))
                  (goto-char (1+ end-offset))
                  (goto-line end-line)
                  (forward-char (1- end-column)))
                (push-mark nil t)))
            (goto-char 0)
            (if (and (= line 0) (not (= offset 0)))
                (goto-char (1+ offset))
              (forward-line (1- line))
              (forward-char (1- column)))
            (when focus-p
              (select-frame-set-input-focus (car (frame-list))))
            (when dzn-location-trigger-p
              (switch-to-buffer-other-window dzn-location-trigger-p)
              (setq dzn-location-trigger-p nil))))))

  (defun dzn-file-at-point ()
    (interactive)
    (save-excursion
      (move-to-column 0)
      (search-forward-regexp dzn-location-regexp (point-max) t)
      (dzn-match2location))))

(setq dzn-location-regexp
      "^\\([^ :\n]+\\):\\([-0-9]+\\)\\(?::\\([-0-9]+\\)\\)?\\(?::i\\([-0-9]+\\)\\)?: *\\([^\n]*[^\n ]\\)")

(defun dzn-match2location ()
  (if (match-beginning 1)
      (let* ((match (buffer-substring-no-properties (match-beginning 0) (match-end 0)))
             (file (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
             (line (string-to-number (buffer-substring-no-properties (match-beginning 2) (match-end 2))))
             (column (and (match-beginning 3) (string-to-number (buffer-substring-no-properties (match-beginning 3) (match-end 3)))))
             (index (and (match-beginning 4) (string-to-number (buffer-substring-no-properties (match-beginning 4) (match-end 4)))))
             (message (and (match-beginning 5) (buffer-substring-no-properties (match-beginning 5) (match-end 5))))
             (location `((match . ,match) (file . ,file) (line . ,line) (column . ,column) (index . ,index) (message . ,message))))
        location)))

(setq dzn-location-trigger-p nil)
(defun dzn-next-error-follow ()
  (let ((fap (dzn-file-at-point)))
    (setq dzn-location-trigger-p (current-buffer))
    (if fap
        (save-excursion
          (if dzn-ws-view-location
              (funcall dzn-ws-view-location fap)
            (goto-location fap))))))

(defun dzn-follow (&optional add-p)
  "Use M-x dzn-follow in *compilation* buffer."
  (interactive)
  (let ((active-p (member 'dzn-next-error-follow post-command-hook)))
    (if (and active-p (not add-p))
        (remove-hook 'post-command-hook 'dzn-next-error-follow t)
      (add-hook 'post-command-hook 'dzn-next-error-follow t t))))

(defun dzn-follow-view ()
  (dzn-update))

(defvar dzn-last-buffer (current-buffer)
  "Most recent DZN buffer")

(defun dzn-buffer-link-view ()
  (let ((buffer (current-buffer)))
    (when (and dzn-ticket
               (eq minor-mode 'dzn-mode)
               (file-exists-p (buffer-file-name)))
      ;; XXX: Not good
      ;; (unless dzn-ws
      ;;   (setq dzn-last-buffer nil)
      ;;   (if dzn-ticket
      ;;       (dzn-register)
      ;;     (dzn-hello)))
      ;; FIXME: add as registered-hook?
      (unless (equal buffer dzn-last-buffer)
        (setq dzn-last-buffer buffer)
        (dzn-follow-view)))))

(defun dzn-link (&optional add-p)
  "Update views when switching buffers.
Toggle on/off: M-x dzn-save RET."
  (interactive)
  (let ((active-p (member 'dzn-buffer-link-view post-command-hook)))
    (if (and active-p (not add-p))
        (remove-hook 'post-command-hook 'dzn-buffer-link-view t)
      (add-hook 'post-command-hook 'dzn-buffer-link-view t t))))

(setq compilation-finish-functions nil)
(defun dzn-after-save ()
  (when (eq minor-mode 'dzn-mode)
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

(defun dzn-get-models ()
  (interactive)
  (let ((interfaces
         (split-string
          (shell-command-to-string (dzn-command-string "parse" '("--interfaces" "2>/dev/null")))))
        (components
         (split-string
          (shell-command-to-string (dzn-command-string "parse" '("--components" "2>/dev/null")))))
        (systems
         (split-string
          (shell-command-to-string (dzn-command-string "parse" '("--systems" "2>/dev/null"))))))
    (setq dzn-models (append systems components interfaces))
    (message "models: %s" dzn-models)
    dzn-models))

(defun dzn-browse (&optional url-or-prefix)
  (interactive "P")
  (let* ((prefix-p (equal url-or-prefix '(4)))
         (url (and (called-interactively-p t)
                   (not prefix-p)
                   url-or-prefix)))
    (if prefix-p (switch-to-buffer-other-window nil))
    (if (or (not dzn-browser-p) (called-interactively-p t))
        (setq dzn-browser-p
              (and dzn-daemon-p
                   (shell-command (dzn-command-string "browse" (if url `(,url) '()))))))))

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

(defun dzn-add-include (dir)
  (interactive "D")
  (push dir dzn-include-dirs))

(defun dzn-command-list (name &optional options)
  (let* ((simple-p (member name '("browse" "cat" "hello" "ls" "query")))
         (file (if simple-p ""
                 (buffer-file-name)))
         (includes (if simple-p nil
                     (mapcar (lambda (x) (concat "-I " x)) dzn-include-dirs))))
    `(,dzn-program ,name
                  ,@includes ,@options ,file)))

(defun dzn-command-string (name &optional options)
  (mapconcat 'identity (dzn-command-list name options) " "))

(defun dzn-run (model)
  (interactive (list (let ((prompt (format "model: ")))
                       (completing-read prompt
                                        (or dzn-models (dzn-get-models))
                                        nil t nil
                                        'dzn-model
                                        dzn-guess-model))))
  (setq dzn-indexes nil)
  (setq dzn-eligible nil)
  (let* ((model-option (if (and (stringp model)
                                (not (string= model "")))
                           (concat " --model=" model) "")))
    (dzn-command "run" (list model-option) nil "")
    (setq dzn-model model)
    (setq compilation-finish-functions '())
    (if (not (member 'dzn-handle-trace compilation-finish-functions))
        (push 'dzn-handle-trace compilation-finish-functions))))

(defun dzn-run-event (event)
  (interactive (list (let* ((next (and (= (length dzn-eligible) 1)
                                       (car dzn-eligible)))
                            (prompt (format "event: ")))
                       (completing-read prompt dzn-eligible nil t next
                                        'dzn-trace-history
                                        nil))))
  (dzn-command "run" (list (concat "--model=" dzn-model) "--forward=") nil event)
  (setq compilation-finish-functions '())
  (if (not (member 'dzn-handle-trace compilation-finish-functions))
      (push 'dzn-handle-trace compilation-finish-functions)))

(defun dzn-run-back ()
  (interactive)
  (dzn-command "run" '("--back"))
  (setq compilation-finish-functions '())
  (if (not (member 'dzn-handle-trace compilation-finish-functions))
      (push 'dzn-handle-trace compilation-finish-functions)))

(defvar dzn-eligible ()
  "Eligible events.")

(defun dzn-handle-trace (buffer msg)
  (when (equal (buffer-name buffer) "*dzn-compilation*")
    (or dzn-ws (dzn-register))
    (dzn-browse)
    (let* ((success-p (string= msg "finished\n"))
           (fail-p
            (with-current-buffer buffer
              (save-excursion
                (and (goto-char (point-min))
                     (search-forward-regexp "\nverify:[^\n]*: fail" nil t)
                     (goto-char (point-min))))))
           (verify-p
            (with-current-buffer buffer
              (save-excursion
                (goto-char (point-min))
                (search-forward-regexp "[\n|/]dzn[^\n]*verify" nil t))))
           (eligible
            (with-current-buffer buffer
              (save-excursion
                (goto-char (point-min))
                (or (search-forward-regexp "[\n](eligible \\([^)]*\\)" nil t)
                    (search-forward-regexp "[\n]eligible: *\\(.*\\)" nil t))
                (if (match-beginning 1)
                    (split-string
                     (buffer-substring-no-properties
                      (match-beginning 1) (match-end 1)) ",")
                  nil))))
           (trace (with-current-buffer buffer
                    (save-excursion
                      (goto-char (point-min))
                      (search-forward-regexp "trace:\\(.*\\)" nil t)
                      (if (match-beginning 1)
                          (split-string
                           (buffer-substring-no-properties
                            (match-beginning 1) (match-end 1)) ",")
                        nil))))
           (indexes (with-current-buffer buffer
                      (save-excursion
                        (goto-char (point-min))
                        (let ((lst nil))
                          (while (search-forward-regexp dzn-location-regexp (point-max) t)
                            (let* ((location (dzn-match2location))
                                   (id (assoc-ref location 'id)))
                              (if id (push id lst))))
                          (reverse lst))))))
      (message "result: success-p=%s, fail-p=%s" success-p fail-p)
      (dzn-follow t)
      (if dzn-ws-select-view (funcall dzn-ws-select-view 'trace))
      (message "eligible: %s" eligible)
      (setq dzn-eligible eligible)
      (setq dzn-indexes indexes))))

(defun dzn-handle-hello (buffer msg)
  (when (string-match "\*dzn-compile-hello\*" (buffer-name buffer))
    (let ((success-p (string= msg "finished\n"))
          (window (get-buffer-window buffer)))
      (setq dzn-ticket success-p)
      (when (and success-p window)
        (delete-window window))
      (if success-p
          (if (not dzn-ws) (dzn-register))
        (message "authentication failed, use dzn -u <user> -p hello")))))

(defun dzn-hello (&optional password)
  (interactive)
  (when (not (member 'dzn-handle-hello compilation-finish-functions))
    (push 'dzn-handle-hello compilation-finish-functions))
  (with-timeout (1 (setq dzn-ticket nil))
    (dzn-command "hello" '() (get-buffer-create "*dzn-compile-hello*"))))

(defun dzn-handle-parse (buffer msg)
  (when (string-match "\*dzn-compil" (buffer-name buffer))
    (or dzn-ws (ignore-errors (dzn-register)))
    (dzn-browse)
    (let ((success-p (string= msg "finished\n"))
          (window (get-buffer-window buffer)))
      (when (and success-p window)
        (delete-window window)))
    (when dzn-ws-select-view (funcall dzn-ws-select-view 'system))))

(defun dzn-parse ()
  (interactive)
  (when (not (member 'dzn-handle-parse compilation-finish-functions))
    (push 'dzn-handle-parse compilation-finish-functions))
  (dzn-command "parse" '() (get-buffer-create "*dzn-compile-parse*")))

(defun dzn-view ()
  (interactive)
  (if (not (member 'dzn-handle-parse compilation-finish-functions))
      (push 'dzn-handle-parse compilation-finish-functions))
  (when (dzn-system-p)
    (dzn-command "system" '() (get-buffer-create "*dzn-compile-system*"))))

(defun dzn-update ()
  (interactive)
  (setq dzn-models nil)
  (dzn-browse)
  (setq dzn-master-buffer (current-buffer))
  (dzn-view))

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
                           (concat " --model=" model) "")))
    (if (dzn-check-p) (dzn-command "check" (list "--verbose" model-option))
      (dzn-command "--verbose verify" (list model-option)))
    (setq compilation-finish-functions '())
    (if (and dzn-daemon-p
             (not (member 'dzn-handle-trace compilation-finish-functions)))
        (push 'dzn-handle-trace compilation-finish-functions))))

(setq dzn-examples-alist nil)
(defun dzn-list-examples ()
  (interactive)
  (let* ((examples
          (shell-command-to-string
           (dzn-command-string "cat" '("/share/examples/index.txt"))))
         (examples-alist
          (mapcar (lambda (x) (split-string x "\n"))
                  (split-string examples "\n\n"))))
    (setq dzn-examples-alist examples-alist)
    dzn-examples-alist))

(defun dzn-download-file (url dir &optional project-p)
  (lexical-let ((dir dir)
                (project-p project-p)
                (url url))
    (lambda (file)
      (lexical-let ((file file))
        (message "download %s into %s" file dir)
        (if t
            (save-window-excursion
              (async-shell-command
               (concat " " (dzn-command-string "cat" `(,(concat "/share/examples/" (if project-p (concat dir "/") "") file))) "> " (concat dir "/" file))
               (concat "*dzn-download-" dir "/" file "*")))
          (url-retrieve
           (if project-p (concat url "/" dir "/" file)
             (concat url "/" file))
           (lambda (s)
             (re-search-forward "\r?\n\r?\n")
             (write-region (point) (point-max) (concat dir "/" file)))))))))

(defun dzn-find (predicate lst)
  (if (not lst) nil
    (if (funcall predicate (car lst)) (car lst)
      (dzn-find predicate (cdr lst)))))

(defun dzn-current-branch ()
  (interactive)
  (let* ((query (shell-command-to-string (dzn-command-string "query" nil)))
         (current-p (lambda (v)
                      (and (string-match "[*] \\(.*\\)" v)
                           (substring v (match-beginning 1) (match-end 1)))))
         (branch (dzn-find current-p (split-string query "\n"))))
    (and branch (funcall current-p branch))))

(defun dzn-get-dzn.json ()
  (let* ((dzn-json (concat (getenv "HOME") "/.dzn.json"))
         (string (with-temp-buffer (insert-file-contents dzn-json) (buffer-string))))
    (json-read-from-string string)))

(defun dzn-current-url ()
  (assoc-ref (dzn-get-dzn.json) 'url))

(defun dzn-example (example)
  (interactive
   (list (let ((prompt (format "example: ")))
           (completing-read prompt
                            (or dzn-examples-alist (dzn-list-examples))
                            nil t nil
                            'dzn-example
                            nil))))
  (let* ((prefix "/share/examples")
         (ls (shell-command-to-string
              (dzn-command-string "ls" `(,prefix))))
         (entry (string-match (concat "^" example ".*") ls))
         (file (substring ls (match-beginning 0) (match-end 0)))
         (branch (dzn-current-branch))
         (server (dzn-current-url))
         (url (concat server "/" branch "/fs" prefix)))
    (mkdir example t)
    (if (string-suffix-p "/" file)
        (let* ((ls (shell-command-to-string
                    (dzn-command-string
                     "ls" `(,(concat prefix "/" file)))))
               (files (nbutlast (split-string ls "\n") 1)))
          (mapcar (dzn-download-file url example t) files))
      (funcall (dzn-download-file url example nil) file))
    (sleep-for 2)
    (find-file (concat example "/" example ".dzn"))))

(setq dzn-mode-map nil)
(defvar dzn-mode-map ()
  "Keymap used in `dzn-mode' buffers.")

(if dzn-mode-map ()
  (setq dzn-mode-map (make-sparse-keymap))
  (define-key dzn-mode-map "\C-c\C-c" 'compile)
  (define-key dzn-mode-map "\C-c\C-r" 'dzn-run)
  (define-key dzn-mode-map "\C-c\C-e" 'dzn-run-event)
  (define-key dzn-mode-map "\C-c\C-b" 'dzn-run-back)
  (define-key dzn-mode-map "\C-c\C-p" 'dzn-parse)
  (define-key dzn-mode-map "\C-c\C-u" 'dzn-update)
  (define-key dzn-mode-map "\C-c\C-v" 'dzn-verify))

(easy-menu-define dzn-command-menu
  dzn-mode-map
  "Menu used in dzn-mode."
  (append '("Dezyne")
          '([ "Compile" compile t])
          '([ "Goto index" dzn-goto-index t])
          '([ "Parse" dzn-parse t])
          '([ "Register Emacs" dzn-register t])
          '([ "Run" dzn-run t])
          '([ "Run event" dzn-run-event t])
          '([ "Run back" dzn-run-back t])
          '([ "Select view" dzn-select-view t])
          '([ "Update views" dzn-update t])
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
  "Minor mode for editing Dezyne files.

COMMANDS
\\{dzn-mode-map}
VARIABLES

dzn-command-alist\t\talist from name to command"
  (interactive)
  (c++-mode)
  (c-set-style "dezyne")
  (setq minor-mode 'dzn-mode)
  (setq mode-name "Dezyne")
  (use-local-map dzn-mode-map)
  (dzn-save t)
  ;; XXX Demo of linking view is nice; but obnoxious in use
  ;; Better: C-c C-u
  ;; (dzn-link t)
  (if dzn-ticket
      (dzn-register)
    (dzn-hello)))

(provide 'dzn-mode)
;;; dzn-mode.el ends here
