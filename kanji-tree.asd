(asdf:defsystem kanji-tree
  :defsystem-depends-on (:radiance)
  :class "radiance:virtual-module"
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description ""
  :homepage "https://shirakumo.org/project/kanji-tree"
  :serial T
  :components ((:file "module")
               (:file "toolkit")
               (:file "objects"))
  :depends-on (:r-clip
               :trivial-indent
               :cl-unicode))
