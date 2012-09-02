;;; theme-helper.el --- Create color themes faster.

;; this file is not part of Emacs

;; Copyright (C) 2012 Le Wang
;; Author: Le Wang
;; Maintainer: Le Wang
;; Description: Create color themes faster.
;; Author: Le Wang
;; Maintainer: Le Wang

;; Created: Sun Sep  2 21:21:40 2012 (+0800)
;; Version: 0.1
;; Last-Updated: Sun Sep  2 21:53:32 2012 (+0800)
;;           By: Le Wang
;;     Update #: 18 
;; URL: 
;; Keywords: 
;; Compatibility: 

;;; Installation: 

;;     (require 'theme-helper-mode)
;;     
;;     ;;; from theme definition file <M-x> "theme-helper-mode"
       
;;; Commentary: 

;; Emacs 24 has arrived with builtin color theme support.
;;
;; This library helps you to make themes faster by quickly seeing what your
;; changes look like.
;;
;; Features:
;;
;;   - "C-c C-c" to quickly re-eval buffer and reload theme and re-font-lock.
;;   - Font-lock faces customized in current theme.
;;   - Font-lock color names and color hex values.
;;     + see: http://www.emacswiki.org/emacs/HexColour

;;; Todo: 

;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Code: 

(eval-when-compile (require 'cl))

(defun theme-helper-hexcolor-luminance (color)
  "Calculate the luminance of a color string (e.g. \"#ffaa00\", \"blue\").
  This is 0.3 red + 0.59 green + 0.11 blue and always between 0 and 255."
  (let* ((values (x-color-values color))
         (r (car values))
         (g (cadr values))
         (b (caddr values)))
    (floor (+ (* .3 r) (* .59 g) (* .11 b)) 256)))

(defun theme-helper-hexcolor-add-to-font-lock ()
  "font-lock color names and hex values"
  (interactive)
  (font-lock-add-keywords nil
                          `((,(concat "#[0-9a-fA-F]\\{3\\}[0-9a-fA-F]\\{3\\}?\\|"
                                      (regexp-opt (x-defined-colors) 'words))
                             (0 (let ((colour (match-string-no-properties 0)))
                                  (put-text-property
                                   (match-beginning 0) (match-end 0)
                                   'face `((:foreground ,(if (> 128.0 (theme-helper-hexcolor-luminance colour))
                                                             "white" "black"))
                                           (:background ,colour))))))))
  (font-lock-fontify-buffer))

(defun theme-helper-get-faces (theme)
  (loop with result
        for setting in (plist-get (symbol-plist theme) 'theme-settings)
        do (when (eq (car setting) 'theme-face)
             ;; Have we assumed theme only defines color with (t (...)) style?
             (push (cons (cadr setting) (cdaar (last setting))) result))
        finally return result))

(defun theme-helper-get-keywords (&optional theme)
  (setq theme (or theme (car custom-enabled-themes)))
  (mapcar (lambda (face-def)
            (destructuring-bind (face def) face-def
              (list (concat "\\_<"
                            (symbol-name face)
                            "\\_>")
                    0
                    (cons 'quote (list def))
                    t)))
          (theme-helper-get-faces theme)))

;;; not sure why can't toggle minor-mode off
(define-minor-mode theme-helper-mode
  "Enable font-locking of all faces defined in current theme.

This us useful for theme experimentation."
  :lighter "theme-helper"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-c") 'theme-helper-refresh)
            map)
  (let ((kwlist (theme-helper-get-keywords)))
    (if fic-mode
        (progn
          (font-lock-add-keywords nil kwlist 'append)
          (theme-helper-hexcolor-add-to-font-lock))
      (normal-mode))))

(defun theme-helper-refresh ()
  "re-evaluate current buffer and re-font-lock according to current theme."
  (interactive)
  ;; eval buffer required incase buffer defines structure of theme, but not
  ;; actual theme.  e.g. solarized-definitions.el
  (eval-buffer)
  (load-theme (car custom-enabled-themes) 'no-confirm)
  (normal-mode)
  (theme-helper-mode 1))

(provide 'theme-helper-mode)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; theme-helper.el ends here
