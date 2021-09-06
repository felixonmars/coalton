(in-package #:coalton-user)

(coalton-toplevel

  ;;
  ;; Vector
  ;;

  (define-type (Vector :a)
    (Vector Lisp-Object))

  (declare make-vector (Unit -> (Vector :a)))
  (define (make-vector _)
    "Create a new empty vector"
    (make-vector-capacity 0))

  (declare make-vector-capacity (Int -> (Vector :a)))
  (define (make-vector-capacity n)
    "Create a new vector with N elements preallocated"
    (lisp (Vector :a) (n)
      (Vector (veil (cl:make-array n :fill-pointer 0 :adjustable cl:t)))))

  (declare vector-length ((Vector :a) -> Int))
  (define (vector-length v)
    "Returns the length of V"
    (lisp Int (v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:fill-pointer v_))))

  (declare vector-capacity ((Vector :a) -> Int))
  (define (vector-capacity v)
    "Returns the number of elements that V can store without resizing"
    (lisp Int (v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:array-dimension v_ 0))))

  (declare vector-empty ((Vector :a) -> Boolean))
  (define (vector-empty v)
    "Returns TRUE if V is empty"
    (== 0 (vector-length v)))

  (declare vector-push (:a -> (Vector :a) -> Unit))
  (define (vector-push item v)
    "Append ITEM to V and resize V if necessary"
    (lisp Unit (item v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:progn
	  (cl:vector-push-extend item v_)
	  Unit))))

  (declare vector-pop ((Vector :a) -> (Optional :a)))
  (define (vector-pop v)
    "Remove and return the first item of V"
    (if (== 0 (vector-length v))
	None
	(Some (vector-pop-unsafe v)))) 

  (declare vector-pop-unsafe ((Vector :a) -> :a))
  (define (vector-pop-unsafe v)
    "Remove and return the first item of V without checking if the vector is empty"
    (lisp :a (v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:vector-pop v_))))

  (declare vector-index (Int -> (Vector :a) -> (Optional :a)))
  (define (vector-index index v)
    "Return the INDEXth element of V"
    (if (>= index (vector-length v))
	None
	(Some (vector-index-unsafe index v))))

  (declare vector-index-unsafe (Int -> (Vector :a) -> :a))
  (define (vector-index-unsafe index v) 
    "Return the INDEXth element of V without checking if the element exists"
    (lisp :a (index v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:aref v_ index))))

  (declare vector-set (Int -> :a -> (Vector :a) -> Unit))
  (define (vector-set index item v)
    "Set the INDEXth element of V to ITEM. This function left intentionally unsafe because it does not have a return value to check."
    (lisp Unit (index item v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:progn
	  (cl:setf (cl:aref v_ index) item)
	  Unit))))

  (declare vector-head ((Vector :a) -> (Optional :a)))
  (define (vector-head v)
    "Return the first item of V"
    (vector-index 0 v))

  (declare vector-head-unsafe ((Vector :a) -> :a))
  (define (vector-head-unsafe v)
    "Return the first item of V without first checking if V is empty"
    (vector-index-unsafe 0 v))

  (declare vector-last ((Vector :a) -> (Optional :a)))
  (define (vector-last v)
    "Return the last element of V"
    (vector-index (- (vector-length v) 1) v))

  (declare vector-last-unsafe ((Vector :a) -> :a))
  (define (vector-last-unsafe v)
    "Return the last element of V without first checking if V is empty"
    (vector-index-unsafe (- (vector-length v) 1) v))

  (declare vector-foreach ((:a -> :b) -> (Vector :a) -> Unit))
  (define (vector-foreach f v)
    "Call the function F once for each item in V"
    (lisp Unit (f v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:progn
	  (cl:loop :for elem :across v_
	     :do (coalton-impl/codegen::A1 f elem))
	  Unit))))

  (declare vector-foreach-index ((Int -> :a -> :b) -> (Vector :a) -> Unit))
  (define (vector-foreach-index f v)
    "Call the function F once for each item in V with its index"
    (lisp Unit (f v)
      (cl:let ((v_ (unveil (cl:slot-value v '_0))))
	(cl:progn
	  (cl:loop
	     :for elem :across v_
	     :for i :from 0
	     :do (coalton-impl/codegen::A2 f i elem))
	  Unit))))

  (declare vector-foreach2 ((:a -> :a -> :b) -> (Vector :a) -> (Vector :a) -> Unit))
  (define (vector-foreach2 f v1 v2)
    "Like vector-foreach but twice as good"
    (lisp Unit (f v1 v2)
      (cl:let ((v1_ (unveil (cl:slot-value v1 '_0)))
	       (v2_ (unveil (cl:slot-value v2 '_0))))
	(cl:progn
	  (cl:loop
	     :for e1 :across v1_
	     :for e2 :across v2_
	     :do (coalton-impl/codegen::A2 f e1 e2))
	  Unit))))

  (declare vector-append ((Vector :a) -> (Vector :a) -> (Vector :a)))
  (define (vector-append v1 v2)
    "Create a new VECTOR containing the elements of v1 followed by the elements of v2"
    (progn
      (let out = (make-vector-capacity (+ (vector-length v1) (vector-length v2))))
      (let f =
	(fn (item)
	  (vector-push item out)))
      
      (vector-foreach f v1)
      (vector-foreach f v2)
      out))

  (declare vector-to-list ((Vector :a) -> (List :a)))
  (define (vector-to-list v)
    (let ((inner
	    (fn (v index)
	      (if (>= index (vector-length v))
		  Nil
		  (Cons (vector-index-unsafe index v) (inner v (+ 1 index)))))))
      (inner v 0)))
  ;;
  ;; Vector Instances
  ;;

  (define-instance (Eq :a => (Eq (Vector :a)))
    (define (== v1 v2)
      (if (/= (vector-length v1) (vector-length v2))
	  False
	  (progn
	    ;; Currently singleton vectors are the only way to have mutability in coalton
	    (let out = (make-vector-capacity 1))
	    (vector-set 0 True out)
	    (vector-foreach2
	     (fn (e1 e2)
	       (unless (== e1 e2)
		 (vector-set 0 False out)))
	     v1 v2)
	    (vector-index-unsafe 0 out))))
    (define (/= v1 v2)
      (not (== v1 v2))))

  (define-instance (Semigroup (Vector :a))
    (define (<> v1 v2)
      (vector-append v1 v2)))

  (define-instance (Functor Vector)
    (define (map f v)
      (progn
	(let out = (make-vector-capacity (vector-length v)))
	(vector-foreach
	 (fn (item)
	   (vector-push (f item) out))
	 v)
	out)))

  (define-instance (Into (List :a) (Vector :a))
    (define (into lst)
      (progn
	(let out = (make-vector-capacity (length lst)))
	(let inner =
	  (fn (lst)
	    (match lst
	      ((Cons x xs)
	       (progn
		 (vector-push x out)
		 (inner xs)))
	      ((Nil) Unit))))
	(inner lst)
	out)))

  (define-instance (Into (Vector :a) (List :a))
    (define (into v)
      (vector-to-list v)))

  (define-instance (Iso (Vector :a) (List :a))))