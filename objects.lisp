#|
 This file is a part of kanji-tree
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.radiance.kanji-tree)

(defvar *kanji* (make-hash-table :test 'eql))
(defvar *kanji-sequence* (make-array 0 :adjustable T :fill-pointer T))

(deftype character () 'cl:character)

(defun ensure-kanji (kanji-ish)
  (etypecase kanji-ish
    (kanji
     kanji-ish)
    (character
     (or (gethash kanji-ish *kanji*)
         (error "No kanji defined for ~c." kanji-ish)))
    (string
     (ensure-kanji (char kanji-ish 0)))
    (integer
     (or (when (<= 0 kanji-ish (1- (length *kanji-sequence*)))
           (aref *kanji-sequence* kanji-ish))
         (error "No kanji defined for index ~d." kanji-ish)))))

(defclass translatable ()
  ((translations :initform () :accessor translations)))

(defmethod (setf translations) :before (translations (translatable translatable))
  (dolist (translation translations)
    (unless (eql translatable (object translation))
      (error "~a is not a translation for ~a." translation translatable))))

(defclass kanji (translatable)
  ((character :initarg :character :accessor character)
   (index :initarg :index :accessor index)
   (components :initarg :components :accessor components)
   (constitutes :initform () :accessor constitutes)
   (notes :initarg :notes :accessor notes)
   (onyomi :initform () :accessor onyomi)
   (kunyomi :initform () :accessor kunyomi)
   (jukugo :initform () :accessor jukugo))
  (:default-initargs
   :character (error "CHARACTER required")
   :components (error "COMPONENTS required")
   :index (1+ (length *kanji-sequence*))
   :notes "None."))

(defmethod initialize-instance :around ((kanji kanji) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :components) (mapcar #'ensure-kanji (getf args :components)))
    (apply #'call-next-method kanji args)))

(defmethod initialize-instance :before ((kanji kanji) &key character index components)
  (when (gethash character *kanji*)
    (error "A kanji instance for ~c already exists." character))
  (when (and (< index (length *kanji-sequence*))
             (aref *kanji-sequence* index))
    (error "A kanji with the index ~c already exists." index))
  (dolist (component components)
    (ensure-kanji component)))

(defmethod initialize-instance :after ((kanji kanji) &key character index components)
  (setf (gethash character *kanji*) kanji)
  (when (<= (length *kanji-sequence*) index)
    (adjust-array *kanji-sequence* (1+ index) :fill-pointer (1+ index)))
  (setf (aref *kanji-sequence* index) kanji)
  (dolist (component components)
    (pushnew kanji (constitutes (ensure-kanji component)))))

(defmethod print-object ((kanji kanji) stream)
  (print-unreadable-object (kanji stream)
    (format stream "~c" (character kanji))))

(defmethod (setf components) :around (new (kanji kanji))
  (let ((new (mapcar #'ensure-kanji new))
        (rem (set-difference (components kanji) new))
        (add (set-difference new (components kanji))))
    (call-next-method new kanji)
    (dolist (old rem)
      (setf (constitutes old) (remove kanji (constitutes old))))
    (dolist (new add)
      (push kanji (constitutes new)))
    new))

(defmethod (setf constitutes) :around (new (kanji kanji))
  (let ((new (mapcar #'ensure-kanji new))
        (rem (set-difference (constitutes kanji) new))
        (add (set-difference new (constitutes kanji))))
    (call-next-method new kanji)
    (dolist (old rem)
      (setf (components old) (remove kanji (components old))))
    (dolist (new add)
      (push kanji (components new)))
    new))

(defmethod (setf onyomi) :before (onyomi (kanji kanji))
  (dolist (on onyomi)
    (unless (eql kanji (kanji on))
      (error "~a is not an onyomi for ~a." on kanji))))

(defmethod (setf kunyomi) :before (kunyomi (kanji kanji))
  (dolist (kun kunyomi)
    (unless (eql kanji (kanji kun))
      (error "~a is not an kunyomi for ~a." kun kanji))))

(defmethod (setf jukugo) :before (jukugo (kanji kanji))
  (dolist (ju jukugo)
    (unless (find kanji (kanji ju))
      (error "~a is not an jukugo for ~a." ju kanji))))

(defclass onyomi (translatable)
  ((kanji :initarg :kanji :accessor kanji)
   (text :initarg :text :accessor text))
  (:default-initargs
   :kanji (error "KANJI required.")
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((onyomi onyomi) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :kanji) (ensure-kanji (getf args :kanji)))
    (apply #'call-next-method onyomi args)))

(defmethod initialize-instance :before ((onyomi onyomi) &key kanji text)
  (when (find text (onyomi kanji) :key #'text :test #'string=)
    (error "An onyomi for ~s already exists on ~a." text kanji)))

(defmethod initialize-instance :after ((onyomi onyomi) &key kanji)
  (push onyomi (onyomi kanji)))

(defmethod print-object ((onyomi onyomi) stream)
  (print-unreadable-object (onyomi stream)
    (format stream "~c ~a" (character (kanji onyomi)) (text onyomi))))

(defmethod (setf kanji) :around (new (onyomi onyomi))
  (let ((new (ensure-kanji new))
        (old (kanji onyomi)))
    (call-next-method new onyomi)
    (setf (onyomi old) (remove onyomi (onyomi old)))
    (push onyomi (onyomi new))
    new))

(defclass kunyomi (translatable)
  ((kanji :initarg :kanji :accessor kanji)
   (text :initarg :text :accessor text))
  (:default-initargs
   :kanji (error "KANJI required.")
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((kunyomi kunyomi) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :kanji) (ensure-kanji (getf args :kanji)))
    (apply #'call-next-method kunyomi args)))

(defmethod initialize-instance :before ((kunyomi kunyomi) &key kanji text)
  (when (find text (kunyomi kanji) :key #'text :test #'string=)
    (error "A kunyomi for ~s already exists on ~a." text kanji)))

(defmethod initialize-instance :after ((kunyomi kunyomi) &key kanji)
  (push kunyomi (kunyomi kanji)))

(defmethod print-object ((kunyomi kunyomi) stream)
  (print-unreadable-object (kunyomi stream)
    (format stream "~c ~a" (character (kanji kunyomi)) (text kunyomi))))

(defmethod (setf kanji) :around (new (kunyomi kunyomi))
  (let ((new (ensure-kanji new))
        (old (kanji kunyomi)))
    (call-next-method new kunyomi)
    (setf (kunyomi old) (remove kunyomi (kunyomi old)))
    (push kunyomi (kunyomi new))
    new))

(defclass jukugo (translatable)
  ((kanji :initarg :kanji :accessor kanji)
   (text :initarg :text :accessor text))
  (:default-initargs
   :kanji (error "KANJI required.")
   :text (error "TEXT required.")))

(defmethod initialize-instance :around ((jukugo jukugo) &rest initargs)
  (let ((args (copy-list initargs)))
    (setf (getf args :kanji) (mapcar #'ensure-kanji (getf args :kanji)))
    (apply #'call-next-method jukugo args)))

(defmethod initialize-instance :before ((jukugo jukugo) &key kanji text)
  (dolist (k kanji)
    (when (find text (jukugo k) :key #'text :test #'string=)
      (error "A jukugo for ~s already exists on ~a." text k))))

(defmethod initialize-instance :after ((jukugo jukugo) &key kanji)
  (push jukugo (jukugo kanji)))

(defmethod print-object ((jukugo jukugo) stream)
  (print-unreadable-object (jukugo stream)
    (format stream "~a" (text jukugo))))

(defmethod (setf kanji) :around (new (jukugo jukugo))
  (let ((new (mapcar #'ensure-kanji new))
        (rem (set-difference (kanji jukugo) new))
        (add (set-difference new (kanji jukugo))))
    (call-next-method new jukugo)
    (dolist (old rem)
      (setf (jukugo old) (remove jukugo (jukugo old))))
    (dolist (new add)
      (push jukugo (jukugo new)))
    new))

(defclass translation ()
  ((object :initarg :object :accessor object)
   (language :initarg :language :accessor language)
   (text :initarg :text :accessor text))
  (:default-initargs
   :object (error "KANJI required.")
   :language (error "LANGUAGE required.")
   :text (error "TEXT required.")))

(defmethod initialize-instance :before ((translation translation) &key object language)
  (check-type object translatable)
  (when (find language (translations object) :key #'language :test #'string=)
    (error "A translation for ~s already exists on ~a." language object)))

(defmethod initialize-instance :after ((translation translation) &key object)
  (push translation (translations object)))

(defmethod print-object ((translation translation) stream)
  (print-unreadable-object (translation stream)
    (format stream "~a ~a" (object translation) (language translation))))

(defmethod (setf object) :around ((new translatable) (translation translation))
  (let ((old (object translation)))
    (call-next-method new translation)
    (setf (translations old) (remove translation (translations old)))
    (push translation (translations new))
    new))
