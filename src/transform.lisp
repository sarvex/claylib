(in-package #:claylib)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defclass rl-transform ()
    ((%translation :initarg :trans
                   :type rl-vector3
                   :reader trans)
     (%rotation :initarg :rot
                :type rl-vector4
                :reader rot)
     (%scale :initarg :scale
             :type rl-vector3
             :reader scale)
     (%c-struct
      :type claylib/ll:transform
      :initform (autowrap:alloc 'claylib/ll:transform)
      :accessor c-struct))))

(defcwriter-struct trans rl-transform translation transform vector3 x y z)
(defcwriter-struct rot rl-transform rotation transform vector4 x y z w)
(defcwriter-struct scale rl-transform scale transform vector3 x y z)

(defmethod sync-children ((obj rl-transform))
  (unless (eq (c-struct (trans obj))
              (transform.translation (c-struct obj)))
    (free-later (c-struct (trans obj)))
    (setf (c-struct (trans obj))
          (transform.translation (c-struct obj))))
  (unless (eq (c-struct (rot obj))
              (transform.rotation (c-struct obj)))
    (free-later (c-struct (rot obj)))
    (setf (c-struct (rot obj))
          (transform.rotation (c-struct obj))))
  (unless (eq (c-struct (scale obj))
              (transform.scale (c-struct obj)))
    (free-later (c-struct (scale obj)))
    (setf (c-struct (scale obj))
          (transform.scale (c-struct obj)))))

(definitializer rl-transform
  :struct-slots ((%translation) (%rotation) (%scale)))

(default-free rl-transform %translation %rotation %scale)
(default-free-c claylib/ll:transform)
