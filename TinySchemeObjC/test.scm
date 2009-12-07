;
; ObjC helpers
;
(define (alloc class-name)
  (objc-send (objc-class class-name) "alloc"))

(define (init obj)
  (objc-send obj "init"))

(define (new class-name)
  (init (alloc class-name)))

(define (class-name object)
  (objc-send object "className"))

(define (self object)
  (objc-send object "self"))

(define (description object)
  (objc-send object "description"))

(define (ctrue? x)
  (if (zero? x) #f #t))

(macro (if-bool form)
  `(if (ctrue? ,(cadr form)) ,@(cddr form)))

(define (eqvobj? obj1 obj2)
  (ctrue? (objc-send obj1 "isEqual:" obj2)))
  
;
; Demo
;
(begin
  (log "Hello")

  (let ((test (new "Test")))
    (objc-send test "displayObject:" "Hello from Test class instance!")
    (objc-send test "displayObject:" "...and hello again")
    (if-bool (objc-send test "hasBool")
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
      (description (objc-send 'current-objc-interface "registeredObjectsCopy"))
       "\n---")
)
