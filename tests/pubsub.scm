;; TODO: can't get unsubscribe working
(cond-expand
 (chicken-5
  (import nanomsg test (only srfi-18 thread-sleep!)))
 (else (use nanomsg test (only srfi-18 thread-sleep!))))

(define (wait) (thread-sleep! 0.1))
(define sub (nn-socket 'sub))
(define pub (nn-socket 'pub))

(nn-bind    sub "inproc://test")
(nn-connect pub "inproc://test")

(nn-send pub "ignored 1") (wait)

(nn-subscribe sub "prefix1")
(nn-subscribe sub "prefix2")

(nn-send pub "ignored 2")     (wait)
(nn-send pub "prefix1 hello") (wait)
(nn-send pub "prefix2 hi")    (wait)
(nn-send pub "prefix1 last")  (wait)

(test "subscribe" "prefix1 hello"  (nn-recv sub))
(test "subscribe" "prefix2 hi"        (nn-recv sub))
(test "subscribe" "prefix1 last" (nn-recv sub))
