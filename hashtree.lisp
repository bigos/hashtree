(declaim (optimize (speed 0) (safety 2) (debug 3)))

(in-package #:hashtree)

(defun init-hash (parent-hash current-hash key)
  "Return CURRENT-HASH initialised with default values."
  (unless (zerop (hash-table-count current-hash))
    (error "You can only init empty hash-table, we have key ~S" (gethash :. current-hash)))
  (setf (gethash :.. current-hash) parent-hash
        (gethash :.  current-hash) key)
  current-hash)

(defun hashtree-tablep (current-hash key)
  (let ((hash (gethash key current-hash)))
    (and (typep hash 'hash-table)
         (typep (gethash :. hash) 'keyword)
         (typep (gethash :.. hash) 'hash-table))))

(defun the-hash (key current-hash)
  (cond
    ((equal :. key)
     current-hash)
    (t
     (gethash key current-hash))))

(defun (setf the-hash) (value key current-hash)
  (when (or (eql :. key)
            (eql :.. key))
    (error "You can not set ~S" key))
  (progn
     (setf (gethash key current-hash) value)
     value))

(defun hash-add (hash key value)
  (when (typep value 'hash-table)
    (unless (hashtree-tablep hash key)
      (init-hash hash value key)))
  (setf (the-hash key hash) value))

(defun hash-init-root ()
  (init-hash nil (make-hash-table :test #'equal) :/))

(defun hash-set-path (hash keys value)
  (if (null (cdr keys))
      (setf (the-hash (car keys) hash) value)
      (hash-set-path
       (alexandria:ensure-gethash (car keys)
                                  hash
                                  (init-hash hash
                                             (make-hash-table :test #'equal)
                                             (car keys)))
       (cdr keys)
       value)))

(defun hash-get-path (hash keys)
  "Return HASH or value that can be traversed from HASH using the KEYS."
  (if (endp keys)
      hash
      (hash-get-path (the-hash (first keys) hash) (rest keys))))

(defun hash-parent (current-hash)
  (gethash :.. current-hash))

(defun hash-current (current-hash)
  (gethash :. current-hash))

(defun parent-hash-table-alist (table)
  "Returns an association list containing the keys and values of hash table
  TABLE replacing parent table with 'parent."
  (loop for k being the hash-key in table
        collect (cons k
                      (if (eql k :..)
                          'parent
                          (gethash k table)))))

;;; this causes problems with big hashes
;; (defmethod print-object ((obj hash-table)  stream)
;;   (print-unreadable-object (obj stream :type t)
;;     (format stream "~S"
;;           (parent-hash-table-alist obj))))

(defun test-me ()
  (format t "~&Testing hashtree~%")

  (let* ((root-hash (hash-init-root))
         (current-hash root-hash))
    (assert (typep current-hash 'hash-table))

    (hash-add current-hash :a "a")
    (hash-set-path current-hash '(:b) "b")
    (assert (equal (parent-hash-table-alist root-hash)
                   '((:|..| . PARENT) (:|.| . :/) (:A . "a") (:B . "b"))))

    (hash-set-path current-hash '(:c :c) "c")
    (assert (hashtree-tablep current-hash :c))
    (assert (equal (parent-hash-table-alist
                    (hash-get-path root-hash '(:c)))
                   '((:|..| . PARENT) (:|.| . :C) (:C . "c"))))

    (hash-set-path current-hash '(:c :d :d) "d")
    (assert (equal (parent-hash-table-alist
                    (hash-get-path root-hash '(:c :d)))
                   '((:|..| . PARENT) (:|.| . :D) (:D . "d"))))

    (format t "zzzz ~S~%"
            (hash-get-path root-hash '(:c :d :d)))
    root-hash))
