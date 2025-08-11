(asdf:defsystem kanji-tree-scraping
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description ""
  :homepage "https://shirakumo.org/project/kanji-tree"
  :serial T
  :components ((:file "scraping"))
  :depends-on (:dexador
               :lquery
               :cl-ppcre
               :kanji-tree))
