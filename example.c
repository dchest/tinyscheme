//
// Tiny example of embedding TinyScheme in your code
// by Dmitry Chestnykh <dmitry@codingrobots.com>
// Public domain
//
//
// Compile 
// --------
// $ cc example.c -L./ -ltinyscheme -o example
//
// Note: if you want to statically, link, first compile tinyscheme as NOT standalone.
// To do this, change scheme.h: # define STANDALONE 0   (instead of 1)
// Then 'make'. Forget about errors. Remove libtinyscheme.so (leave only static library .a)
// And then compile this example as written above.
// 
//
// Run
// ---
// $ ./example
//
// Output
// --------------
// Hello, world!
// Answer: 42

#include <stdio.h>

#define USE_INTERFACE 1

#include "scheme.h"
#include "scheme-private.h"

// display -- scheme function
// Example: (display "Hello")
// This version only displays strings
pointer display(scheme *sc, pointer args) {
  if (args!=sc->NIL) {
    if (sc->vptr->is_string(sc->vptr->pair_car(args)))  {
      char *str = sc->vptr->string_value(sc->vptr->pair_car(args));
      printf("%s", str);
    }
  }
  return sc->NIL;
}

// square -- scheme function
// Example: (square 3)
pointer square(scheme *sc, pointer args) {
  if (args!=sc->NIL) {
    if(sc->vptr->is_number(sc->vptr->pair_car(args))) {
      double v=sc->vptr->rvalue(sc->vptr->pair_car(args));
      return sc->vptr->mk_real(sc,v*v);
    }
  }
  return sc->NIL;
}


int main(void) {
  scheme *sc;
  
  // Init Scheme interpreter
  sc = scheme_init_new();
  
  // Load init.scm
  FILE *finit = fopen("init.scm", "r");
  scheme_load_file(sc, finit);
  fclose(finit);

  // Define square 
  sc->vptr->scheme_define( 
       sc, 
       sc->global_env, 
       sc->vptr->mk_symbol(sc, "square"), 
       sc->vptr->mk_foreign_func(sc, square)); 

  // Define display
  sc->vptr->scheme_define( 
       sc, 
       sc->global_env, 
       sc->vptr->mk_symbol(sc, "display"), 
       sc->vptr->mk_foreign_func(sc, display)); 

  // Run first example
  char *hello_scm = "(display \"Hello, world!\\n\")";
  scheme_load_string(sc, hello_scm);

  // Run second example
  char *square_scm = "(display "
                     "  (string-append \"Answer: \" "
                     "    (number->string (square 6.480740698407859)) \"\\n\"))";
  scheme_load_string(sc, square_scm);
  
  // Bye!
  scheme_deinit(sc);
  return 0;
}