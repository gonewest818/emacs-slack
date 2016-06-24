;;; slack-util.el ---utility functions               -*- lexical-binding: t; -*-

;; Copyright (C) 2015  yuya.minami

;; Author: yuya.minami <yuya.minami@yuyaminami-no-MacBook-Pro.local>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'eieio)

(defun slack-seq-to-list (seq)
  (if (listp seq) seq (append seq nil)))

(defun slack-decode (seq)
  (cl-loop for e in (slack-seq-to-list seq)
           collect (if (stringp e)
                       (decode-coding-string e 'utf-8)
                     e)))

(defun slack-class-have-slot-p (class slot)
  (and (symbolp slot)
       (let* ((stripped (substring (symbol-name slot) 1))
              (replaced (replace-regexp-in-string "_" "-"
                                                  stripped))
              (symbolized (intern replaced)))
         (slot-exists-p class symbolized))))

(defun slack-collect-slots (class seq)
  (let ((plist (slack-seq-to-list seq)))
    (cl-loop for p in plist
             if (and (slack-class-have-slot-p class p)
                     (plist-member plist p))
             nconc (let ((value (plist-get plist p)))
                     (list p (if (stringp value)
                                 (decode-coding-string value 'utf-8)
                               (if (eq :json-false value)
                                   nil
                                 value)))))))

(eval-after-load "company"
  '(progn
     (defun company-slack-backend (command &optional arg &rest ignored)
       "Completion backend for slack chats.  It currently understands
@USER; adding #CHANNEL should be a simple matter of programming."
       (interactive (list 'interactive))
       (cl-case command
         (interactive (company-begin-backend 'company-slack-backend))
         (prefix (when (and (find major-mode '(slack-mode slack-edit-message-mode))
                            (looking-back "\\W@\\(\\w*\\)"))
                   (match-string 1)))
         (candidates (remove-if-not
                      (lambda (x)
                        (s-starts-with-p arg x))
                      (mapcar #'first (slack-user-names slack-current-team))))
         (meta (format "%s%s"
                       (slack-user-presence-to-string (slack-user-find-by-name arg slack-current-team))
                       arg))))

     (add-to-list 'company-backends 'company-slack-backend)))

(provide 'slack-util)
;;; slack-util.el ends here
