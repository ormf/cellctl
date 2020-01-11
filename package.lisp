;;;; package.lisp

(defpackage #:cellctl
  (:use #:cl)
  (:export
   #:model-slot
   #:model-array
   #:set-cell
   #:ref-set-cell
   #:value-cell
   #:map-fn
   #:rmap-fn
   #:ref-set-fn
   #:val
   #:set-ref
   #:dependents
   #:dependents
;;   #:map-fn
;;   #:rmap-fn
   #:with-model-slots
   #:class-redefine-model-slots-setf
   #:model-slot-register-setf-method
   #:class-get-model-slot-readers
   #:class-get-model-slot-reader-defs))
