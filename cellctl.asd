;;;; cellctl.asd

(asdf:defsystem #:cellctl
  :description "Describe cellctl here"
  :author "Your Name <your.name@example.com>"
  :license  "Specify license here"
  :version "0.0.1"
  :serial t
  :depends-on (:closer-mop)
  :components ((:file "package")
               (:file "cellctl")))
