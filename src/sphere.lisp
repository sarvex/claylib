(in-package #:claylib)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defclass sphere (3d-shape)
    ((%radius :initarg :radius
              :type (float 0 *)
              :accessor radius)
     (%rings :initarg :rings
             :type (integer 0 *)
             :accessor rings)
     (%slices :initarg :slices
              :type (integer 0 *)
              :accessor slices))
    (:default-initargs
     :rings 16
     :slices 16)))

(define-print-object sphere
    (radius rings slices))

(defmethod (setf radius) :before (value (obj sphere))
  (set-linked-children 'radius obj value))
(defmethod (setf rings) :before (value (obj sphere))
  (set-linked-children 'rings obj value))
(defmethod (setf slices) :before (value (obj sphere))
  (set-linked-children 'slices obj value))

(definitializer cube
  :lisp-slots ((%radius) (%rings) (%slices)))

(defun make-sphere (x y z radius color &rest args &key filled rings slices)
  (declare (ignorable filled rings slices))
  (apply #'make-instance 'sphere
         :pos (make-vector3 x y z)
         :radius radius
         :color color
         args))

(defun make-sphere-from-vec (pos radius color &rest args &key filled rings slices)
  (declare (ignorable filled rings slices))
  (apply #'make-instance 'sphere
         :pos pos
         :radius radius
         :color color
         args))

(defmethod draw-object ((obj sphere))
  (if (filled obj)
      (claylib/ll:draw-sphere-ex (c-struct (pos obj))
                                 (radius obj)
                                 (rings obj)
                                 (slices obj)
                                 (c-struct (color obj)))
      (claylib/ll:draw-sphere-wires (c-struct (pos obj))
                                    (radius obj)
                                    (rings obj)
                                    (slices obj)
                                    (c-struct (color obj)))))

(static-draw draw-sphere-object sphere)
