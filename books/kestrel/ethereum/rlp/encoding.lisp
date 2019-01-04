; Ethereum Library -- RLP Encoding
;
; Copyright (C) 2018 Kestrel Institute (http://www.kestrel.edu)
;
; License: A 3-clause BSD license. See the LICENSE file distributed with ACL2.
;
; Author: Alessandro Coglio (coglio@kestrel.edu)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package "ETHEREUM")

(include-book "kestrel/utilities/define-sk" :dir :system)

(include-book "big-endian")
(include-book "trees")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defxdoc+ rlp-encoding
  :parents (rlp)
  :short "RLP encoding."
  :long
  (xdoc::topapp
   (xdoc::p
    "We specify RLP encoding via functions
     from byte arrays, trees, and scalars
     to byte arrays.
     These functions closely correspond to the ones in [YP:B].
     They are both executable and high-level.")
   (xdoc::p
    "We also define valid RLP encodings as images of the encoding functions.
     These are declaratively defined, non-executable predicates."))
  :order-subtopics t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define rlp-encode-bytes ((bytes byte-listp))
  :parents (rlp-encoding)
  :returns (mv (error? booleanp)
               (encoding byte-listp
                         :hints (("Goal"
                                  :in-theory (enable bytep)
                                  :use (:instance
                                        acl2::len-of-nat=>bendian*-leq-width
                                        (nat (len bytes))
                                        (base 256)
                                        (width 8))))))
  :short "RLP encoding of a byte array."
  :long
  (xdoc::topapp
   (xdoc::p
    "This corresponds to @($R_{\\mathrm{b}}$) [YP:(180)].")
   (xdoc::p
    "That equation does not explicitly say that the byte array
     can be encoded only if its length is below @($2^{64}$).
     This can be inferred from the fact that, according to [YP:(183)],
     encodings whose first byte is 192 or higher
     are used for non-leaf trees.
     In order for the encoding to be unambiguous
     (in particular, to distinguish leaf trees from non-leaf trees),
     the first byte that encodes a byte array must be below 192.
     Thus, the length of the base-256 big-endian representation
     of the length of the byte array,
     which is added to 183, can be at most 8
     (reaching 191 for the first byte of the encoding).
     This means that the base-256 big-endian representation
     of the length of the byte array
     must have at most 8 digits,
     i.e. it must be below @($256^8$), which is @($2^{64}$).
     The encoding code in [Wiki:RLP] confirms this, via an explicit check.")
   (xdoc::p
    "The first result of this function is an error flag,
     which is @('t') if the argument byte array cannot be encoded;
     in this case, @('nil') is returned as the (irrelevant) second result."))
  (b* ((bytes (byte-list-fix bytes)))
    (cond ((and (= (len bytes) 1)
                (< (car bytes) 128)) (mv nil bytes))
          ((< (len bytes) 56) (b* ((encoding (cons (+ 128 (len bytes))
                                                   bytes)))
                                (mv nil encoding)))
          ((< (len bytes)
              (expt 2 64)) (b* ((be (nat=>bendian* 256 (len bytes)))
                                (encoding (cons (+ 183 (len be))
                                                (append be bytes))))
                             (mv nil encoding)))
          (t (mv t nil))))
  :no-function t
  :hooks (:fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defines rlp-encode-tree
  :parents (rlp-encoding)
  :short "RLP encoding of a tree."
  :long
  (xdoc::topapp
   (xdoc::p
    "This corresponds to
     @($\\mathtt{RLP}$) [YP:(179)],
     @($R_{\\mathrm{l}}$) [YP:(183)],
     and @($s$) [YP:(184)].
     More precisely,
     @(tsee rlp-encode-tree) corresponds to @($\\mathtt{RLP}$),
     the non-leaf case of @(tsee rlp-encode-tree)
     corresponds to @($R_{\\mathrm{l}}$),
     and @(tsee rlp-encode-tree-list) corresponds to @($s$).")
   (xdoc::p
    "[YP:(183)] does not explicitly say that the tree can be encoded
     only if the total length of its encoded subtrees is below @($2^{64}$).
     This can be inferred from the fact that the first byte, being a byte,
     cannot exceed 255.
     Thus, the length of the base-256 big-endian representation
     of the length of the encoded subtrees,
     which is added to 247, can be at most 8
     (reaching 255 for the first byte of the encoding).
     This means that the base-256 big-endian representation
     of the length of the encoded subtrees
     must have at most 8 digits,
     i.e. it must be below @($256^8$), which is @($2^{64}$).
     The encoding code in [Wiki:RLP] confirms this, via an explicit check.")
   (xdoc::p
    "Similarly, [YP:(184)] does not explicitly say that
     the concatenation of the encoded subtrees
     cannot be encoded if any subtree cannot be encoded.
     This can be inferred from the fact that if a subtree encoding is too long,
     the supertree encoding is at least that long.
     The encoding code in [Wiki:RLP] confirms this, by propagating exceptions.")
   (xdoc::p
    "The first result of this function is an error flag,
     which is @('t') if the argument tree cannot be encoded;
     in this case, @('nil') is returned as the (irrelevant) second result.")
   (xdoc::def "rlp-encode-tree")
   (xdoc::def "rlp-encode-tree-list"))
  :verify-guards nil ; done below

  (define rlp-encode-tree ((tree rlp-treep))
    :returns (mv (error? booleanp)
                 (encoding byte-listp))
    (rlp-tree-case
     tree
     :leaf (rlp-encode-bytes tree.bytes)
     :nonleaf (b* (((mv error? encoding) (rlp-encode-tree-list tree.subtrees))
                   ((when error?) (mv t nil)))
                (cond ((< (len encoding) 56)
                       (b* ((encoding (cons (+ 192 (len encoding))
                                            encoding)))
                         (mv nil encoding)))
                      ((< (len encoding)
                          (expt 2 64))
                       (b* ((be (nat=>bendian* 256 (len encoding)))
                            (encoding (cons (+ 247 (len be))
                                            (append be encoding))))
                         (mv nil encoding)))
                      (t (mv t nil)))))
    :measure (rlp-tree-count tree)
    :no-function t)

  (define rlp-encode-tree-list ((trees rlp-tree-listp))
    :returns (mv (error? booleanp)
                 (encoding byte-listp))
    (b* (((when (endp trees)) (mv nil nil))
         ((mv error? encoding1) (rlp-encode-tree (car trees)))
         ((when error?) (mv t nil))
         ((mv error? encoding2) (rlp-encode-tree-list (cdr trees)))
         ((when error?) (mv t nil)))
      (mv nil (append encoding1 encoding2)))
    :measure (rlp-tree-list-count trees)
    :no-function t)

  :returns-hints (("Goal"
                   :in-theory (enable bytep))
                  '(:use (:instance
                          acl2::len-of-nat=>bendian*-leq-width
                          (nat (len
                                (mv-nth 1 (rlp-encode-tree-list
                                           (rlp-tree-nonleaf->subtrees tree)))))
                          (base 256)
                          (width 8))))

  ///

  (verify-guards rlp-encode-tree
    :hints (("Goal"
             :in-theory (enable true-listp-when-byte-listp-rewrite))))

  (fty::deffixequiv-mutual rlp-encode-tree))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define rlp-encode-scalar ((nat natp))
  :returns (mv (error? booleanp)
               (encoding byte-listp))
  :parents (rlp-encoding)
  :short "RLP encoding of a scalar."
  :long
  (xdoc::topapp
   (xdoc::p
    "This corresponds to @($\\mathtt{RLP}$) [YP:(185)].")
   (xdoc::p
    "The first result of this function is an error flag,
     which is @('t') if the argument scalar is so large that
     its big-endian representation exceeds @($2^{64}$) in length."))
  (rlp-encode-bytes (nat=>bendian* 256 (lnfix nat)))
  :no-function t
  :hooks (:fix))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-sk rlp-tree-encoding-p ((encoding byte-listp))
  :returns (yes/no booleanp)
  :parents (rlp-encoding)
  :short "Check if a byte array is an RLP encoding of a tree."
  :long
  (xdoc::topp
   "This is a declarative, non-executable definition,
    which essentially characterizes the image of @(tsee rlp-encode-tree)
    (over trees that can be encoded,
    i.e. such that @(tsee rlp-encode-tree) returns a @('nil') error flag).")
  (exists (tree)
          (and (rlp-treep tree)
               (b* (((mv tree-error? tree-encoding) (rlp-encode-tree tree)))
                 (and (not tree-error?)
                      (equal tree-encoding (byte-list-fix encoding))))))
  :skolem-name rlp-tree-encoding-witness
  ///

  (fty::deffixequiv rlp-tree-encoding-p
    :args ((encoding byte-listp))
    :hints (("Goal"
             :in-theory (disable rlp-tree-encoding-p-suff)
             :use ((:instance rlp-tree-encoding-p-suff
                    (tree (rlp-tree-encoding-witness (byte-list-fix encoding))))
                   (:instance rlp-tree-encoding-p-suff
                    (tree (rlp-tree-encoding-witness encoding))
                    (encoding (byte-list-fix encoding))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-sk rlp-bytes-encoding-p ((encoding byte-listp))
  :returns (yes/no booleanp)
  :parents (rlp-encoding)
  :short "Check if a byte array is an RLP encoding of a byte array."
  :long
  (xdoc::topapp
   (xdoc::p
    "This is analogous to @(tsee rlp-tree-encoding-p).")
   (xdoc::p
    "The encoding of a byte array
     is also the encoding of a tree consisting of a single leaf
     with that byte array."))
  (exists (bytes)
          (and (byte-listp bytes)
               (b* (((mv bytes-error? bytes-encoding) (rlp-encode-bytes bytes)))
                 (and (not bytes-error?)
                      (equal bytes-encoding (byte-list-fix encoding))))))
  :skolem-name rlp-bytes-encoding-witness
  ///

  (fty::deffixequiv rlp-bytes-encoding-p
    :args ((encoding byte-listp))
    :hints (("Goal"
             :in-theory (disable rlp-bytes-encoding-p-suff)
             :use ((:instance rlp-bytes-encoding-p-suff
                    (bytes (rlp-bytes-encoding-witness (byte-list-fix encoding))))
                   (:instance rlp-bytes-encoding-p-suff
                    (bytes (rlp-bytes-encoding-witness encoding))
                    (encoding (byte-list-fix encoding)))))))

  (defruled rlp-tree-encoding-p-when-rlp-bytes-encoding-p
    (implies (rlp-bytes-encoding-p encoding)
             (rlp-tree-encoding-p encoding))
    :use (:instance rlp-tree-encoding-p-suff
          (tree (rlp-tree-leaf (rlp-bytes-encoding-witness encoding))))
    :enable rlp-encode-tree))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-sk rlp-scalar-encoding-p ((encoding byte-listp))
  :returns (yes/no booleanp)
  :parents (rlp-encoding)
  :short "Check if a byte array is an RLP encoding of a scalar."
  :long
  (xdoc::topp
   "This is analogous to @(tsee rlp-tree-encoding-p).")
  (exists (nat)
          (and (natp nat)
               (b* (((mv nat-error? nat-bytes) (rlp-encode-scalar nat)))
                 (and (not nat-error?)
                      (equal nat-bytes (byte-list-fix encoding))))))
  :skolem-name rlp-scalar-encoding-witness
  ///

  (fty::deffixequiv rlp-scalar-encoding-p
    :args ((encoding byte-listp))
    :hints (("Goal"
             :in-theory (disable rlp-scalar-encoding-p-suff)
             :use ((:instance rlp-scalar-encoding-p-suff
                    (nat (rlp-scalar-encoding-witness
                          (byte-list-fix encoding))))
                   (:instance rlp-scalar-encoding-p-suff
                    (nat (rlp-scalar-encoding-witness encoding))
                    (encoding (byte-list-fix encoding))))))))