(begin
  (display "Hello")
  
  (define (new class-name)
          (objc-send (objc-send (objc-class class-name) "alloc") "init")))
  
  (objc-send (new "Test") "displayObject:" 
                          "Hello from Test class instance!")
  (display "Goodbye")
)
