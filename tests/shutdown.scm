(use nanomsg test)

(define (wait) (thread-sleep! 0.1))

(define s1 (nn-socket 'bus))
(define s2 (nn-socket 'bus))

(define c1a (nn-bind    s1 "inproc://test-shutdown"))
(define c2a (nn-connect s2 "inproc://test-shutdown"))

(nn-send s2 "one")
(test "setup" "one" (nn-recv s1))

(nn-shutdown s1 c1a) ;; tear down

(nn-send s2 "ignored because endpoint is down ;-)")
(nn-bind s1 "inproc://test-shutdown") ;; bring s1 back up
(nn-send s2 "back online")

(test "back online" (nn-recv s1))

