;;; Personal Functions
;;
;; By convention, I start them all with `sam--'

(defun sam--view-clipboard ()
  (interactive)
  (delete-other-windows)
  (switch-to-buffer "*Clipboard*")
  (let ((inhibit-read-only t))
    (erase-buffer)
    (clipboard-yank)
    (goto-char (point-min))))

(defun sam--revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer t t))

(defun sam--insert-timestamp ()
  "Insert a quick timestamp."
  (interactive)
  (insert (format "%s" (format-time-string "%Y-%m-%d" (current-time)))))

(defun sam--duplicate-line ()
  "Duplicate the line containing point."
  (interactive)
  (save-excursion
    (let (line-text)
      (goto-char (line-beginning-position))
      (let ((beg (point)))
        (goto-char (line-end-position))
        (setq line-text (buffer-substring beg (point))))
      (if (eobp)
          (insert ?\n)
        (forward-line))
      (open-line 1)
      (insert line-text))))

(defun sam--comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)))

(defun sam--switch-to-other-buffer ()
  "Switch to other buffer"
  (interactive)
  (switch-to-buffer (other-buffer)))

(defun sam--edit-init-file ()
  "Edit the emacs init file"
  (interactive)
  (find-file "~/dotfile/emacs/init.el"))

(defun sam--edit-keybindings ()
  (interactive)
  (find-file "~/dotfile/emacs/keybindings.el"))

(defun sam--edit-functions ()
  (interactive)
  (find-file "~/dotfile/emacs/functions.el"))

(defun sam--edit-todo ()
  (interactive)
  (find-file "~/TODO"))

(defun sam--chrome-plain-link ()
  (interactive)
  (insert (concat " " (grab-mac-link 'chrome 'plain))))

(defun sam--chrome-org-link ()
  (interactive)
  (insert (concat " " (grab-mac-link 'chrome 'org))))

(defun sam--chrome-md-link ()
  (interactive)
  (insert (concat " " (grab-mac-link 'chrome 'markdown))))

(defun sam--finder-md-link ()
  (interactive)
  (insert (grab-mac-link 'finder 'markdown)))

(defun sam--eval-current-form-sp (&optional arg)
  "Call `eval-last-sexp' after moving out of one level of
parentheses. Will exit any strings and/or comments first.
Requires smartparens because all movement is done using
`sp-up-sexp'. An optional ARG can be used which is passed to
`sp-up-sexp' to move out of more than one sexp."
  (interactive "p")
  (require 'smartparens)
  (save-excursion
    (let ((max 10))
      (while (and (> max 0)
                  (sp-point-in-string-or-comment))
        (decf max)
        (sp-up-sexp)))
    (sp-up-sexp arg)
    (call-interactively 'eval-last-sexp)))

;; from https://github.com/syl20bnr/spacemacs/
(defun sam--open-in-external-app ()
  "Open current file in external application."
  (interactive)
  (let ((file-path (if (eq major-mode 'dired-mode)
                       (dired-get-file-for-visit)
                     (buffer-file-name))))
    (if file-path
        (shell-command (format "open \"%s\"" file-path))
      (message "No file associated to this buffer."))))


;; from magnars ;; from spacemacs
(defun sam--delete-current-buffer-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to delete this file? ")
        (delete-file filename t)
        (kill-buffer buffer)
        (message "File '%s' successfully removed" filename)))))

;;; Blog related functions
;; from https://blog.tohojo.dk/2015/10/integrating-hugo-into-emacs.html

(setq hugo-base-dir "~/blog/samuel-blog/"
      hugo-buffer "*hugo*")

(defun hugo-new-post ()
  "This function asks for the title of the new post, generates a
filename for it by lower-casing the title and replacing all
special characters with hyphens, then runs hugo new to create the
posting. Finally, the file is opened and the correct title is
inserted in place of the one Hugo generates from the file name."
  (interactive)
  (let* ((title (read-from-minibuffer "Title: "))
         (filename
          (concat "post/"
                  (read-from-minibuffer
                   "Filename: "
                   (replace-regexp-in-string
                    "-\\.md" ".md"
                    (concat (downcase (replace-regexp-in-string "[^a-z0-9]+" "-" title)) ".md")))))
         (path (concat hugo-base-dir "content/" filename)))
    (if (file-exists-p path)
        (message "File already exists!")
      (hugo-command "new" filename)
      (find-file path)
      (hugo-replace-key "title" title)
      (goto-char (point-max))
      (save-buffer))))

(defun hugo-command (&rest args)
  (let ((default-directory (expand-file-name hugo-base-dir)))
    (apply 'call-process "hugo" nil hugo-buffer t args)))

(defun hugo-replace-key (key val)
  (save-excursion
    (goto-char (point-min))
                                        ; quoted value
    (if (and (re-search-forward (concat key " = \"") nil t)
             (re-search-forward "[^\"]+" (line-end-position) t))
        (or (replace-match val) t) ; ensure we return t
                                        ; unquoted value
      (when (and (re-search-forward (concat key " = ") nil t)
                 (re-search-forward ".+" (line-end-position) t))
        (or (replace-match val) t)))))

(defun hugo-server (&optional arg)
  "This simply spawn the Hugo server process and attaches it to
the defined Hugo buffer – or kills it if it is already
running. The server is run with the --buildDrafts --watch -d dev
command line options, which causes draft posts to also be built,
turns on watch mode, and uses a separate directory for the
compiled files (so as not to interfere with publishing). If run
without a prefix argument, this function will also open a browser
pointing to the Hugo localhost server."
  (interactive "P")
  (let* ((default-directory (concat (expand-file-name hugo-base-dir) "/"))
         (proc (get-buffer-process hugo-buffer)))
    (if (and proc (process-live-p proc))
        (progn (interrupt-process proc)
               (message "Stopped Hugo server"))
      (start-process "hugo" hugo-buffer "hugo" "server" "--buildDrafts" "--watch" "-d" "dev")
      (message "Started Hugo server")
      (unless arg
        (browse-url "http://localhost:1313/")))))

(defun hugo-publish ()
  (interactive)
  (let* ((default-directory (concat (expand-file-name hugo-base-dir) "/")))
    (when (call-process "bash" nil hugo-buffer t  "./upload.sh")
      (message "Blog published"))))

(defun hugo-undraft ()
  (interactive)
  (when (and (hugo-replace-key "date" (iso-timestamp))
             (hugo-replace-key "draft" "false"))
    (save-buffer)
    (message "Removed draft status and updated timestamp")))

(defun iso-timestamp ()
  (concat (format-time-string "%Y-%m-%dT%T")
          ((lambda (x) (concat (substring x 0 3) ":" (substring x 3 5)))
           (format-time-string "%z"))))

;;;
;; a redefinition of lisp-indent-function to make it respect sexp that start with a keyword
;; (:keymap patate
;;          pamplemousse)
;; is the default behavior
;; (:keymap patate
;;  pamplemousse)
;; is the expected behavior
;; https://github.com/Fuco1/.emacs.d/blob/af82072196564fa57726bdbabf97f1d35c43b7f7/site-lisp/redef.el#L20-L94
;;;
(defun Fuco1/lisp-indent-function (indent-point state)
  "This function is the normal value of the variable `lisp-indent-function'.
The function `calculate-lisp-indent' calls this to determine
if the arguments of a Lisp function call should be indented specially.

INDENT-POINT is the position at which the line being indented begins.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.

If the current line is in a call to a Lisp function that has a non-nil
property `lisp-indent-function' (or the deprecated `lisp-indent-hook'),
it specifies how to indent.  The property value can be:

* `defun', meaning indent `defun'-style
  \(this is also the case if there is no property and the function
  has a name that begins with \"def\", and three or more arguments);

* an integer N, meaning indent the first N arguments specially
  (like ordinary function arguments), and then indent any further
  arguments like a body;

* a function to call that returns the indentation (or nil).
  `lisp-indent-function' calls this function with the same two arguments
  that it itself received.

This function returns either the indentation to use, or nil if the
Lisp function does not specify a special indentation."
  (let ((normal-indent (current-column))
        (orig-point (point)))
    (goto-char (1+ (elt state 1)))
    (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
    (cond
     ;; car of form doesn't seem to be a symbol, or is a keyword
     ((and (elt state 2)
           (or (not (looking-at "\\sw\\|\\s_"))
               (looking-at ":")))
      (if (not (> (save-excursion (forward-line 1) (point))
                  calculate-lisp-indent-last-sexp))
          (progn (goto-char calculate-lisp-indent-last-sexp)
                 (beginning-of-line)
                 (parse-partial-sexp (point)
                                     calculate-lisp-indent-last-sexp 0 t)))
      ;; Indent under the list or under the first sexp on the same
      ;; line as calculate-lisp-indent-last-sexp.  Note that first
      ;; thing on that line has to be complete sexp since we are
      ;; inside the innermost containing sexp.
      (backward-prefix-chars)
      (current-column))
     ((and (save-excursion
             (goto-char indent-point)
             (skip-syntax-forward " ")
             (not (looking-at ":")))
           (save-excursion
             (goto-char orig-point)
             (looking-at ":")))
      (save-excursion
        (goto-char (+ 2 (elt state 1)))
        (current-column)))
     (t
      (let ((function (buffer-substring (point)
                                        (progn (forward-sexp 1) (point))))
            method)
        (setq method (or (function-get (intern-soft function)
                                       'lisp-indent-function)
                         (get (intern-soft function) 'lisp-indent-hook)))
        (cond ((or (eq method 'defun)
                   (and (null method)
                        (> (length function) 3)
                        (string-match "\\`def" function)))
               (lisp-indent-defform state indent-point))
              ((integerp method)
               (lisp-indent-specform method state
                                     indent-point normal-indent))
              (method
               (funcall method indent-point state))))))))

(defun sam--edit-password ()
  (interactive)
  (find-file "~/Org/private.org")
  )

(defun sam--iterm-goto-filedir-or-home ()
  "Go to present working dir and focus iterm"
  (interactive)
  (do-applescript
   (concat
    " tell application \"iTerm2\"\n"
    "   tell the current session of current window\n"
    (format "     write text \"cd %s\" \n"
            ;; string escaping madness for applescript
            (replace-regexp-in-string "\\\\" "\\\\\\\\"
                                      (shell-quote-argument (or default-directory "~"))))
    "   end tell\n"
    " end tell\n"
    " do shell script \"open -a iTerm\"\n"
    ))
  )

(defun sam--iterm-focus ()
  (interactive)
  (do-applescript
   " do shell script \"open -a iTerm\"\n"))

(defun sam--calendar-focus ()
  (interactive)
  (do-applescript
   " do shell script \"open -a Calendar\"\n"
   )
  )

(defun sam--finder-focus ()
  (interactive)
  (do-applescript
   " do shell script \"open -a Finder\"\n"
   )
  )

(defun sam--finder-goto-filedir-or-home ()
  (interactive)
  (do-applescript
   (format " do shell script \"open -a Finder %s\"\n"
           (replace-regexp-in-string "\\\\" "\\\\\\\\"
                                     (shell-quote-argument (or default-directory "~"))))))

(defun sam--new-empty-buffer ()
  "Create a new buffer called untitled(<n>)"
  ;; from spacemacs/layers/+distribution/spacemacs-base/funcs.el
  (interactive)
  (let ((newbuf (generate-new-buffer-name "untitled")))
    (switch-to-buffer newbuf)))

(defun use-package-jump ()
  "Jump to an outer-level `use-package' definition in current buffer."
  (interactive)
  (let ((packages))
    (save-excursion
      (goto-char (point-max))
      (while (beginning-of-defun)
        (let ((line (buffer-substring (line-beginning-position) (line-end-position))))
          (when (string-match "^(use-package \\([^[:space:]\n]+\\)"
                              line)
            (push (cons (match-string-no-properties 1 line)
                        (point))
                  packages)))))
    (goto-char (cdr (assoc (ivy-completing-read "Package: " packages)
                           packages)))))

;; adapted from
;; http://emacs.stackexchange.com/questions/202/close-all-dired-buffers
(defun kill-diff-buffers ()
  (interactive)
  (mapc (lambda (buffer)
          (when (member (buffer-local-value 'major-mode buffer)
                        '(diff-mode magit-diff-mode magit-process-mode))
            (kill-buffer buffer)))
        (buffer-list)))

;; syntax highlight hugo src block
(font-lock-add-keywords
 'markdown-mode
 '(("src\\|{{< figure\\|caption\\|link\\|>}}" . font-lock-keyword-face)))


(defun sam--ivy-solarized ()
  "Return HEX code from solarized color map."
  (interactive)
  (ivy-read
   "Select hex from solarized color: "
   '(("brblack  " "#002b36")
     ("black    " "#073642")
     ("brgreen  " "#586e75")
     ("bryellow " "#657b83")
     ("brblue   " "#839496")
     ("brcyan   " "#93a1a1")
     ("white    " "#eee8d5")
     ("brwhite  " "#fdf6e3")
     ("yellow   " "#b58900")
     ("brred    " "#cb4b16")
     ("red      " "#dc322f")
     ("magenta  " "#d33682")
     ("brmagenta" "#6c71c4")
     ("blue     " "#268bd2")
     ("cyan     " "#2aa198")
     ("green    " "#859900"))
   :action '(1 ("o" (lambda (x)
                      (with-ivy-window
                        (insert (elt x 1))))))))



;;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
        ;; This would override `fill-column' if it's an integer.
        (emacs-lisp-docstring-fill-column t))
    (fill-paragraph nil region)))

(defun wtd ()
  "opens a new buffer with a list of TODO items populated by
  running ag 'TODO' in the current dir"
  (interactive)
  (counsel-ag "todo" default-directory))

;; this function is used to append multiple elements to the list 'ox-latex
(defun append-to-list (list-var elements)
  "Append ELEMENTS to the end of LIST-VAR. The return value is the new value of LIST-VAR."
  (unless (consp elements) (error "ELEMENTS must be a list"))
  (let ((list (symbol-value list-var)))
    (if list
        (setcdr (last list) elements)
      (set list-var elements)))
  (symbol-value list-var))

(defun sam--find-biblio ()
  "Open a pdf in the directory containing my bibliography"
  (interactive)
  (counsel-find-file "~/zotero_bib/"))


(defmacro if-looking-at-do-else (look-at does otherwise)
  `(if (looking-at ,look-at)
       (eval ,does)
     (eval ,otherwise)))

;;; lab notebook
(setq journal-base-dir "~/these/meta/journal/")

(defun journal-command (&rest args)
  (let ((default-directory (expand-file-name journal-base-dir)))
    (apply 'call-process "hugo" nil hugo-buffer t args)))

(defun journal-post ()
  (interactive)
  (let* ((filename
          (concat "post/"
                  (format-time-string "%Y-%m-%d" (current-time))
                  ".md"))
         (path (concat journal-base-dir "content/" filename)))
    (if (file-exists-p path)
        (find-file path)
      (journal-command "new" filename)
      (find-file path)
      (goto-char (point-min))
      (save-buffer))))


(defun search-journal ()
  (interactive)
  (counsel-ag nil "~/Org/journal/"))

(use-package s
  :commands all-sidenote-buffer
  :defines all-sidenote buffer
  :config
  (defun all-sidenote-buffer ()
    (interactive)
    (ivy-read
     "get a list of all sidenotes"
     (s-match-strings-all "sidenote \"[0-9]+\"" (buffer-string)))))

(defun delete-to-sentence-beg ()
  (interactive)
  (save-excursion
    (let ((end (point)))
      (backward-sentence)
      (delete-region (point) end))))

;; from http://endlessparentheses.com/ispell-and-abbrev-the-perfect-auto-correct.html
(defun sam--simple-get-word ()
  (car-safe (save-excursion (ispell-get-word nil))))

(defun modi/multi-pop-to-mark (orig-fun &rest args)
  "Call ORIG-FUN until the cursor moves.
Try the repeated popping up to 10 times."
  (let ((p (point)))
    (dotimes (i 10)
      (when (= p (point))
        (apply orig-fun args)))))

(advice-add 'pop-to-mark-command :around
            #'modi/multi-pop-to-mark)

(setq set-mark-command-repeat-pop t)

;; http://endlessparentheses.com/emacs-narrow-or-widen-dwim.html
(defun narrow-or-widen-dwim (p)
  "Widen if buffer is narrowed, narrow-dwim otherwise.
Dwim means: region, org-src-block, org-subtree, or
defun, whichever applies first. Narrowing to
org-src-block actually calls `org-edit-src-code'.

With prefix P, don't widen, just narrow even if buffer
is already narrowed."
  (interactive "P")
  (declare (interactive-only))
  (cond ((and (buffer-narrowed-p) (not p)) (widen))
        ((region-active-p)
         (narrow-to-region (region-beginning)
                           (region-end)))
        ((derived-mode-p 'org-mode)
         ;; `org-edit-src-code' is not a real narrowing
         ;; command. Remove this first conditional if
         ;; you don't want it.
         (cond ((ignore-errors (org-edit-src-code) t)
                (delete-other-windows))
               ((ignore-errors (org-narrow-to-block) t))
               (t (org-narrow-to-subtree))))
        ((derived-mode-p 'latex-mode)
         (LaTeX-narrow-to-environment))
        (t (narrow-to-defun))))

(defun buffer-to-new-frame ()
  "Open the current buffer in a new frame"
  (interactive)
  (let ((buf (buffer-name)))
    (delete-window)
    (switch-to-buffer-other-frame buf)))

(defun mark-line ()
  "Mark the whole line"
  (interactive)
  (move-beginning-of-line nil)
  (set-mark-command nil)
  (next-line)
  (setq deactivate-mark nil))

(defun ignore-error-wrapper (fn)
  "Funtion return new function that ignore errors.
   The function wraps a function with `ignore-errors' macro."
  (lexical-let ((fn fn))
    (lambda ()
      (interactive)
      (ignore-errors
        (funcall fn)))))

(defun next-line-end ()
  (interactive)
  (next-line)
  (end-of-line))

(defun prev-line-end ()
  (interactive)
  (previous-line)
  (end-of-line))

(defun delete-word-ap (arg)
  (interactive "P")
  (let* ((argp (and arg (= 4 (prefix-numeric-value arg))))
         (beg (beginning-of-thing (if argp 'symbol 'word)))
         (end (end-of-thing (if argp 'symbol 'word))))
    (save-excursion
      (delete-region beg end)
      (delete-char 1))))

;; from  http://endlessparentheses.com/kill-entire-line-with-prefix-argument.html
(defmacro bol-with-prefix (function)
  "Define a new function which calls FUNCTION.
Except it moves to beginning of line before calling FUNCTION when
called with a prefix argument. The FUNCTION still receives the
prefix argument."
  (let ((name (intern (format "sam:%s-BOL" function))))
    `(progn
       (defun ,name (p)
         ,(format
           "Call `%s', but move to BOL when called with a prefix argument."
           function)
         (interactive "P")
         (when p
           (forward-line 0))
         (call-interactively ',function))
       ',name)))

;; from  http://endlessparentheses.com/fill-and-unfill-paragraphs-with-a-single-key.html
(defun sam/fill-or-unfill ()
  "Like `fill-paragraph', but unfill if used twice."
  (interactive)
  (let ((fill-column
         (if (eq last-command 'sam/fill-or-unfill)
             (progn (setq this-command nil)
                    (point-max))
           fill-column)))
    (call-interactively #'fill-paragraph)))

(defadvice upcase-word (before upcase-word-advice activate)
  (unless (and (looking-back "\\b" (beginning-of-line))
               (not (derived-mode-p 'text-mode)))
    (backward-word)))

(defadvice downcase-word (before downcase-word-advice activate)
  (unless (and (looking-back "\\b" (beginning-of-line))
               (not (derived-mode-p 'text-mode)))
    (backward-word)))

(defadvice capitalize-word (before capitalize-word-advice activate)
  (unless (and (looking-back "\\b" (beginning-of-line))
               (not (derived-mode-p 'text-mode)))
    (backward-word)))
