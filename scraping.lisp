#|
 This file is a part of kanji-tree
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(defpackage #:kanji-tree-scraping
  (:nicknames #:org.shirakumo.radiance.kanji-tree.scraping)
  (:use #:cl))

(in-package #:org.shirakumo.radiance.kanji-tree.scraping)

(defvar *trim-chars* '(#\Space #\Return #\Linefeed #\Tab))

(defun extract-jisho-readings (thing texts)
  (let ((text (or (loop for text across texts
                        when (search (format NIL "【~a】" thing) text)
                        return text)
                  "】")))
    (split (string-trim *trim-chars* (subseq text (1+ (position #\】 text))))
           #\, :key (lambda (s) (string-trim *trim-chars* s)))))

(defun split (text c &key key)
  (let ((parts ())
        (s (make-string-output-stream)))
    (flet ((maybe-push ()
             (let ((s (funcall key (get-output-stream-string s))))
               (when (string/= "" s) (push s parts)))))
      (loop for char across text
            do (if (eql char c)
                   (maybe-push)
                   (write-char char s))
            finally (maybe-push))
      (nreverse parts))))

(defun jisho-kanji (kanji)
  (let* ((kanji (character kanji))
         (page (plump:parse (dex:get (quri:make-uri :scheme "http"
                                                    :host "jisho.org"
                                                    :path "/search/"
                                                    :query (quri:url-encode-params `(("keyword" . ,(format NIL "~a #kanji" kanji))))))))
         (data (lquery:$ page ".kanji")))
    (list :kanji kanji
          :level (lquery:$1 data ".kanji_stats .jlpt strong" (text))
          :rank (parse-integer (lquery:$1 data ".kanji_stats .frequency strong" (text)))
          :strokes (parse-integer (lquery:$1 data ".kanji-details__stroke_count strong" (text)))
          :components (coerce (lquery:$ data ".radicals" (aref 1) "a" (text) (each #'character)) 'list)
          :meanings (split (lquery:$1 data ".kanji-details__main-meanings" (text))
                           #\, :key (lambda (s) (string-trim *trim-chars* s)))
          :kunyomi (let ((kunyomi (lquery:$ data ".kun_yomi .kanji-details__main-readings-list a" (text)))
                         (texts (lquery:$ data ".compounds .columns" (aref 1) "li" (text))))
                     (loop for kun across kunyomi
                           for text = (extract-jisho-readings kun texts)
                           collect (cons kun text)))
          :onyomi (let ((onyomi (lquery:$ data ".on_yomi .kanji-details__main-readings-list a" (text)))
                        (texts (lquery:$ data ".compounds .columns" (aref 0) "li" (text))))
                    (loop for on across onyomi
                          for text = (extract-jisho-readings on texts)
                          collect (cons on text))))))

(defun jisho-word (word)
  (let* ((page (plump:parse (dex:get (quri:make-uri :scheme "http"
                                                    :host "jisho.org"
                                                    :path (format NIL "/word/~a" (quri:url-encode word))))))
         (data (lquery:$ page ".concept_light .meanings-wrapper" (children)))
         (meanings ())
         (forms ()))
    (loop with type = NIL
          for node across data
          for class = (plump:attribute node "class")
          do (cond ((equal "meaning-tags" class)
                    (setf type (cond ((string= "Noun" (plump:text node)) :meanings)
                                     ((string= "Other forms" (plump:text node)) :forms))))
                   ((equal "meaning-wrapper" class)
                    (case type
                      (:meanings (push (lquery:$1 node ".meaning-meaning" (text)) meanings))
                      (:forms (loop for form across (lquery:$ node ".meaning-meaning .break-unit" (text))
                                    do (push form forms)))))))
    (list :word word
          :forms (loop for form in (nreverse forms)
                       collect (subseq form 0 (position #\Space form)))
          :meanings (nreverse meanings))))
