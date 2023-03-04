(in-package #:claylib/ll)

(defvar *claylib-background* +raywhite+)
(defvar *screen-width* 800)
(defvar *screen-height* 450)
(defvar *target-fps* 60)

(defun calloc (type &optional (count 1))
  (cffi:foreign-funcall "calloc"
                        :unsigned-int count
                        :unsigned-int (cffi:foreign-type-size type)
                        :pointer))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun builtin-type-p (type)
    (find type (append cffi:*built-in-float-types*
                       cffi:*built-in-foreign-types*
                       cffi:*built-in-integer-types*
                       cffi:*other-builtin-types*))))

(defun field-ptr (ptr type field-name)
  (cffi:foreign-slot-pointer ptr
                             (intern (format nil "~A" type) :claylib/ll)
                             (intern (format nil "~A" field-name) :claylib/ll)))

(defun field-value (ptr type field-name)
  (cffi:foreign-slot-value ptr
                           (intern (format nil "~A" type) :claylib/ll)
                           (intern (format nil "~A" field-name) :claylib/ll)))

(defun set-field-value (ptr type field-name value)
  (setf (cffi:foreign-slot-value ptr
                                 (intern (format nil "~A" type) :claylib/ll)
                                 (intern (format nil "~A" field-name) :claylib/ll))
        value))

(defsetf field-value set-field-value)

(defmacro lisp-bool (name &rest args)
  (let ((c-fun (intern (remove #\' (format nil "~:@a" name)))) 
        (lisp-fun (intern (remove #\' (format nil "~:@a-P" name)))))
    `(defun ,lisp-fun (,@args)
       (declare (inline))
       (,c-fun ,@args)
;       (= (,c-fun ,@args) 1)
       )))

(lisp-bool window-should-close)
(lisp-bool is-window-ready)
(lisp-bool is-window-fullscreen)
(lisp-bool is-window-hidden)
(lisp-bool is-window-minimized)
(lisp-bool is-window-maximized)
(lisp-bool is-window-focused)
(lisp-bool is-window-resized)
(lisp-bool is-window-state flag)

(lisp-bool is-cursor-hidden)
(lisp-bool is-cursor-on-screen)

(lisp-bool file-exists file-name)
(lisp-bool directory-exists dir-path)
(lisp-bool is-file-extension file-name ext)
(lisp-bool is-path-file path)
(lisp-bool is-file-dropped)

(lisp-bool is-key-pressed key)
(lisp-bool is-key-down key)
(lisp-bool is-key-released key)
(lisp-bool is-key-up key)

(lisp-bool is-gamepad-available gamepad)
(lisp-bool is-gamepad-button-pressed gamepad button)
(lisp-bool is-gamepad-button-down gamepad button)
(lisp-bool is-gamepad-button-released gamepad button)
(lisp-bool is-gamepad-button-up gamepad button)

(lisp-bool is-mouse-button-pressed button)
(lisp-bool is-mouse-button-down button)
(lisp-bool is-mouse-button-released button)
(lisp-bool is-mouse-button-up button)

(lisp-bool is-gesture-detected gesture)

(lisp-bool text-is-equal text1 text2)

(lisp-bool is-model-animation-valid model anim)

(lisp-bool is-audio-device-ready)

(lisp-bool is-sound-playing sound)

(lisp-bool is-music-stream-playing music)

(lisp-bool is-audio-stream-processed stream)
(lisp-bool is-audio-stream-playing stream)

(lisp-bool gui-is-locked)

(declaim (inline run-window-p))
(defun run-window-p ()
  "Returns T if the raylib window status is good and should therefore stay open."
  (not (window-should-close-p)))


(defmacro with-window ((&key
                          (width *screen-width*)
                          (height *screen-height*)
                          (title "")
                          (fps *target-fps*)
                          (flags ())
                          (min-size ()))
                       &body body)
  "Initializes a new game window, runs your code, and closes when finished."
  `(progn
     (init-window ,width ,height ,title)
     (set-target-fps ,fps)
     ,(when flags
       `(set-config-flags (reduce #'+ ,flags)))
     ,(when min-size
       `(set-window-min-size ,(car min-size) ,(cadr min-size)))
     ,@body
     (close-window)))


(defmacro loop-drawing (&body body)
  "Provides a Raylib loop structure which prepares for drawing
  and loops until the user closes the graphics window."
  `(loop while (run-window-p) do
     (begin-drawing)
     (clear-background *claylib-background*)
     ,@body
     (end-drawing)))


(defmacro do-drawing (vars ends &body body)
  "Provides a Raylib-ready do construct which prepares for drawing."
  `(do ,vars ,ends
     (begin-drawing)
     (clear-background *claylib-background*)
     ,@body
     (end-drawing)))


(defmacro with-drawing ((&key (bgcolor *claylib-background*)) &body body)
  "Provides a simple Raylib-ready construct for drawing."
  `(progn
     (begin-drawing)
     (clear-background ,bgcolor)
     ,@body
     (end-drawing)))


(defmacro with-mode2d (cam &body body)
  "Provides a simple Raylib-ready construct for 2D camera mode."
  `(progn
     (begin-mode2d ,cam)
     ,@body
     (end-mode2d)))

(defmacro with-mode3d (cam &body body)
  "Provides a simple Raylib-ready construct for 3D camera mode."
  `(progn
     (begin-mode3d ,cam)
     ,@body
     (end-mode3d)))

(defmacro with-texture-mode ((texture &key (bgcolor *claylib-background*)) &body body)
  "Provides a simple Raylib-ready construct for texture mode."
  `(progn
     (begin-texture-mode ,texture)
     (clear-background ,bgcolor)
     ,@body
     (end-texture-mode)))

(defmacro with-scissor-mode (x y width height &body body)
  "Provides a simple Raylib-ready construct for scissor mode."
  ;; Raylib's scissor mode only supports ints. We could convert but I think it's best
  ;; to leave it up to the user how to do that.
  `(progn
     (begin-scissor-mode ,x ,y ,width ,height)
     ,@body
     (end-scissor-mode)))

(defmacro struct-setter (name &rest skip-fields)
  ;; TODO: Type checking/coercion
  (flet ((setter (name)
           (alexandria:symbolicate (format nil "SET-~:@a" name)))
         (get-fields (type)
           (cffi:foreign-slot-names type)))
    (let ((field-specs (mapcar #'(lambda (field)
                                   `(,field ,(cffi:foreign-slot-type name field)))
                               (get-fields name))))
      `(defun ,(setter name) ,(append '(struct)
                               (remove-if #'(lambda (f)
                                              (member f skip-fields))
                                (mapcar #'car field-specs)))
         ,@(loop for field in field-specs
                 unless (member (car field) skip-fields)
                   collect (cond ((builtin-type-p (cadr field))
                                  `(setf (field-value struct ',name ',(car field))
                                         ,(car field)))
                                 ((listp (cadr field)) ; Field is a pointer
                                  `(setf (field-value struct ',name ',(car field))
                                         ,(car field)))
                                 ((eql (cadr field) :bool)
                                  `(setf (field-value struct ',name ',(car field))
                                         (if ,(car field) 1 0)))
                                 ((eql (cadr field) :string)
                                  `(setf (field-value struct ',name ',(car field))
                                         ,(car field)))
                                 (t (let ((ftype (case (cadr field)
                                                   (texture2d 'texture)
                                                   (quaternion 'vector4)
                                                   (t (cadr field)))))
                                      `(,(setter ftype) (field-value struct ',name ',(car field))
                                        ,@(loop for subfield in (get-fields ftype)
                                                collect `(field-value ,(car field) ',ftype ',subfield)))))))))))

(struct-setter vector2)
(struct-setter vector3)
(struct-setter vector4)
(struct-setter matrix)
(struct-setter color)
(struct-setter rectangle)
(struct-setter image)
(struct-setter texture)
(struct-setter render-texture)
(struct-setter n-patch-info)
(struct-setter glyph-info)
(struct-setter font)
(struct-setter camera3d)
(struct-setter camera2d)
(struct-setter mesh)
(struct-setter shader)
(struct-setter material-map)

(defun set-material (struct shader maps params)
  (set-shader (field-value struct 'material 'shader)
              (field-value shader 'shader 'id)
              (field-value shader 'shader 'locs))
  (setf (field-value struct 'material 'maps) maps)
  (let ((ptr (field-ptr struct 'material 'params)))
    (dotimes (i 4)
      (when (nth i params)
        (setf (cffi:mem-aref ptr :float i) (nth i params))))))

(struct-setter transform)
(struct-setter bone-info name)
(struct-setter model)
(struct-setter model-animation)
(struct-setter ray)
(struct-setter ray-collision)
(struct-setter bounding-box)
(struct-setter wave)
(struct-setter audio-stream)
(struct-setter sound)
(struct-setter music)
(struct-setter vr-device-info chroma-ab-correction lens-distortion-values)
;(struct-setter vr-stereo-config left-lens-center left-screen-center projection right-lens-center right-screen-center scale scale-in view-offset)
(struct-setter file-path-list)
