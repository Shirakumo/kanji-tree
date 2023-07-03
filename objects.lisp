(in-package #:org.shirakumo.radiance.kanji-tree)

(defvar *kanji* (make-hash-table :test 'eql))
(defvar *jukugo* (make-hash-table :test 'equal))

(deftype character () 'cl:character)

(defun ensure-kanji (kanji-ish &optional (errorp T))
  (etypecase kanji-ish
    (kanji
     kanji-ish)
    (character
     (or (gethash kanji-ish *kanji*)
         (when errorp (error "No kanji defined for ~c." kanji-ish))))
    (string
     (ensure-kanji (char kanji-ish 0) errorp))
    (symbol
     (ensure-kanji (string kanji-ish) errorp))))

(defun list-kanji ()
  (loop for v being the hash-values of *kanji*
        collect v))

(defun ensure-jukugo (jukugo-ish &optional (errorp T))
  (etypecase jukugo-ish
    (jukugo
     jukugo-ish)
    (string
     (or (gethash jukugo-ish *jukugo*)
         (when errorp (error "No jukugo defined for ~a." jukugo-ish))))
    (symbol
     (ensure-jukugo (string jukugo-ish)))))

(defclass translatable ()
  ((translations :initarg :translations :accessor translations))
  (:default-initargs :translations ()))

(defmethod initialize-instance :before ((translatable translatable) &key translations)
  (dolist (translation translations)
    (check-type translation translation)))

(defclass kanji (translatable)
  ((character :initarg :character :accessor character)
   (index :initarg :index :accessor index)
   (level :initarg :level :accessor level)
   (rank :initarg :rank :accessor rank)
   (components :initarg :components :accessor components)
   (constitutes :initform () :accessor constitutes)
   (notes :initarg :notes :accessor notes)
   (onyomi :initarg :onyomi :accessor onyomi)
   (kunyomi :initarg :kunyomi :accessor kunyomi)
   (jukugo :initform () :accessor jukugo))
  (:default-initargs
   :character (error "CHARACTER required")
   :level NIL
   :rank NIL
   :components ()
   :index NIL
   :notes "None."
   :onyomi ()
   :kunyomi ()))

(defmethod initialize-instance :around ((kanji kanji) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :components) (remove-duplicates (mapcar #'ensure-kanji (getf args :components))))
    (setf (getf args :character) (cl:character (getf args :character)))
    (setf (getf args :text) (string (getf args :text)))
    (apply #'call-next-method kanji args)))

(defmethod initialize-instance :before ((kanji kanji) &key character components)
  (when (gethash character *kanji*)
    (warn "A kanji instance for ~c already exists." character))
  (dolist (component components)
    (ensure-kanji component)))

(defmethod initialize-instance :after ((kanji kanji) &key character components)
  (setf (gethash character *kanji*) kanji)
  (dolist (component components)
    (pushnew kanji (constitutes (ensure-kanji component)))))

(defmethod print-object ((kanji kanji) stream)
  (print-unreadable-object (kanji stream :type T)
    (format stream "~c" (character kanji))))

(defmethod (setf components) :around (new (kanji kanji))
  (let* ((new (sort (remove-duplicates (mapcar #'ensure-kanji new))
                    #'< :key (lambda (k) (char-code (character k)))))
         (rem (set-difference (components kanji) new))
         (add (set-difference new (components kanji))))
    (call-next-method new kanji)
    (dolist (old rem)
      (setf (constitutes old) (remove kanji (constitutes old))))
    (dolist (new add)
      (push kanji (constitutes new)))
    new))

(defmethod (setf constitutes) :around (new (kanji kanji))
  (let* ((new (sort (remove-duplicates (mapcar #'ensure-kanji new))
                    #'< :key (lambda (k) (char-code (character k)))))
         (rem (set-difference (constitutes kanji) new))
         (add (set-difference new (constitutes kanji))))
    (call-next-method new kanji)
    (dolist (old rem)
      (setf (components old) (remove kanji (components old))))
    (dolist (new add)
      (push kanji (components new)))
    new))

(defmethod radical-p ((kanji kanji))
  (null (components kanji)))

(defmethod radicals ((kanji kanji))
  (if (radical-p kanji)
      (list kanji)
      (let ((radicals ()))
        (dolist (component (components kanji))
          (dolist (radical (radicals component))
            (pushnew radical radicals)))
        (sort radicals
              #'< :key (lambda (k) (char-code (character k)))))))

(defclass onyomi (translatable)
  ((text :initarg :text :accessor text))
  (:default-initargs
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((onyomi onyomi) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :text) (string (getf args :text)))
    (apply #'call-next-method onyomi args)))

(defmethod print-object ((onyomi onyomi) stream)
  (print-unreadable-object (onyomi stream :type T)
    (format stream "~a" (text onyomi))))

(defclass kunyomi (translatable)
  ((text :initarg :text :accessor text))
  (:default-initargs
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((kunyomi kunyomi) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :text) (string (getf args :text)))
    (apply #'call-next-method kunyomi args)))

(defmethod print-object ((kunyomi kunyomi) stream)
  (print-unreadable-object (kunyomi stream :type T)
    (format stream "~a" (text kunyomi))))

(defclass jukugo (translatable)
  ((kanji :initarg :kanji :accessor kanji)
   (text :initarg :text :accessor text))
  (:default-initargs
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((jukugo jukugo) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :text) (string (getf args :text)))
    (setf (getf args :kanji) (loop for kspec in (or (getf args :kanji) (extract-kanji (getf args :text)))
                                   for kanji = (ensure-kanji kspec NIL)
                                   if kanji collect kanji
                                   else do (warn "No kanji for ~a defined." kspec)))
    (apply #'call-next-method jukugo args)))

(defmethod initialize-instance :after ((jukugo jukugo) &key text)
  (setf (gethash text *jukugo*) jukugo)
  (dolist (kanji (kanji jukugo))
    (pushnew jukugo (jukugo kanji))))

(defmethod print-object ((jukugo jukugo) stream)
  (print-unreadable-object (jukugo stream :type T)
    (format stream "~a" (text jukugo))))

(defclass translation ()
  ((language :initarg :language :accessor language)
   (text :initarg :text :accessor text))
  (:default-initargs
   :language (error "LANGUAGE required.")
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((translation translation) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :language) (string-downcase (getf args :language)))
    (apply #'call-next-method translation args)))

(defmethod print-object ((translation translation) stream)
  (print-unreadable-object (translation stream :type T)
    (format stream "~a" (language translation))))


(defun expand-translations (translations)
  (loop for (lang . text) in translations
        collect `(make-instance 'translation
                                :language ',lang
                                :text ',text)))

(defmacro define-kanji (char &body args)
  (let ((object (gensym "OBJECT")))
    (destructuring-bind (character &rest components) (if (listp char) char (list char))
      (destructuring-bind (&key level rank translations onyomi kunyomi notes) (gather-kargs args)
        `(let ((,object (or (ensure-kanji ',character NIL)
                            (make-instance 'kanji :character ',character))))
           (setf (level ,object) ',(first level))
           (setf (rank ,object) ',(first rank))
           (setf (components ,object) ',components)
           (setf (notes ,object) ,(first notes))
           (setf (translations ,object) (list ,@(expand-translations translations)))
           (setf (onyomi ,object)
                 (list ,@(loop for on in onyomi
                               collect (destructuring-bind (text &rest translations) on
                                         `(make-instance 'onyomi
                                                         :text ',text
                                                         :translations (list ,@(expand-translations translations)))))))
           (setf (kunyomi ,object)
                 (list ,@(loop for kun in kunyomi
                               collect (destructuring-bind (text &rest translations) kun
                                         `(make-instance 'kunyomi
                                                         :text ',text
                                                         :translations (list ,@(expand-translations translations))))))))))))

(trivial-indent:define-indentation define-kanji (6 &body))

(defmacro define-jukugo (text &body translations)
  (let ((object (gensym "OBJECT")))
    `(let ((,object (or (ensure-jukugo ',text NIL)
                        (make-instance 'jukugo :text ',text))))
       (setf (translations ,object) (list ,@(expand-translations translations))))))

(defun print-translation (translation)
  (format NIL "(~a~{ ~s~})"
          (language translation)
          (text translation)))

(defun print-kanji (kanji)
  (let ((kanji (ensure-kanji kanji)))
    (format NIL "~
\(define-kanji (~a~{ ~a~})
  :level ~s
  :rank ~s
  :translations ~{~a~}
  :notes ~s
  :onyomi~{
  (~a~{ ~a~^~%    ~})~}
  :kunyomi~{
  (~a~{ ~a~^~%    ~})~})"
            (character kanji)
            (mapcar #'character (components kanji))
            (level kanji)
            (rank kanji)
            (mapcar #'print-translation (translations kanji))
            (notes kanji)
            (loop for on in (onyomi kanji)
                  collect (text on) collect (mapcar #'print-translation (translations on)))
            (loop for kun in (kunyomi kanji)
                  collect (text kun) collect (mapcar #'print-translation (translations kun))))))
