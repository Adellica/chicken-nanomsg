(use nanomsg test)

(define (wait) (thread-sleep! 0.1))
(define pair1 (nn-socket 'pair))
(define pair2 (nn-socket 'pair))
(nn-bind    pair1 "inproc://test36")

(test "connections 0" 0 (nn-get-statistic pair1 'current-connections))
(nn-connect pair2 "inproc://test36") (wait)
(test "connections 1" 1 (nn-get-statistic pair1 'current-connections))

(nn-send pair1 "test message") (wait)
(test "receive" "test message" (nn-recv pair2))

(test "messages-sent"      1 (nn-get-statistic pair1 'messages-sent))
(test "messages-received"  1 (nn-get-statistic pair2 'messages-received))
(test "bytes-sent"        12 (nn-get-statistic pair1 'bytes-sent))
