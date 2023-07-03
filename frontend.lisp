(in-package #:org.shirakumo.radiance.kanji-tree)

(lquery:define-lquery-function kanji (node kanji)
  (let ((kanji (etypecase kanji
                 (character kanji)
                 (kanji (character kanji)))))
    (lquery:$ node
      (text (string kanji))
      (attr :href (uri-to-url (make-uri :domains '("kanji-tree")
                                        :path (format NIL "kanji/~a" kanji))
                              :representation :external))))
  node)

(defvar *links* ())

(defclass linker ()
  ((name :initarg :name :accessor name)
   (url :initarg :url :accessor url)
   (icon :initarg :icon :accessor icon)
   (type :initarg :type :accessor type))
  (:default-initargs
   :name (error "NAME required")
   :url (error "URL required.")
   :icon ""
   :type :kanji))

(defmethod initialize-instance :after ((linker linker) &key)
  (setf *links* (remove-if (lambda (a)
                             (and (string-equal (name a) (name linker))
                                  (eql (type a) (type linker))))
                           *links*))
  (push linker *links*))

(defmacro define-linker (name url &key (icon "") (type :kanji))
  `(make-instance
    'linker
    :name ,(string-capitalize name)
    :url ,url
    :icon ,icon
    :type ,type))

(define-linker jisho
  "http://jisho.org/search/~a%20%23kanji"
  :icon "http://assets.jisho.org/assets/favicon-062c4a0240e1e6d72c38aa524742c2d558ee6234497d91dd6b75a182ea823d65.ico")

(define-linker jisho
  "http://jisho.org/search/~a"
  :icon "http://assets.jisho.org/assets/favicon-062c4a0240e1e6d72c38aa524742c2d558ee6234497d91dd6b75a182ea823d65.ico"
  :type :word)

(define-linker jigen
  "http://jigen.net/data/~a?type2=1&rs=100"
  :icon "http://jigen.net/favicon.ico")

(define-linker saiga-jp
  "http://www.saiga-jp.com/cgi-bin/dic.cgi?m=search&j=~a"
  :icon "http://www.saiga-jp.com/favicon.ico")

(define-linker etymology
  "http://www.chineseetymology.org/CharacterEtymology.aspx?submitButton1=Etymology&characterInput=~a")

(define-page kanji "kanji-tree/kanji/([^/]+)" (:clip "detail.ctml" :uri-groups (kanji))
  (r-clip:process T :kanji (ensure-kanji kanji)
                    :links *links*))
