(define (new class-name)
        (objc-send (objc-send (objc-class class-name) "alloc") "init"))

(begin
  (log "Hello")

  (let ((test (new "Test")))
    (objc-send test "displayObject:" "Hello from Test class instance!")
    (objc-send test "displayObject:" "...and hello again"))
    
  (log "Goodbye")
)
