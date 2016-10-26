#lang scribble/manual
@(require (for-label slideshow slideshow/staged-slide pict/conditional))

@title{Staged Slides}

@author[@author+email["Carl Eastlund" "cce@racket-lang.org"]
        @author+email["Vincent St-Amour" "stamourv@racket-lang.org"]]

@defmodule[slideshow/staged-slide]

This library provides helpers for creating stages slides that provide more
flexibility than Slideshow's build-in @racket[slide].

@defform[(staged [name ...] body ...)]{

Executes the @racket[body] terms once for each stage @racket[name].  The terms
may include expressions and mutually recursive definitions.  Within the body,
each @racket[name] is bound to a number from @racket[1] to the number of stages
in order.  Furthermore, during execution @racket[stage] is bound to the number
of the current stage and @racket[stage-name] is bound to a symbol representing
the @racket[name] of the current stage.  By comparing @racket[stage] to the
numeric value of each @racket[name], or @racket[stage-name] to quoted symbols of
the form @racket['name], the user may compute based on the progression of the
stages.
}

@deftogether[(
@defform[#:id stage stage]
@defform[#:id stage-name stage-name]
)]{

These keywords are bound during the execution of @racket[staged] and should not
be used otherwise.
}

@defform[(slide/staged [name ...] arg ...)]{

Creates a staged slide.  Equivalent to @racket[(staged [name ...] (slide arg
...))].

Within a staged slide, the boolean arguments to @racket[hide], @racket[show],
and others can be used to determine in which stages to perform a transformation.
The macros @racket[pict-if], @racket[pict-cond], and @racket[pict-case], may
also be used to create images which change naturally between stages.
}

@defform[(at name ...)]{
Returns @racket[#t] if the current stage is one of @racket[name].
}
@defform[(before name)]{
Returns @racket[#t] if the current stage is before @racket[name].
}
@defform[(before/at name)]{
Returns @racket[#t] if the current stage is before @racket[name] or is @racket[name].
}
@defform[(at/after name)]{
Returns @racket[#t] if the current stage is after @racket[name] or is @racket[name].
}
@defform[(after name)]{
Returns @racket[#t] if the current stage is after @racket[name].
}
@defform[(before/after name)]{
Returns @racket[#t] if the current stage is before or after @racket[name].
}
