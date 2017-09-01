#|
 This file is a part of kanji-tree
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.radiance.kanji-tree)

(define-kanji 一
  :translations (en "one" "one radical")
  :onyomi
  (イチ)
  (イシ)
  :kunyomi
  (ひと)
  (ひと/つ (en "one" "for one thing" "only")))

(define-kanji 了
  :translations (en "total")
  :onyomi
  (リョウ))

(define-kanji (子 一 了)
  :translations (en "child")
  :onyomi
  (シ)
  :kunyomi
  (こ (en "child")))
