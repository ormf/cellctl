;;;; cellctl.lisp

;;; 
;;; cellctl.lisp
;;;
;;; **********************************************************************
;;; Copyright (c) 2019 Orm Finnendahl <orm.finnendahl@selma.hfmdk-frankfurt.de>
;;;
;;; Revision history: See git repository.
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the Gnu Public License, version 2 or
;;; later. See https://www.gnu.org/licenses/gpl-2.0.html for the text
;;; of this agreement.
;;; 
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;; GNU General Public License for more details.
;;;
;;; **********************************************************************

(in-package #:cellctl)

;;; cellctl establishes one to many relationships between model-slots
;;; and dependent value-cells. To set a value in a model-slot, use
;;; set-cell.



(defclass model-slot ()
  ((val :initform 0 :initarg :val :accessor val)
   (dependents :initform nil :accessor dependents)))

(defmethod (setf val) (val (instance model-slot))
  (setf (slot-value instance 'val) val)
  (map nil #'(lambda (cell) (ref-set-cell cell val))
       (dependents instance))
  val)

(defmethod print-object ((obj model-slot) out)
  (print-unreadable-object (obj out :type t)
    (format out "~s" (val obj))))

(defclass model-array (model-slot)
  ((a-ref :initform nil :initarg :a-ref :accessor a-ref)
   (arr :initform nil :initarg :arr :accessor arr)))

(defmethod (setf val) (val (instance model-array))
    (setf (slot-value instance 'val) val)
  (with-slots (arr a-ref dependents) instance
    (setf (apply #'aref arr a-ref) val)
    (map nil #'(lambda (cell) (ref-set-cell cell val))
         dependents))
  val)

(defmethod set-cell ((instance model-array) value &key src)
  (prog1
      (setf (slot-value instance 'val) value)
  (with-slots (arr a-ref dependents) instance
    (setf (apply #'aref arr a-ref) value)
    (map nil #'(lambda (cell) (unless (eql cell src) (ref-set-cell cell value)))
         (dependents instance)))))

(defmethod print-object ((obj model-array) out)
  (print-unreadable-object (obj out :type nil)
    (format out "~s" (val obj))))

;;; (defparameter *test-model* (make-instance 'model-array))

;;; (setf (val *test-model*) 10)

(defgeneric set-cell (instance value &key src)
  (:method ((instance model-slot) value &key src)
;;    (break "set-cell ~a ~a ~a" instance value src)
    (prog1
        (setf (slot-value instance 'val) value)
      (map nil #'(lambda (cell) (unless (eql cell src) (ref-set-cell cell value)))
           (dependents instance))))
  (:documentation "set the val slot of the model-slot and its
  dependents. If triggered from a dependent, its instance can be given
  to the src keyword to avoid reassignment or loops."))

(defclass value-cell ()
  ((val :accessor val :initarg :val :initform 0)
   (ref :accessor ref :initarg :ref :initform nil)
   (ref-set-fn :accessor ref-set-fn :initarg :ref-set-fn :initform #'identity)
   (map-fn :initarg :map-fn :initform #'identity :accessor map-fn)
   (rmap-fn :initarg :rmap-fn :initform #'identity :accessor rmap-fn)))

(defmethod initialize-instance :after ((instance value-cell) &rest initargs)
  (declare (ignore initargs))
  (if (ref instance)
      (with-slots (val ref map-fn) instance
        (pushnew instance (dependents ref))
        (setf val (funcall map-fn (val ref))))
      (warn "no ref specified for ~a on initialization" instance))
  instance)

(defgeneric ref-set-cell (instance new-val)
  (:documentation "set the val of instance from its reference by
  invoking the rmap-fn on the val of the reference.")
  (:method ((instance value-cell) new-val)
    (with-slots (val ref-set-fn rmap-fn) instance
      (setf val (funcall rmap-fn new-val))
      (funcall ref-set-fn val))))

(defmethod (setf val) (new-val (instance value-cell))
  (setf (slot-value instance 'val) new-val)
;;;  (format t "directly setting value-cell~%")
  (if (ref instance) (set-cell (ref instance) (funcall (map-fn instance) new-val) :src instance))
  new-val)

(defmethod print-object ((obj value-cell) out)
  (print-unreadable-object (obj out :type t)
    (format out "~s" (val obj))))

(defgeneric set-ref (instance new-ref &key map-fn rmap-fn)
  (:documentation "(Re)set the reference model-cell of value cell and
  add to the model-cell's dependents list. Also remove instance in
  dependents of previous ref.")
  (:method ((instance value-cell) new-ref &key map-fn rmap-fn)
    (with-slots (ref) instance
      (when ref (setf (dependents ref) (delete instance (dependents ref))))
      (setf ref new-ref)
      (if new-ref
          (progn
            (pushnew instance (dependents new-ref))
            (if map-fn (setf (map-fn instance) map-fn))
            (if rmap-fn (setf (rmap-fn instance) rmap-fn))
            (setf (slot-value instance 'val)
                  (funcall rmap-fn (slot-value new-ref 'val))))))
    new-ref))

(defun model-val-expand (slots)
  (loop for slot in slots
        collect `(,slot (val ,slot))))

(defmacro with-model-slots (slots instance &body body)
  "bind the slotnames of cells to their value slots in body."
  `(with-slots ,slots ,instance
     (let ,(model-val-expand slots)
       ,@body)))

(defmacro model-slot-register-setf-method (slot-reader class-name)
  `(progn
     (warn "~&redefining setf for (~a ~a)" ',slot-reader ',class-name)
     (defgeneric (setf ,slot-reader) (val ,class-name)
       (:method (val (instance boid-params))
         (set-cell (,slot-reader instance) val)))))

(defun class-get-model-slot-readers (class-name)
  (let ((tmp (make-instance class-name))
         (class (find-class class-name)))
     (c2mop:ensure-finalized class)
     (loop for slot-def in (c2mop:class-direct-slots class)
           for slot-name = (c2mop:slot-definition-name slot-def)
           if (typep (slot-value tmp slot-name) 'model-slot)
             collect (first (c2mop:slot-definition-readers slot-def)))))

(defun class-get-model-slot-reader-defs (class-name)
  (loop for reader in (class-get-model-slot-readers class-name)
        collect `(model-slot-register-setf-method ,reader ,class-name)))

;;; (class-get-model-slot-reader-defs 'boid-params)

(defmacro class-redefine-model-slots-setf (class-name)
  `(progn
     ,@(class-get-model-slot-reader-defs class-name)))





;;; (class-redefine-model-slots-setf boid-params)

#|
(with-model-slots (maxspeed maxlife) *bp*
  (setf maxspeed 10))

(defparameter *model01* (make-instance 'model-slot))

(defparameter *v1* (make-instance 'value-cell :ref *model01*))

(defparameter *v2* (make-instance 'value-cell :ref *model01*))
|#


