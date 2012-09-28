;;
;; XP ˆÚAì‹Æ—p‚ÌŽG‘½‚È‚à‚Ì
;; ‘S‚­®—‚µ‚Ä‚È‚¢
;;
;; •’i‚Í xl-repl ‚©‚ç‚±‚ñ‚È‚Ì‚ðŽÀs‚µ‚Ä‚é
;;
;;     user> (remove-xp) (load-xp t) (test-xp)

(in-package :user)

(defconstant *base-dir* (directory-namestring *load-pathname*))

(defparameter *xp-code-src* "xp-code.l")
(defparameter *xp-code-fasl* "xp-code.lc")
(defparameter *xp-test* "xp-test.l")


(defmacro with-output-to-error-log (&body body)
  `(let ((#1=#:buffer (get-buffer-create "*Test Errors*")))
     (setup-temp-buffer #1#)
     (with-output-to-buffer (#1# (buffer-size #1#))
       ,@body)))

(defun error-log-stream (&optional clear)
  (let ((buffer (get-buffer-create "*Test Errors*")))
    (setup-temp-buffer buffer)
    (when clear (erase-buffer buffer))
    (make-buffer-stream buffer (buffer-size buffer))))

(defun remove-xp ()
  (let* ((xp-pkg (find-package :xp))
         (installer (when xp-pkg
                      (find-symbol "install" xp-pkg))))
    (when xp-pkg
      (dolist (using (package-used-by-list xp-pkg))
        (funcall installer :remove t))
      (delete-package xp-pkg)
      :xp-pkg-removed)))

(defun load-xp (&optional compile)
  (when (find-package :xp)
    (remove-xp))
  (let ((src  (merge-pathnames *xp-code-src* *base-dir*))
        (fasl (merge-pathnames *xp-code-fasl* *base-dir*)))
    (when compile
      (compile-file src))
    (load (cond ((file-exist-p fasl) fasl)
                ((file-exist-p src)  src)
                (t (error 'file-not-found :pathname src))))))

(defun test-xp (&optional n)
  (unless (find-package :xp)
    (load-xp))
  (load (merge-pathnames *xp-test* *base-dir*))
  (with-open-stream (elog (error-log-stream t))
    (let ((debug-info-def
            (get (find-symbol "debug-info" :xp) 'si:structure-definition))
          (failure-def
            (get (find-symbol "failure" :user)  'si:structure-definition)))
      (with-interval-message (300)
        (handler-bind ((condition
                        (lambda (x)
                          (let ((def (si:*structure-definition x)))
                            (cond ((eq def debug-info-def)
                                    (let ((msg (split-string (lisp:princ-to-string x)
                                                             #\LFD)))
                                      (lisp:format elog "~&Debug> ~A~%~{~7T ~A~%~}"
                                                   (first msg) (rest msg))))
                                  ((eq def failure-def)
                                    (lisp:format elog "~&Failure: ~A~%" x)))))))
          (handler-case
              (funcall (find-symbol "do-tests" :user))
            (error ()
              (loop
                (handler-case
                    (return (funcall (find-symbol "more" :user)))
                  (error (err)
                    (lisp:format elog "~&ERROR: ~A" err)
                    (message "Error: ~A" err)))
                (do-events)))))))))


(defun *load-xp (&optional (run-test t))
  (load (merge-pathnames *xp-code-fasl* *base-dir*))
  (funcall (find-symbol "install" :xp))
  (when run-test
    (load (merge-pathnames *xp-test* *base-dir*))
    (with-interval-message (400)
      (with-open-stream (error-log (error-log-stream))
        (let ((debug-info-def
                (get (find-symbol "debug-info" :xp) 'si:structure-definition))
              (failure-def
                (get (find-symbol "failure" :user) 'si:structure-definition)))
          (handler-bind ((condition
                          (lambda (x)
                            (let ((def (si:*structure-definition x)))
                              (cond ((eq def debug-info-def)
                                      (let ((msg (split-string (lisp:princ-to-string x) #\LFD)))
                                        (lisp:format error-log "~&Debug> ~A~%~{~7T ~A~%~}"
                                                     (first msg) (rest msg))))
                                    ((eq def failure-def)
                                      (lisp:format error-log "~&Failure: ~A~%" x)))))))
            (handler-case
                (funcall (find-symbol "do-tests" :user))
              (error ()
                (loop
                  (do-events)
                  (handler-case
                      (progn
                        (funcall (find-symbol "more" :user))
                        (return (values)))
                    (error (err)
                      (lisp:format error-log "~&ERROR: ~A" err)
                      (message "Error: ~A" err))))))))))))

