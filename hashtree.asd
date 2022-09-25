(asdf:defsystem #:hashtree
  :description "This is attempt to build nested data structures using hash table"
  :author "Jacek Podkanski <ruby.object@googlemail.com>"
  :license  "Unlicence"
  :version "0.0.1"
  :depends-on (#:alexandria)
  :serial t
  :components ((:file "package")
               (:file "hashtree")))
