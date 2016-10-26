#lang info

(define collection "slideshow")

(define deps '("base" "pict-lib" "slideshow-lib"))

(define build-deps '("scribble-lib"
                     "pict-doc"
                     "racket-doc"
                     "slideshow-doc"))

(define pkg-authors '(stamourv cce))

(define version "1.0")

(define scribblings
  '(("scribblings/staged-slide.scrbl" () ("Slideshow Libraries"))))
