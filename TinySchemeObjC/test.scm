(define (new class-name)
        (objc-send (objc-send (objc-class class-name) "alloc") "init"))

(begin
  (log "Hello")
  
  (objc-send (new "Test") "displayObject:" 
                          "Hello from Test class instance!")
  (log "Goodbye")
)
