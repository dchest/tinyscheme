;
; ObjC helpers
;
(define -> objc-send)

(define (alloc class-name)
  (-> (objc-class class-name) "alloc"))

(define (init obj)
  (-> obj "init"))

(define (new class-name)
  (init (alloc class-name)))

(define (class-name object)
  (-> object "className"))

(define (self object)
  (-> object "self"))

(define (description object)
  (-> object "description"))

(define (ctrue? x)
  (if (zero? x) #f #t))

(macro (if-bool form)
  `(if (ctrue? ,(cadr form)) ,@(cddr form)))

(define (eqvobj? obj1 obj2)
  (ctrue? (-> obj1 "isEqual:" obj2)))
  
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
