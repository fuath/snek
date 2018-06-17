
(in-package :lin-path)

(defstruct path
  (n nil :type integer :read-only t)
  (lens nil :read-only t)
  (closed nil :type boolean)
  (pts nil :read-only t))


(defun -diff-scale (a b s) (/ (- b a) s))


(defun -set-path-lens (pts lens n)
  (let ((total (loop for i from 0 below (1- n)
                     sum (vec:dst (vec:arr-get pts i)
                                  (vec:arr-get pts (1+ i))) into total
                     do (setf (aref lens (1+ i) 0) total)
                     finally (return total))))
    (loop for i from 1 below n
          do (setf (aref lens i 0) (/ (aref lens i 0) total)))))


(defun -find-seg-ind (lens f n)
  (loop with l = 0
        with r = (- n 1)
        with mid = 0
        until (<= (aref lens mid 0) f (aref lens (1+ mid) 0))
        do (setf mid (floor (+ l r) 2))
           (cond ((> f (aref lens mid 0)) (setf l (progn mid)))
                 ((< f (aref lens mid 0)) (setf r (1+ mid))))

        finally (return (1+ mid))))


(defun -calc-pos (pts lens n f)
  (let* ((ind (-find-seg-ind lens f n))
         (pb (vec:arr-get pts ind))
         (pa (vec:arr-get pts (1- ind)))
         (s (-diff-scale (aref lens (1- ind) 0)
                         f
                         (- (aref lens ind 0) (aref lens (1- ind) 0)))))
    (vec:add pa (vec:scale (vec:sub pb pa) s))))


(defun pos (pth f)
  (declare (path pth))
  (with-struct (path- lens pts n) pth
    (-calc-pos pts lens n (mod (math:dfloat f) 1.0d0))))


(defun pos* (pth ff)
  (declare (path pth))
  (declare (list ff))
  (with-struct (path- lens pts n) pth
    (mapcar (lambda (f) (-calc-pos pts lens n (mod f 1.0d0)))
            (math:dfloat* ff))))


(defun rndpos (pth n)
  (pos* pth (rnd:rndspace n 0d0 1d0)))


(defun make (pts &key closed
                 &aux (n (if closed (+ (length pts) 1) (length pts))))
  (declare (list pts))
  (let ((p (make-dfloat-array n))
        (l (make-dfloat-array n :cols 1)))
    (loop for pt in pts and i from 0
          do (vec:arr-set p i pt))

    (when closed (vec:arr-set p (1- n) (first pts)))

    (-set-path-lens p l n)
    (make-path :n n :pts p :lens l :closed closed)))

