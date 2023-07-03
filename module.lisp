(in-package #:rad-user)
(define-module #:kanji-tree
  (:nicknames #:org.shirakumo.radiance.kanji-tree)
  (:use #:cl #:radiance)
  (:shadow #:character)
  (:export
   #:ensure-kanji
   #:ensure-jukugo
   #:translatable
   #:translations
   #:kanji
   #:character
   #:index
   #:level
   #:rank
   #:components
   #:constitutes
   #:notes
   #:onyomi
   #:kunyomi
   #:jukugo
   #:radical-p
   #:radicals
   #:onyomi
   #:text
   #:kunyomi
   #:text
   #:jukugo
   #:kanji
   #:text
   #:translation
   #:language
   #:text
   #:define-kanji
   #:define-jukugo
   #:print-kanji))
