(in-package #:org.shirakumo.radiance.kanji-tree)

(defun gather-kargs (args)
  (let ((plist ()))
    (loop with key = NIL
          for item in args
          do (if (keywordp item)
                 (setf key item)
                 (push item (getf plist key))))
    (loop for (k v) on plist by #'cddr
          do (setf (getf plist k) (nreverse v)))
    plist))

(defun extract-kanji (text)
  (loop for char across text
        for block = (nth-value 1 (cl-unicode:code-block char))
        when (eql block 'CL-UNICODE-NAMES::CJKUNIFIEDIDEOGRAPHS)
        collect char))
