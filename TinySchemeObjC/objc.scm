;
; ObjC helpers
;
(define -> objc-send)

(define (alloc x)
  (-> (objc-class x) "alloc"))

(define (init x)
  (-> x "init"))

(define (new x)
  (init (alloc x)))

(define (class-name x)
  (-> x "className"))

(define (self x)
  (-> x "self"))

(define (description x)
  (-> x "description"))

(define (ctrue? x)
  (if (zero? x) #f #t))

(macro (if-bool form)
  `(if (ctrue? ,(cadr form)) ,@(cddr form)))

(define (eqvobj? x y)
  (ctrue? (-> x "isEqual:" y)))
 
(define YES 1)
(define NO  0)
