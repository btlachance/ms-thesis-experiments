#lang racket/base
(require pict
         ppict/tag
         racket/contract/base racket/match
         racket/splicing racket/stxparam racket/draw
         racket/class
         (for-syntax racket/base)
         pict/shadow (submod pict/shadow unstable)
         (submod slideshow/staged-slide pict))
(provide (all-from-out pict/shadow)
         (all-from-out (submod pict/shadow unstable))
         (all-from-out ppict/tag))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Picture Manipulation
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ryanc: 'inset-to' might be a better name than 'fill'
(define (fill pict w h)
  (cc-superimpose
   pict
   (blank (or w (pict-width pict))
          (or h (pict-height pict)))))

(provide colorize/alpha)
(define (colorize/alpha pict r g b a)
  (colorize pict (make-object color% r g b a)))

(define (color c p) (colorize p c))

(provide/contract
 [color (-> color/c pict? pict?)]
 [fill
  (-> pict?
      (or/c (real-in 0 +inf.0) #f)
      (or/c (real-in 0 +inf.0) #f)
      pict?)])

(require pict/color) ; for re-export
(provide color/c
         red orange yellow green blue purple
         black brown gray white cyan magenta
         light dark)

(require pict/conditional ; for re-export
         (submod pict/conditional params))

;; unlike with match, pattern variables are not bound in the rhss (and can't be)
;; so left in unstable, instead of moving to pict/conditional like the others
;; pointed out by ryanc
(define-syntax (pict-match stx)
  (syntax-case stx ()
    [(_ test #:combine combine [pattern expr] ...)
     (with-syntax ([(pict ...) (generate-temporaries #'(expr ...))])
       (syntax/loc stx
         (let ([pict expr] ...)
           (combine (match test [pattern pict] ... [_ (blank 0 0)])
                    (ghost pict) ...))))]
    [(_ test [pattern expr] ...)
     (quasisyntax/loc stx
       (pict-match test #:combine #,(syntax-parameter-value #'pict-combine)
                   [pattern expr] ...))]))

(provide hide show
         pict-if pict-cond pict-case pict-match
         pict-combine with-pict-combine)

(provide/contract
 [strike (->* [pict?] [any/c] pict?)]
 [shade (->* [pict?] [any/c #:ratio (real-in 0 1)] pict?)])

;; from slideshow/staged-slide, re-exported for backwards compatibility
(provide staged stage stage-name
         before at after before/at at/after)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Slide Staging
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (shade pict [shade? #t] #:ratio [ratio 0.5])
  (if shade? (cellophane pict ratio) pict))

(define (strike pict [strike? #t])
  (if strike?
      (pin-over pict
                0
                (/ (pict-height pict) 2)
                (pip-line (pict-width pict) 0 0))
      pict))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Misc
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; the following has been added by stamourv, then replaced with implementations
;; adapted from Ian Johnson

(define (draw-shape/border dc-path color border-color border-width)
  (define-values (color* style)
    (if color
        (values color 'solid)
        (values "white" 'transparent)))
  (let-values ([(x y w h) (send dc-path get-bounding-box)])
    (dc (λ (dc dx dy)
          (define old-brush (send dc get-brush))
          (define old-pen   (send dc get-pen))
          (send dc set-brush
                (send the-brush-list find-or-create-brush color* style))
          (send dc set-pen (send the-pen-list
                                 find-or-create-pen
                                 border-color
                                 border-width
                                 (send old-pen get-style)))
          (send dc draw-path dc-path (- dx x) (- dy y))
          (send dc set-brush old-brush)
          (send dc set-pen   old-pen))
        w h)))

(define (ellipse/border ew eh
                        #:color [color #f]
                        #:border-color [border-color "black"]
                        #:border-width [border-width 2])
  (define dc-path (new dc-path%))
  (send dc-path ellipse 0 0 ew eh)
  (draw-shape/border dc-path color border-color border-width))
(define (circle/border d
                       #:color [color #f]
                       #:border-color [border-color "black"]
                       #:border-width [border-width 2])
  (ellipse/border d d
                  #:color color #:border-color border-color
                  #:border-width border-width))
(define (rounded-rectangle/border w h
                                  #:color [color #f]
                                  #:border-color [border-color "black"]
                                  #:border-width [border-width 2]
                                  #:corner-radius [corner-radius -0.25]
                                  #:angle [angle 0])
  (define dc-path (new dc-path%))
  (send dc-path rounded-rectangle 0 0 w h corner-radius)
  (send dc-path rotate angle)
  (draw-shape/border dc-path color border-color border-width))
(define (rectangle/border w h
                          #:color [color #f]
                          #:border-color [border-color "black"]
                          #:border-width [border-width 2])
  (define dc-path (new dc-path%))
  (send dc-path rectangle 0 0 w h)
  (draw-shape/border dc-path color border-color border-width))

(define shape/border-contract
  (->* [real? real?]
       [#:color color/c #:border-color color/c #:border-width real?]
       pict?))
(provide/contract
 [ellipse/border shape/border-contract]
 [rectangle/border shape/border-contract]
 [rounded-rectangle/border
  (->* [real? real?]
       [#:color color/c #:border-color color/c #:border-width real? #:corner-radius real? #:angle real?]
       pict?)]
 [circle/border
  (->* [real?]
       [#:color color/c #:border-color color/c #:border-width real?]
       pict?)])

;; the following has been written by Scott Owens
;; and updated and added by stamourv

(define (pin-label-line label pict
                        src-pict src-coord-fn
                        dest-pict dest-coord-fn
                        #:start-angle (start-angle #f)
                        #:end-angle (end-angle #f)
                        #:start-pull (start-pull 1/4)
                        #:end-pull (end-pull 1/4)
                        #:line-width (line-width #f)
                        #:color (color #f)
                        #:alpha (alpha 1)
                        #:style (style 'solid)
                        #:under? (under? #f)
                        #:x-adjust (x-adjust 0)
                        #:y-adjust (y-adjust 0))
  (pin-line pict
            src-pict src-coord-fn
            dest-pict dest-coord-fn
            #:start-angle start-angle #:end-angle end-angle
            #:start-pull start-pull #:end-pull end-pull
            #:line-width line-width #:color color #:alpha alpha
            #:style style #:under? under?
            #:label label #:x-adjust-label x-adjust #:y-adjust-label y-adjust))

(define-values (pin-arrow-label-line
                pin-arrows-label-line)
  (let ()
    (define ((mk fn)
             label arrow-size pict
             src-pict src-coord-fn
             dest-pict dest-coord-fn
             #:start-angle (start-angle #f)
             #:end-angle (end-angle #f)
             #:start-pull (start-pull 1/4)
             #:end-pull (end-pull 1/4)
             #:line-width (line-width #f)
             #:color (color #f)
             #:alpha (alpha 1)
             #:under? (under? #f)
             #:solid? (solid? #t)
             #:style (style 'solid)
             #:hide-arrowhead? (hide-arrowhead? #f)
             #:x-adjust (x-adjust 0)
             #:y-adjust (y-adjust 0))
      (fn arrow-size pict src-pict src-coord-fn dest-pict dest-coord-fn
          #:start-angle start-angle #:end-angle end-angle
          #:start-pull start-pull #:end-pull end-pull
          #:line-width line-width #:color color #:under? under?
          #:style style #:alpha alpha #:solid? solid?
          #:hide-arrowhead? hide-arrowhead?
          #:label label #:x-adjust-label x-adjust #:y-adjust-label y-adjust))
    (values (mk pin-arrow-line)
            (mk pin-arrows-line))))
(define pin-arrow-label-line-contract
  (->* [pict? real? pict?
        pict-path? (-> pict? pict-path? (values real? real?))
        pict-path? (-> pict? pict-path? (values real? real?))]
       [#:start-angle (or/c real? #f) #:end-angle (or/c real? #f)
        #:start-pull real? #:end-pull real?
        #:line-width (or/c real? #f)
        #:color (or/c #f string? (is-a?/c color%))
        #:style pen-style/c
        #:alpha (real-in 0 1)
        #:solid? any/c
        #:under? any/c #:hide-arrowhead? any/c
        #:x-adjust real? #:y-adjust real?]
       pict?))

(provide/contract
 [pin-label-line
  (->* [pict? pict?
        pict-path? (-> pict? pict-path? (values real? real?))
        pict-path? (-> pict? pict-path? (values real? real?))]
       [#:start-angle (or/c real? #f) #:end-angle (or/c real? #f)
        #:start-pull real? #:end-pull real?
        #:line-width (or/c real? #f)
        #:color (or/c #f string? (is-a?/c color%))
        #:under? any/c
        #:x-adjust real? #:y-adjust real?]
       pict?)]
 [pin-arrow-label-line pin-arrow-label-line-contract]
 [pin-arrows-label-line pin-arrow-label-line-contract])

;; the following are by ryanc

(define (scale-to p w h #:mode [mode 'preserve])
  (let* ([w0 (pict-width p)]
         [h0 (pict-height p)]
         [wfactor0 (if (zero? w0) 1 (/ w w0))]
         [hfactor0 (if (zero? h0) 1 (/ h h0))])
    (let-values ([(wfactor hfactor)
                  (case mode
                    ((preserve inset)
                     (let ([factor (min wfactor0 hfactor0)])
                       (values factor factor)))
                    ((distort)
                     (values wfactor0 hfactor0)))])
      (let ([scaled-pict (scale p wfactor hfactor)])
        (case mode
          ((inset)
           (cc-superimpose (blank w h) scaled-pict))
          (else
           scaled-pict))))))

(provide/contract
 [scale-to
  (->* (pict? real? real?)
       (#:mode (or/c 'preserve 'inset 'distort))
       pict?)])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Other pict combinators
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The following were added by asumu
(provide (contract-out
          [backdrop (->* (pict?) (#:color color/c) pict?)]
          [cross-out (->* (pict?)
                          (#:width real?
                           #:style (or/c 'transparent 'solid 'xor
                                         'hilite 'dot 'long-dash 'short-dash
                                         'dot-dash 'xor-dot 'xor-long-dash
                                         'xor-short-dash 'xor-dot-dash)
                           #:color color/c)
                          pict?)]))

;; backdrop
;; adds a background highlighted with the given color
(define (backdrop pict #:color [color "white"])
  (pin-under
   pict 0 0
   (colorize (filled-rectangle
              (pict-width pict)
              (pict-height pict))
             color)))

;; cross-out
;; crosses out the pict with two lines of the given color
(define (cross-out pict
                   #:width [width 1]
                   #:style [style 'solid]
                   #:color [color "black"])
  (cc-superimpose
   pict
   (dc (λ (dc dx dy)
         (define old-pen (send dc get-pen))
         (send dc set-pen
               (new pen% [width width] [style style] [color color]))
         (send dc draw-line
               dx dy
               (+ dx (pict-width pict)) (+ dy (pict-height pict)))
         (send dc draw-line
               (+ dx (pict-width pict)) dy
               dx (+ dy (pict-height pict)))
         (send dc set-pen old-pen))
       (pict-width pict)
       (pict-height pict))))
;; draw

(define (draw-pict-centered p dc aw ah)
  (define pw (pict-width p))
  (define ph (pict-height p))
  (define (inset x y)
    (/ (- x y) 2))
  (draw-pict p dc (inset aw pw) (inset ah ph)))

(provide
 (contract-out
  [draw-pict-centered 
   (-> pict? (is-a?/c dc<%>) real? real?
       void?)]))
