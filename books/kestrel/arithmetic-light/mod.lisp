; A lightweight book about the built-in function mod.
;
; Copyright (C) 2008-2011 Eric Smith and Stanford University
; Copyright (C) 2013-2019 Kestrel Institute
; For mod-sum-cases, see the copyright on the RTL library.
;
; License: A 3-clause BSD license. See the file books/3BSD-mod.txt.
;
; Author: Eric Smith (eric.smith@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ACL2")

;; Theorem rationalp-of-mod below may not hold in ACL2(r), so for now we
;; disable certification of this book in ACL2(r):
; cert_param: (non-acl2r)

(local (include-book "times"))
(local (include-book "minus"))
(local (include-book "plus"))
(local (include-book "floor"))

(in-theory (disable mod))

;; Note: ACL2's built-in :type-prescription rule for MOD tells us that it is an
;; acl2-number.

(defthm integerp-of-mod
  (implies (integerp y)
           (equal (integerp (mod x y))
                  (integerp (fix x))))
  :hints (("Goal" ;:cases (integerp x)
           :in-theory (enable mod))))

(defthm integerp-of-mod-type
  (implies (and (integerp x)
                (integerp y))
           (integerp (mod x y)))
  :rule-classes :type-prescription
  :hints (("Goal" :in-theory (enable mod))))

;gen?
(defthm nonneg-of-mod-type
  (implies (and (<= 0 x)
                (rationalp x)
                (<= 0 y)
                (rationalp y))
           (<= 0 (mod x y)))
  :rule-classes :type-prescription
  :hints (("Goal" :cases ((equal 0 y))
           :in-theory (enable mod my-floor-upper-bound-alt))))

(defthm nonneg-of-mod-type-2
  (implies (and ;(<= 0 x)
                (rationalp x)
                (< 0 y)
                (rationalp y))
           (<= 0 (mod x y)))
  :rule-classes :type-prescription
  :hints (("Goal" :cases ((equal 0 y))
           :in-theory (enable mod my-floor-upper-bound-alt))))

(defthm mod-of-0-arg1
  (equal (mod 0 y)
         0)
  :hints (("Goal" :in-theory (enable mod))))

(defthm mod-of-0-arg2
  (equal (mod x 0)
         (fix x))
  :hints (("Goal" :in-theory (enable mod))))

;; (mod x 1) returns the fractional part of x, which for an integer is 0.
(defthm mod-of-1-when-integerp
  (implies (integerp x)
           (equal (mod x 1)
                  0))
  :hints (("Goal" :in-theory (enable mod))))

(defthm mod-of-1-arg1
  (implies (and (integerp j)
                (<= 0 j) ;gen
                )
           (equal (mod 1 j)
                  ;;(if (<= 0 j)
                  (if (equal 1 j)
                      0
                    1)
                  ;;-1)
                  ))
  :hints (("Goal" :in-theory (enable mod))))

;; To support ACL2(r), we might have to assume (rationalp y) here.
(defthm rationalp-of-mod
  (implies (rationalp x)
           (rationalp (mod x y)))
  :rule-classes (:rewrite :type-prescription)
  :hints (("Goal" :cases ((rationalp y)
                          (complex-rationalp y))
           :in-theory (enable mod
                              floor-when-rationalp-and-complex-rationalp))))

(local (include-book "../../arithmetic-3/floor-mod/floor-mod"))

(defthm mod-of-mod-same-arg2
  (implies (and (rationalp x)
                (rationalp y))
           (equal (mod (mod x y) y)
                  (mod x y))))

(defthm mod-when-<
  (implies (and (< x y)
                (<= 0 x)
                (rationalp x)
                (rationalp y))
           (equal (mod x y)
                  x))
  :hints (("Goal" :cases ((rationalp x)))))

(defthmd equal-of-0-and-mod
  (implies (and (rationalp x)
                (rationalp y))
           (equal (equal 0 (mod x y))
                  (if (equal 0 y)
                      (equal 0 x)
                    (integerp (/ x y))))))

;; (defthm integerp-of-/-becomes-equal-of-0-and-mod
;;   (implies (and (rationalp x)
;;                 (rationalp y)
;;                 (not (equal 0 y)))
;;            (equal (integerp (/ x y))
;;                   (equal 0 (mod x y)))))

;todo: add alt conjunct
(defthmd integerp-of-*-of-/-becomes-equal-of-0-and-mod
  (implies (and (rationalp x)
                (rationalp y)
                (not (equal 0 y)))
           (equal (integerp (* (/ y) x)) ;should match things like (* 1/32 x)
                  (equal 0 (mod x y))))
  :hints (("Goal" :use (:instance equal-of-0-and-mod)
           :in-theory (disable equal-of-0-and-mod))))

(theory-invariant (incompatible (:rewrite integerp-of-*-of-/-becomes-equal-of-0-and-mod)
                                (:rewrite equal-of-0-and-mod)))

(defthm mod-bound-linear-arg1
  (implies (and (rationalp x)
                (<= 0 x)
                (rationalp y)
                (<= 0 y))
           (<= (mod x y) x))
  :rule-classes :linear
  :hints (("Goal" :cases ((equal y 0))
           :in-theory (enable mod))))

;this allows y to be negative (conclusion will be false)
(defthm <-of-mod-same-arg2
  (implies (and (rationalp x)
                (rationalp y))
           (equal (< (mod x y) y)
                  (if (equal 0 y)
                      (< x 0)
                    (<= 0 y)))))

(defthm mod-bound-linear-arg2
  (implies (and (rationalp x)
                (rationalp y)
                (< 0 y))
           (< (mod x y) y))
  :rule-classes :linear
  :hints (("Goal" :cases ((equal y 0))
           :in-theory (enable mod))))

(defthm equal-of-mod-same-arg1
  (implies (and (rationalp x)
                (rationalp y)
                (< 0 y))
           (equal (equal x (mod x y))
                  (and (<= 0 x)
                       (< x y)))))

(defthm mod-of-2-when-even-cheap
  (implies (and (integerp (* 1/2 x))
                (rationalp x))
           (equal (mod x 2)
                  0))
  :rule-classes ((:rewrite :backchain-limit-lst (0 nil)))
  :hints (("Goal" :in-theory (enable equal-of-0-and-mod))))

(defthm mod-of-*-lemma
  (implies (and (integerp x)
                (posp y))
           (equal (mod (* x y) y)
                  0)))

(defthm mod-of-*-lemma-alt
  (implies (and (integerp x)
                (posp y))
           (equal (mod (* y x) y)
                  0)))

(defthm integerp-of-mod-of-1
  (equal (integerp (mod x 1))
         (or (integerp x)
             (not (acl2-numberp x))))
  :hints (("Goal" :in-theory (enable mod))))

;quite aggressive
(defthmd mod-cancel
  (implies (syntaxp (not (equal ''1 y)))
           (equal (mod x y)
                  (if (equal 0 (fix y))
                      (fix x)
                    (* y (mod (/ x y) 1)))))
  :hints (("Goal" :in-theory (e/d (mod floor-normalize-denominator)
                                  (floor-of-*-of-/-and-1)))))

;from rtl:
(defthm mod-sum-cases
  (implies (and (<= 0 y)
                (rationalp x)
                (rationalp y)
                (rationalp k))
           (equal (mod (+ k x) y)
                  (if (< (+ (mod k y)
                            (mod x y))
                         y)
                      (+ (mod k y)
                         (mod x y))
                    (+ (mod k y)
                       (mod x y)
                       (* -1 y)))))
  :hints (("Goal" :in-theory (enable mod))))

;may be expensive..
;could specialize to when y1 and y2 are obviously powers of 2
(defthmd mod-of-mod-when-mult
  (implies (and (integerp (* y1 (/ y2)))
                (rationalp y1)
                (rationalp y2))
           (equal (mod (mod x y1) y2)
                  (if (equal 0 y2)
                      (mod x y1) ;rare case
                    (mod x y2))))
  :hints (("Goal" :in-theory (e/d (mod unicity-of-0) (integerp-of-*))
           :use ((:instance integerp-of-* (x (* y1 (/ y2)))
                            (y (floor x y1)))
                 (:instance floor-of-+-when-mult-arg1
                            (i1 (* y1 (floor i y1)))
                            (i2 x)
                            (j y2)
                            (i (* y1 (/ y2) (floor x y1))))))))

;gen
(defthm mod-of-*-of-mod
  (implies (and (integerp x)
                (integerp y)
                (integerp z)
                )
           (equal (mod (* x (mod y z)) z)
                  (mod (* x y) z))))

;gen
(defthm mod-of-*-of-mod-2
  (implies (and (integerp x)
                (integerp y)
                (integerp z)
                )
           (equal (mod (* (mod y z) x) z)
                  (mod (* y x) z))))

;rename
(defthm mod-mult-lemma
  (implies (and (integerp x)
                (integerp w)
                (integerp y))
           (equal (mod (+ (* y x) w) y)
                  (mod w y))))

(defthm mod-same
  (equal (mod x x)
         0)
  :hints (("Goal" :in-theory (enable mod))))

(defthm mod-of-minus-arg1
  (implies (and (rationalp x)
                (rationalp y)
                (not (equal y 0)))
           (equal (mod (- x) y)
                  (if (equal 0 (mod x y))
                      0
                    (- y (mod x y))))))

(defthm mod-of-minus-arg2
  (implies (and (rationalp x)
                (rationalp y))
           (equal (mod x (- y))
                  (- (mod (- x) y))))
  :hints (("Goal" :cases ((equal '0 y)))))


;; generalizing this is hard since even if x is not rational, the quotient may be.
(defthm mod-when-not-rationalp-arg1
  (implies (and (not (rationalp x))
                (rationalp y))
           (equal (mod x y)
                  (fix x)))
  :hints (("Goal" :in-theory (enable mod))))

(defthm mod-when-not-acl2-numberp
  (implies (not (acl2-numberp x))
           (equal (mod x y)
                  0))
  :hints (("Goal" :in-theory (enable mod floor))))

(defthm mod-when-multiple
  (implies (and (integerp (* x (/ y)))
                (rationalp x)
                (rationalp y)
                (not (equal 0 y)))
           (equal (mod x y)
                  0))
  :hints (("Goal" :in-theory (enable mod
                                     floor-when-multiple))))

(defthm mod-of-+-of-mod-arg1
  (implies (and (rationalp x1)
                (rationalp x2)
                (rationalp y)
                (< 0 y))
           (equal (mod (+ (mod x1 y) x2) y)
                  (mod (+ x1 x2) y)))
  :hints (("Goal" :in-theory (enable mod))))

(defthm mod-of-+-of-mod-arg2
  (implies (and (rationalp x1)
                (rationalp x2)
                (rationalp y)
                (< 0 y))
           (equal (mod (+ x1 (mod x2 y)) y)
                  (mod (+ x1 x2) y)))
  :hints (("Goal" :in-theory (enable mod))))

(defthm equal-of-mod-of-+-and-mod-of-+-cancel
  (implies (and (rationalp x)
                (rationalp y)
                (rationalp z)
                (integerp p)
                (< 0 p))
           (equal (equal (mod (+ x y) p)
                         (mod (+ x z) p))
                  (equal (mod y p) (mod z p))))
  :hints (("Goal" :in-theory (enable mod-sum-cases))))

;enable?
(defthmd mod-of-*-subst
  (implies (and (equal (mod y p)
                       (mod free p))
                (syntaxp (not (term-order y free)))
                (integerp x)
                (integerp y)
                (integerp free)
                (integerp p)
                (< 0 p))
           (equal (mod (* x y) p)
                  (mod (* x free) p)))
  :hints (("Goal" :use ((:instance mod-of-*-of-mod
                                  (z p)
                                  (y y))
                        (:instance mod-of-*-of-mod
                                  (z p)
                                  (y free)))
           :in-theory (disable mod-of-*-of-mod))))

(defthm mod-of-+-of---same
  (implies (and (rationalp x)
                (rationalp y)
                (< 0 y))
           (equal (mod (+ (- y) x) y)
                  (mod x y))))

(defthm mod-of-+-of---of-mod-same-arg1
  (implies (and (rationalp x1)
                (rationalp x2)
                (rationalp y)
                (< 0 y)
                )
           (equal (mod (+ (- (mod x1 y)) x2) y)
                  (mod (+ (- x1) x2) y))))

(defthm mod-of-+-of---of-mod-same-arg2
  (implies (and (rationalp x1)
                (rationalp x2)
                (rationalp y)
                (< 0 y)
                )
           (equal (mod (+ x2 (- (mod x1 y))) y)
                  (mod (+ x2 (- x1)) y))))

(defthm mod-of-+-same-arg1
  (implies (and (rationalp x)
                (rationalp y)
                (< 0 y))
           (equal (mod (+ y x) y)
                  (mod x y)))
  :hints (("Goal" :in-theory (enable mod-sum-cases))))

(defthm mod-of-+-same-arg2
  (implies (and (integerp x)
                (rationalp y)
                (< 0 y))
           (equal (mod (+ x y) y)
                  (mod x y))))

(defthm multiple-when-mod-0-cheap
  (implies (and (equal 0 (mod n m))
                (rationalp m)
                (rationalp n))
           (integerp (* (/ m) n)))
  :rule-classes ((:rewrite :backchain-limit-lst (0 nil nil))))

(defthm equal-of-0-and-mod-of-1
  (implies (rationalp x)
           (equal (equal 0 (mod x 1))
                  (integerp x))))

(defthm mod-bound-linear-arg2-strong
  (implies (and (integerp x)
                (integerp y)
                (< 0 y))
           (<= (mod x y) (+ -1 y)))
  :rule-classes :linear
  :hints (("Goal" :use (:instance mod-bound-linear-arg2))))


;gen?
(defthm <-of-mod-same2
  (implies (and (< 0 y)
                (rationalp y)
                (rationalp x))
           (not (< y (mod x y)))))

;gen?
(defthm equal-of-mod-same
  (implies (and (< 0 y)
                (rationalp y)
                (rationalp x))
           (not (equal y (mod x y)))))

;two ways of saying that i is odd
(defthm equal-of-+-1-and-*-2-of-floor-of-2
  (implies (integerp i)
           (equal (equal i (+ 1 (* 2 (floor i 2))))
                  (equal 1 (mod i 2))))
  :hints (("Goal" :in-theory (enable mod))))

(defthmd *-of-2-and-floor-of-2
  (implies (integerp i)
           (equal (* 2 (floor i 2))
                  (if (equal 1 (mod i 2))
                      (+ -1 i)
                    i)))
  :hints (("Goal" :in-theory (enable))))

(defthm split-low-bit
  (implies (rationalp i)
           (equal i (+ (* 2 (floor i 2)) (mod i 2))))
  :rule-classes nil
  :hints (("Goal" :in-theory (enable mod))))

(defthmd floor-of-2-cases
  (implies (integerp i)
           (equal (floor i 2)
                  (if (equal 0 (mod i 2))
                      (/ i 2)
                    (+ -1/2 (/ i 2)))))
  :hints (("Goal" :use ((:instance floor-unique
                                   (j 2)
                                   (n (if (equal 0 (mod i 2))
                                          (/ i 2)
                                        (+ 1/2 (/ i 2)))))
                        (:instance split-low-bit)))))

;two ways of saying that i is even
(defthmd equal-of-*-2-of-floor-of-2-same
  (equal (equal (* 2 (floor i 2)) i)
         (and (acl2-numberp i)
              (equal 0 (mod i 2))))
  :hints (("Goal" :in-theory (enable mod))))

(theory-invariant (incompatible (:definition mod) (:rewrite equal-of-*-2-of-floor-of-2-same)))

(defthmd floor-when-mod-0
  (implies (and (equal 0 (mod x y))
                (rationalp x)
                (rationalp y)
                (not (equal 0 y)))
           (equal (floor x y)
                  (/ x y)))
  :hints (("Goal" :in-theory (enable mod))))

(defthm mod-of-*-subst-constant-arg1
  (implies (and (equal (mod x p) free)
                (syntaxp (and (quotep free)
                              (not (quotep x))))
                (integerp y)
                (integerp x)
                (rationalp free)
                (integerp p)
                (< 0 p))
           (equal (mod (* x y) p)
                  (mod (* free y) p))))

(defthm mod-of-*-subst-constant-arg2
  (implies (and (equal (mod x p) free)
                (syntaxp (and (quotep free)
                              (not (quotep x))))
                (integerp y)
                (integerp x)
                (rationalp free)
                (integerp p)
                (< 0 p))
           (equal (mod (* y x) p)
                  (mod (* y free) p))))
