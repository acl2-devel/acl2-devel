(in-package "RTL")

(include-book "definitions")
(include-book "rcp")
(local (include-book "example"))

(defthm init-approx
  (implies (and (rationalp a)
                (rationalp b)
                (rationalp y)
                (rationalp ep)
                (not (zp p))
                (> a 0)
                (> b 0)
                (<= (abs (- 1 (* b y))) ep))
           (<= (abs (- 1 (* (/ b a) (rne (* a y) p))))
               (+ ep (* (expt 2 (- p)) (1+ ep)))))
  :rule-classes ())

(defthm r-exactp
  (implies (and (rationalp a)
                (rationalp b)
                (integerp p)
                (> p 1)
                (exactp a p)
                (exactp b p)
                (<= 1 a)
                (< a 2)
                (<= 1 b)
                (< b 2)
                (rationalp q)
                (exactp q p)
                (< (abs (- (/ a b) q)) (expt 2 (- (1+ (if (> a b) 0 -1)) p))))
           (exactp (- a (* b q)) p))
  :rule-classes ())

(defthm markstein-lemma
  (let ((e (if (> a b) 0 -1))
        (r (- a (* b q))))
    (implies (and (rationalp a)
                  (rationalp b)
                  (rationalp q)
                  (rationalp y)
                  (integerp p)
                  (<= 1 a)
                  (< a 2)
                  (<= 1 b)
                  (< b 2)
                  (> p 1)
                  (exactp a p)
                  (exactp b p)
                  (exactp q p)
                  (< (abs (- 1 (* b y))) (/ (expt 2 p)))
                  (< (abs (- (/ a b) q)) (expt 2 (- (1+ e) p)))
                  (ieee-rounding-mode-p mode))
             (= (rnd (+ q (* r y)) mode p)
                (rnd (/ a b) mode p))))
  :rule-classes ())

(defthm quotient-refinement-1
  (implies (and (rationalp a)
                (rationalp b)
                (rationalp y)
                (rationalp q0)
                (rationalp ep)
                (rationalp de)
                (not (zp p))
                (<= 1 a)
                (< a 2)
                (<= 1 b)
                (< b 2)
                (<= (abs (- 1 (* b y))) ep)
                (<= (abs (- 1 (* (/ b a) q0))) de))
            (let* ((r (rne (- a (* b q0)) p))
                   (q (rne (+ q0 (* r y)) p)))
              (<= (abs (- q (/ a b)))
                  (* (/ a b)
                     (+ (expt 2 (- p))
                        (* (1+ (expt 2 (- p))) de ep)
                        (* (expt 2 (- p)) de (1+ ep))
                        (* (expt 2 (- (* 2 p))) de (1+ ep)))))))
  :rule-classes ())

(defthm recip-refinement-1
  (let* ((e1 (rne (- 1 (* b y1)) p))
         (y3p (+ y1 (* e1 y2)))
         (ep3p (* ep1 (+ ep2 (* (expt 2 (- p)) (1+ ep2))))))
    (implies (and (rationalp y1)
                  (rationalp y2)
                  (rationalp b)
                  (rationalp ep1)
                  (rationalp ep2)
                  (integerp p)
                  (> p 0)
                  (<= (abs (- 1 (* b y1))) ep1)
                  (<= (abs (- 1 (* b y2))) ep2))
             (<= (abs (- 1 (* b y3p)))
                 ep3p)))
  :rule-classes ())

(defthm quotient-refinement-2
  (implies (and (rationalp a)
                (rationalp b)
                (rationalp y)
                (rationalp q0)
                (rationalp ep)
                (rationalp de)
                (not (zp p))
                (<= 1 a)
                (< a 2)
                (<= 1 b)
                (< b 2)
                (<= (abs (- 1 (* b y))) ep)
                (<= (abs (- 1 (* (/ b a) q0))) de)
                (< (+ (* ep de) (* (expt 2 (- p)) de (1+ ep))) (expt 2 (- (1+ p)))))
            (let* ((r (rne (- a (* b q0)) p))
                   (q (rne (+ q0 (* r y)) p))
                   (e (if (> a b) 0 -1)))
              (< (abs (- q (/ a b)))
                 (expt 2 (- (1+ e) p)))))
  :rule-classes ())

(defthm recip-refinement-2
  (let* ((e1 (rne (- 1 (* b y1)) p))
         (y3p (+ y1 (* e1 y2)))
         (y3 (rne y3p p))
         (ep3p (* ep1 (+ ep2 (* (expt 2 (- p)) (1+ ep2)))))
         (ep3 (+ ep3p (* (expt 2 (- p)) (1+ ep3p)))))
    (implies (and (rationalp y1)
                  (rationalp y2)
                  (rationalp b)
                  (rationalp ep1)
                  (rationalp ep2)
                  (integerp p)
                  (> p 0)
                  (<= (abs (- 1 (* b y1))) ep1)
                  (<= (abs (- 1 (* b y2))) ep2))
             (<= (abs (- 1 (* b y3)))
                 ep3)))
  :rule-classes ())

(defund h-excps (d p)
  (if (zp d)
      ()
    (cons (- 2 (* (expt 2 (- 1 p)) d))
          (h-excps (1- d) p))))

(defthm harrison-lemma
  (let ((y (rne yp p))
        (d (cg (* (expt 2 (* 2 p)) ep))))
    (implies (and (rationalp b)
                  (rationalp yp)
                  (rationalp ep)
                  (integerp p)
                  (> p 1)
                  (<= 1 b)
                  (< b 2)
                  (exactp b p)
                  (not (member b (h-excps d p)))
                  (< ep (expt 2 (- (1+ p))))
                  (<= (abs (- 1 (* b yp))) ep))
             (< (abs (- 1 (* b y))) (expt 2 (- p)))))
  :rule-classes ())

(defthm rcp24-spec
  (implies (and (rationalp b)
                (exactp b 24)
                (<= 1 b)
                (< b 2))
           (and (exactp (rcp24 b) 24)
                (<= 1/2 (rcp24 b))
                (<= (rcp24 b) 1)
                (< (abs (- 1 (* b (rcp24 b)))) (expt 2 -23))))
  :rule-classes ())

(defund divsp (a b mode)
  (let* ((y0 (rcp24 b))
         (q0 (rne (* a y0) 24))
         (e0 (rne (- 1 (* b y0)) 24))
         (r0 (rne (- a (* b q0)) 24))
         (y1 (rne (+ y0 (* e0 y0)) 24))
         (q1 (rne (+ q0 (* r0 y1)) 24))
         (r1 (rne (- a (* b q1)) 24)))
    (rnd (+ q1 (* r1 y1)) mode 24)))

(defthm divsp-small-cases
  (implies (and (not (zp k))
                (<= k 7))
           (let* ((b (- 2 (* (expt 2 -23) k)))
                  (y0 (rcp24 b))
                  (e0 (rne (- 1 (* b y0)) 24))
                  (y1 (rne (+ y0 (* e0 y0)) 24)))
             (< (abs (- 1 (* b y1)))
                (expt 2 -24))))
  :rule-classes ()
  :hints (("Goal" :use ((:instance bvecp-member (x k) (n 3)))
           :in-theory (enable bvecp))))

(defthm divsp-correct
  (implies (and (rationalp a)
                (rationalp b)
                (<= 1 a)
                (< a 2)
                (<= 1 b)
                (< b 2)
                (exactp a 24)
                (exactp b 24)
                (ieee-rounding-mode-p mode))
           (= (divsp a b mode) (rnd (/ a b) mode 24)))
  :rule-classes ())

(defthm rcp24-rtz-error
  (implies (and (rationalp b)
                (<= 1 b)
                (< b 2))
           (<= (abs (- 1 (* b (rcp24 (rtz b 24))))) (expt 2 -22)))
  :rule-classes ())

(defund divdp (a b mode)
  (let* ((y0 (rcp24 (rtz b 24)))
         (q0 (rne (* a y0) 53))
         (e0 (rne (- 1 (* b y0)) 53))
         (r0 (rne (- a (* b q0)) 53))
         (y1 (rne (+ y0 (* e0 y0)) 53))
         (e1 (rne (- 1 (* b y1)) 53))
         (y2 (rne (+ y0 (* e0 y1)) 53))
         (q1 (rne (+ q0 (* r0 y1)) 53))
         (y3 (rne (+ y1 (* e1 y2)) 53))
         (r1 (rne (- a (* b q1)) 53)))
    (rnd (+ q1 (* r1 y3)) mode 53)))

(defthm divdp-small-cases
  (implies (and (not (zp k))
                (<= k 1027))
           (let* ((b (- 2 (* (expt 2 -52) k)))
                  (y0 (rcp24 (rtz b 24)))
                  (e0 (rne (- 1 (* b y0)) 53))
                  (y1 (rne (+ y0 (* e0 y0)) 53))
                  (e1 (rne (- 1 (* b y1)) 53))
                  (y2 (rne (+ y0 (* e0 y1)) 53))
                  (y3 (rne (+ y1 (* e1 y2)) 53)))
             (< (abs (- 1 (* b y3)))
                (expt 2 -53))))
  :rule-classes ()
  :hints (("Goal" :in-theory (enable y0 e0 y1 e1 y2 y3)
           :use (divdp-small-cases-1
                 (:instance excp-cases (b (- 2 (* (expt 2 -52) k))))))))

(defthm divdp-correct
  (implies (and (rationalp a)
                (rationalp b)
                (<= 1 a)
                (< a 2)
                (<= 1 b)
                (< b 2)
                (exactp a 53)
                (exactp b 53)
                (ieee-rounding-mode-p mode))
           (= (divdp a b mode) (rnd (/ a b) mode 53)))
  :rule-classes ())

