;;;; package.lisp

(defpackage #:cellctl
  (:use #:cl)
  (:export
   #:model-slot
   #:model-array
   #:set-cell
   #:set-cell-hook
   #:ref-set-cell
   #:value-cell
   #:map-fn
   #:rmap-fn
   #:ref-set-hook
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
   #:class-redefine-model-slot-accessors))
