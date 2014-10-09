(use lolevel foreigners)

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

(define (nn-assert val)
  (if (< val 0)
      (error (nn-strerror) val)
      val))

;; int nn_socket (int domain, int protocol)
;; OBS: args reversed
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

;; return the next message as a string.
(define (nn-recv socket #!optional (flags 0))
   ;; make a pointer which nanomsg will point to its newly allocated
   ;; message
  (let-location
   ((dst (c-pointer void) #f))
   (let* ((size (nn-recv! socket (location dst) (foreign-value "NN_MSG" int) flags))
          (blb (make-string size)))
     (move-memory! dst blb size)
     (nn-freemsg! dst)
     blb)))

;; TODO: support nn_sendmsg and nn_recvmsg?
