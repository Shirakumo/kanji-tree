#|
 This file is a part of kanji-tree
 (c) 2017 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(asdf:defsystem kanji-tree
  :defsystem-depends-on (:radiance)
  :class "radiance:virtual-module"
  :version "1.0.0"
  :license "Artistic"
  :author "Nicolas Hafner <shinmera@tymoon.eu>"
  :maintainer "Nicolas Hafner <shinmera@tymoon.eu>"
  :description ""
  :homepage "https://github.com/Shirakumo/kanji-tree"
  :serial T
  :components ((:file "module")
               (:file "toolkit")
               (:file "objects")
               (:file "data"))
  :depends-on (:r-clip
               :trivial-indent
               :cl-unicode))
