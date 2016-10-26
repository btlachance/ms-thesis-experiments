#lang racket/base

;; that part is required by `unstable/gui/pict`, for backwards compatibility
;; because `unstable/gui/pict` is required in its own docs to show examples,
;; that part can't depend on `slideshow`, otherwise building docs tries to
;; unstantiate the GUI twice
(module pict racket/base
  (require racket/stxparam
           racket/block
           (for-syntax racket/base))
  (provide staged stage stage-name
           before at after before/at at/after)

  (define-for-syntax (stage-keyword stx)
    (raise-syntax-error #f "not in the body of a staged slide" stx))

  (define-syntax-parameter stage stage-keyword)
  (define-syntax-parameter stage-name stage-keyword)

  (define-syntax (staged stx)
    (syntax-case stx ()
      [(_ [name ...] body ...)
       (let* ([ids (syntax->list #'(name ...))])

         (for ([id (in-list ids)] #:unless (identifier? id))
           (raise-syntax-error #f "expected an identifier" stx id))

         (with-syntax ([(num ...)
                        (for/list ([i (in-naturals 1)] [id (in-list ids)])
                          (datum->syntax #'here i id))])

           (syntax/loc stx
             (let* ([name num] ...)
               (define (staged-computation number symbol)
                 (syntax-parameterize
                  ([stage (make-rename-transformer #'number)]
                   [stage-name (make-rename-transformer #'symbol)])
                  (block body ...)))
               (begin (staged-computation name 'name) ...)))))]))

  (define-syntax-rule (before name) (< stage name))
  (define-syntax-rule (before/at name) (<= stage name))
  (define-syntax-rule (at/after name) (>= stage name))
  (define-syntax-rule (after name) (> stage name))
  (define-syntax-rule (before/after name) (not (= stage name)))
  (define-syntax-rule (at name ...) (or (= stage name) ...)))

(require slideshow
         (submod "." pict))

(define-syntax-rule (slide/staged [name ...] body ...)
  (staged [name ...] (slide body ...)))

(provide slide/staged
         (all-from-out (submod "." pict)))
