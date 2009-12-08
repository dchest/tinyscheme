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
  
;
; Demo
;
(begin
  (log "Hello")

  (let ((test (new "Test")))
    (-> test "displayObject:" "Hello from Test class instance!")
    (-> test "displayObject:" "...and hello again")
    (if-bool (-> test "hasBool")
        (log "hasBool = true")
        (log "hasBool = false"))
    (log "Test class name is:" (class-name test))
    (define one "One")
    (define two "Two")
    (if (eqvobj? one two)
      (log one "==" two)
      (log one "!=" two)))
    
  (log "Goodbye... BTW, magic number is" 'magicNumber "of class" 
    (class-name 'magicNumber))
  
  ;
  ; 'current-objc-interface points to instance of TinyScheme ObjC class
  ; which runs us. Let me show how to manupilate it:
  ;
  (log "\n---\n"
       "Listing registered objects:\n"
      (description (-> 'current-objc-interface "registeredObjectsCopy"))
       "\n---")
)
