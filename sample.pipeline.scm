;; watch nanomsg's pipeline load-balancer in action.
(use nanomsg)

(define push (nn-socket 'push))
(define pull1 (nn-socket 'pull))
(define pull2 (nn-socket 'pull))

(nn-bind    push  "inproc://test")
(nn-connect pull1 "inproc://test")
(nn-connect pull2 "inproc://test")

(nn-send push "a")
(nn-send push "b")
(nn-send push "c")
(nn-send push "d")

(define ((th sock))
  (print (current-thread) ": " (nn-recv sock))
  (print (current-thread) ": " (nn-recv sock))
  (print (current-thread) " is done"))

(thread-start! (th pull1))
(thread-start! (th pull2))

(thread-sleep! 1)
