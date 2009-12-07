(begin
  (display "Hello")
  (define (TestClass) (objc-class "Test"))
  (objc-send 
    (objc-send 
      (objc-send (TestClass) "alloc") 
     "init") 
   "displayObject:" "Hello from Test class instance!")
  (display "Goodbye")
)