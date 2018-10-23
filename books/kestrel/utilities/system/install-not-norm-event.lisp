; System Utilities -- Non-Normalized Definition Installation Event
;
; Copyright (C) 2018 Kestrel Institute (http://www.kestrel.edu)
; Copyright (C) 2018, Regents of the University of Texas
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)
; Author: Matt Kaufmann (kaufmann@cs.utexas.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

(include-book "misc/install-not-normalized" :dir :system)
(include-book "event-forms")
(include-book "fresh-names")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define install-not-norm-event
  ((fn symbolp "Function to install the non-normalized definition of.")
   (local booleanp "Make the event form local or not.")
   (names-to-avoid symbol-listp "Avoid these as theorem name.")
   (wrld plist-worldp))
  :returns (mv (event "A @(tsee pseudo-event-formp).")
               (name "A @(tsee symbolp): the name of the theorem."))
  :mode :program
  :parents (system-utilities-non-built-in install-not-normalized)
  :short "Create an event form to
          <see topic='@(url install-not-normalized)'>install
          the non-normalized definition</see>
          of a function,
          ensuring that the name of the theorem will not cause a conflict."
  :long
  "<p>
   Ensure that the name of the theorem is not already in use
   and is not among a list of names to avoid.
   Start with the default name
   (i.e. the concatenation of
   the name of @('fn') with @('$not-normalized'))
   and ensure its uniqueness via @(tsee fresh-name-in-world-with-$s).
   </p>"
  (b* ((name (install-not-normalized-name fn))
       (name (fresh-name-in-world-with-$s name names-to-avoid wrld))
       (event
        (if local
            `(local (install-not-normalized ,fn :defthm-name ',name :allp nil))
          `(install-not-normalized ,fn :defthm-name ',name :allp nil))))
    (mv event name)))

(define install-not-norm-event-lst
  ((fns symbol-listp "Functions to install the non-normalized definitions of.")
   (local booleanp "Make the event forms local or not.")
   (names-to-avoid symbol-listp "Avoid these as theorem names.")
   (wrld plist-worldp))
  :returns (mv (events "A list of @(tsee pseudo-event-formp) values.")
               (names "A @(tsee symbol-listp): the names of the theorems."))
  :mode :program
  :parents (system-utilities-non-built-in install-not-normalized)
  :short "Create a list of event forms to
          <see topic='@(url install-not-normalized)'>install
          the non-normalized definitions</see>
          of a list of functions,
          ensuring that the names of the theorems will not cause a conflict."
  :long
  "<p>
   Ensure that the names of the theorems are not already in use
   and are not among a list of names to avoid.
   Start with the default names
   (i.e. the concatenation of
   the names of each function suffixed with @('$not-normalized'))
   and ensure their uniqueness via @(tsee fresh-name-in-world-with-$s).
   </p>"
  (cond ((endp fns) (mv nil nil))
        (t (mv-let (event name)
             (install-not-norm-event (car fns) local names-to-avoid wrld)
             (mv-let (rest-events rest-names)
               (install-not-norm-event-lst (cdr fns)
                                           local
                                           (cons name names-to-avoid)
                                           wrld)
               (mv (cons event rest-events)
                   (cons name rest-names)))))))

(defun install-not-norm-fn (fn allp names-to-avoid state)
  (declare (xargs :stobjs state :mode :program))
  (let* ((wrld (w state))
         (fns (and allp
                   (getpropc fn 'recursivep nil wrld))))
    (cond
     ((cdr fns)
      (mv-let (events names)
        (install-not-norm-event-lst fns nil names-to-avoid wrld)
        (declare (ignore names))
        (cons 'progn events)))
     (t (mv-let (event name)
          (install-not-norm-event fn nil names-to-avoid wrld)
          (declare (ignore name))
          event)))))

(defmacro install-not-norm (fn &key allp names-to-avoid)
  `(make-event (install-not-norm-fn ',fn ,allp ,names-to-avoid state)))

(defxdoc install-not-norm
  :parents (system-utilities-non-built-in install-not-normalized)
  :short "<see topic='@(url install-not-normalized)'>Install
          the non-normalized definition</see>
          of a function,
          ensuring that the name of the theorem will not cause a conflict."
  :long
  "<p>This utility is an event which, when evaluated successfully, installs the
 event generated by @(tsee install-not-norm-event).  See @(see
 install-not-norm-event).</p>

 @(def install-not-norm)")