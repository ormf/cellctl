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
   #:val
   #:set-ref
   #:dependents
;;   #:map-fn
;;   #:rmap-fn
   #:with-model-slots))
