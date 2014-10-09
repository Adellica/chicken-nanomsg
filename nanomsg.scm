(use lolevel foreigners srfi-18)

#>
#include <nanomsg/nn.h>
#include <nanomsg/pipeline.h>
#include <nanomsg/pubsub.h>
#include <nanomsg/reqrep.h>
<#

;; TODO: socket options NN_SUB_SUBSCRIBE NN_SUB_UNSUBSCRIBE

;; nanomsg protocol enum
(define-foreign-enum-type (nn-protocol int)
  (nn-protocol->int int->nn-protocol)

  (pub  NN_PUB)  (sub  NN_SUB)
  (pull NN_PULL) (push NN_PUSH)
  (req  NN_REQ)  (rep  NN_REP))

;; nanomsg domain (AF_SP)
(define-foreign-enum-type (nn-domain int)
  (nn-domain->int int->nn-domain)
  (sp AF_SP)
  (raw AF_SP_RAW))

;; ==================== socket flags

(define nn/dontwait (foreign-value "NN_DONTWAIT" int))

(define (nn-strerror #!optional (errno (foreign-value "errno" int)))
  ((foreign-lambda c-string "nn_strerror" int) errno))

;; let val pass unless it is negative, in which case gulp with the nn
;; error-string. on EAGAIN, return #f.
(define (nn-assert val)
  (if (< val 0)
      (if (= (foreign-value "errno" int)
             (foreign-value "EAGAIN" int))
          #f ;; signal EGAIN with #f, other errors will throw
          (error (nn-strerror) val))
      val))


;; get the pollable fd for socket.
(define (nn-recv-fd socket)
  (let-location ((fd int -1)
                 (fd_size int (foreign-value "sizeof(int)" int)))
                (nn-assert
                 ((foreign-lambda* int ( (int socket)
                                    ((c-pointer int) fd)
                                    ((c-pointer int) fds))
                              "return(nn_getsockopt(socket, NN_SOL_SOCKET, NN_RCVFD, fd, fds));")
                  socket (location fd) (location fd_size)))
                (if (not (= (foreign-value "sizeof(int)" int) fd_size))
                    (error "invalid nn_getsockopt destination storage size" fd_size))
                fd))

;; int nn_socket (int domain, int protocol)
;; OBS: args reversed
;; TODO: add finalizer
(define (nn-socket protocol #!optional (domain 'sp))
  (nn-assert ((foreign-lambda int nn_socket nn-domain nn-protocol)
              domain
              protocol)))

(define (nn-close socket)
  (nn-assert ( (foreign-lambda int "nn_close" int) socket)))

(define (nn-bind socket address)
  (nn-assert ((foreign-lambda int "nn_bind" int c-string) socket address)))

(define (nn-connect socket address)
  (nn-assert ((foreign-lambda int "nn_connect" int c-string) socket address)))

(define (nn-freemsg! pointer)
  (nn-assert ( (foreign-lambda int "nn_freemsg" (c-pointer void)) pointer)))

(define (nn-send socket data #!optional (flags 0))
  (nn-assert ( (foreign-lambda int "nn_send" int blob int int)
              socket data (number-of-bytes data) flags)))

(define (nn-recv! socket data size flags)
  (nn-assert ( (foreign-lambda int "nn_recv" int (c-pointer void) int int)
              socket data (or size (number-of-bytes data)) flags)))

;; plain nn-recv, will read-block other srfi-18 threads unless
;; nn/dontwait flag is specified. returns the next message as a
;; string.
(define (nn-recv* socket #!optional (flags 0))
  ;; make a pointer which nanomsg will point to its newly allocated
  ;; message
  (let-location
   ((dst (c-pointer void) #f))
   (and-let* ((size (nn-recv! socket (location dst) (foreign-value "NN_MSG" int) flags))
              (blb (make-string size)))
     (move-memory! dst blb size)
     (nn-freemsg! dst)
     blb)))

;; wait for message on socket, return it as string. does not block
;; other srfi-18 threads.
(define (nn-recv socket)
  (let loop ()
    ;; make a non-blocking attempt first, and if we get EAGAIN (#f),
    ;; wait and retry. let's give nn a chance to error with
    ;; something other than EAGAIN before waiting for i/o. for
    ;; example, nn-recv on PUB socket would block infinitely
    (or (nn-recv* socket nn/dontwait)
        (begin
          ;; is getting the fd an expensive operation?
          (thread-wait-for-i/o! (nn-recv-fd socket) #:input)
          (loop)))))

;; TODO: support nn_sendmsg and nn_recvmsg?
