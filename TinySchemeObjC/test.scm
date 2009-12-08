;; objc.scm should be preloaded
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
      (log one "!=" two))
    (-> test "testArgumentsWithBool:andString:" YES "string argument")
    (log "Logging:" (-> test "testArgumentsWithFloat:andInt:" 66.28 65539)))
    
  (log "BTW, magic number is" 'magicNumber "of class" 
    (class-name 'magicNumber))

  (let ((fm (new "NSFileManager")))
    (log "App folder name:" (-> fm "displayNameAtPath:" "/Applications")))
  
  ;
  ; 'current-objc-interface points to instance of TinyScheme ObjC class
  ; which runs us. Let me show how to manupilate it:
  ;
  (log "\n---\n"
       "Listing registered objects:\n"
      (description (-> 'current-objc-interface "registeredObjectsCopy"))
       "\n---")
       
  (log "Goodbye!")
  
)
