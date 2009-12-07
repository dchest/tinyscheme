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

(define (bool x)
  (if (eqv? x 0) #f #t))

(macro (if-bool form)
  `(if (bool ,(cadr form)) ,@(cddr form)))

(define (eqvobj? obj1 obj2)
  (bool (objc-send obj1 "isEqual:" obj2)))

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
    (if (eqvobj? "One" "Two")
      (log "One == Two ?!")
      (log "One != Two")))
    
  (log "Goodbye")
)
