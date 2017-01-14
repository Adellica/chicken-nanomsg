(use lolevel foreigners srfi-18)

#>
#include <nanomsg/nn.h>
#include <nanomsg/pipeline.h>
#include <nanomsg/pubsub.h>
#include <nanomsg/reqrep.h>
#include <nanomsg/survey.h>
#include <nanomsg/pair.h>
#include <nanomsg/bus.h>

#include <nanomsg/inproc.h>
#include <nanomsg/ipc.h>
#include <nanomsg/tcp.h>
#include <nanomsg/ws.h>
<#

;; TODO: socket options NN_SUB_SUBSCRIBE NN_SUB_UNSUBSCRIBE

(define-record-type nn-socket (%nn-socket-box int)
  nn-socket?
  (int %nn-socket-unbox))

(define-foreign-type nn-socket int
  %nn-socket-unbox
  %nn-socket-box)

(define-record-type nn-endpoint (%nn-endpoint-box int)
  nn-endpoint?
  (int %nn-endpoint-unbox))

(define-foreign-type nn-endpoint int
  %nn-endpoint-unbox
  %nn-endpoint-box)

;; nanomsg protocol enum
(define-foreign-enum-type (nn-protocol int)
  (nn-protocol->int int->nn-protocol)

  (pair NN_PAIR)
  (pub  NN_PUB)  (sub  NN_SUB)
  (pull NN_PULL) (push NN_PUSH)
  (req  NN_REQ)  (rep  NN_REP)
  (surveyor NN_SURVEYOR)  (respondent NN_RESPONDENT)
  (bus NN_BUS))

(define-foreign-enum-type (nn-option-level int)
  (nn-option-level->int int->nn-option-level)
  (sol-socket NN_SOL_SOCKET)

  ;; ==================== copy of nn-protocol
  (pair NN_PAIR)
  (pub  NN_PUB)  (sub  NN_SUB)
  (pull NN_PULL) (push NN_PUSH)
  (req  NN_REQ)  (rep  NN_REP)
  (surveyor NN_SURVEYOR)  (respondent NN_RESPONDENT)
  (bus NN_BUS)

  ;; ==================== copy of nn-transport
  (inproc NN_INPROC)
  (ipc    NN_IPC)
  (tcp    NN_TCP)
  (ws     NN_WS))

;; socket-level options for sol-socket . there are additional ones
;; per-transport and per-protocol.
(define-foreign-enum-type (nn-option int 0)
  (nn-option->int int->nn-option)

  (linger            NN_LINGER)
  (sndbuf            NN_SNDBUF)
  (rcvbuf            NN_RCVBUF)
  (sndtimeo          NN_SNDTIMEO)
  (rcvtimeo          NN_RCVTIMEO)
  (reconnect-ivl     NN_RECONNECT_IVL)
  (reconnect-ivl-max NN_RECONNECT_IVL_MAX)
  (sndprio           NN_SNDPRIO)
  (rcvprio           NN_RCVPRIO)
  (sndfd             NN_SNDFD)
  (rcvfd             NN_RCVFD)
  (domain            NN_DOMAIN)
  (protocol          NN_PROTOCOL)
  (ipv4only          NN_IPV4ONLY)
  (socket-name       NN_SOCKET_NAME)
  (rcvmaxsize        NN_RCVMAXSIZE)
  (maxttl            NN_MAXTTL)

  (tcp-nodelay NN_TCP_NODELAY) ;; option-level == NN_TCP level

  (surveyor-deadline NN_SURVEYOR_DEADLINE) ;; NN_SURVEYOR ;; int
  (sub-subscribe NN_SUB_SUBSCRIBE) ;; NN_SUB string
  (sub-unsubscribe NN_SUB_UNSUBSCRIBE) ;; NN_SUB string
  (ws-msg-type NN_WS_MSG_TYPE) ;; NN_WS ;; int => NN_WS_MSG_TYPE_TEXT or NN_WS_MSG_TYPE_BINARY

  )

;; nanomsg domain (AF_SP)
(define-foreign-enum-type (nn-domain int)
  (nn-domain->int int->nn-domain)
  (sp AF_SP)
  (sp-raw AF_SP_RAW))

;; ==================== socket flags

(define nn/dontwait           (foreign-value "NN_DONTWAIT" int))
(define nn/ws-msg-type-text   (foreign-value "NN_WS_MSG_TYPE_TEXT" int))
(define nn/ws-msg-type-binary (foreign-value "NN_WS_MSG_TYPE_BINARY" int))
;; TODO: test NN_WS_MSG_TYPE

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

;; turn 'linger into NN_LINGER etc (allow fixnums too, for a custom
;; nanomsg build)
(define (%nn-optionize option)
  (cond ((symbol? option) (nn-option->int option))
        ((fixnum? option) option)
        (else (error "invalid option" option))))

;; turn 'pair -> NN_PAIR etc
(define (%nn-levelize level)
  (cond ((symbol? level) (nn-option-level->int level))
        ((fixnum? level) level)
        (else (error "invalid option-level" level))))

;; overwrite destination (may be "") with the value of the
;; option. returns the length of the original data.
(define (nn-getsockopt/string! socket level option destination)
  (assert (or (blob? destination) (string? destination)))
  (assert (and (fixnum? level) (fixnum? option)))
  (let-location
   ( (dst_size size_t (number-of-bytes destination)) )
   (nn-assert
    ((foreign-lambda*
      int ( (nn-socket socket)
            (int level) (int option)
            (nonnull-scheme-pointer buffer)
            ((c-pointer size_t) dst_size))
      "return(nn_getsockopt(socket, level, option, buffer, dst_size));")
     socket level option destination (location dst_size)))
   dst_size))

(define (nn-getsockopt/string socket level option)
  (let* ((level (%nn-levelize level)) (option (%nn-optionize option))
         (len (nn-getsockopt/string! socket level option ""))
         (res (make-string len)))
    (nn-getsockopt/string! socket level option res)
    res))

(define (nn-getsockopt/int socket level option)
  (let ((level (%nn-levelize level)) (option (%nn-optionize option)))
    (let-location
     ( (dst int)
       (dst_size int (foreign-value "sizeof(int)" int)) )
     (nn-assert
      ((foreign-lambda* int ( (nn-socket socket)
                              (int level) (int option)
                              ((c-pointer int) dst)
                              ((c-pointer size_t) dst_size))
                        "return(nn_getsockopt(socket, level, option, dst, dst_size));")
       socket level option (location dst) (location dst_size)))
     (if (not (= (foreign-value "sizeof(int)" int) dst_size))
         (error "invalid nn_getsockopt destination storage size" dst_size)
         dst))))

(define (nn-setsockopt/string socket level option value)
  (assert (or (blob? value) (string? value)))
  (let ((level (%nn-levelize level)) (option (%nn-optionize option)))
   (nn-assert
    ((foreign-lambda*
      int ( (nn-socket socket)
            (int level) (int option)
            (nonnull-scheme-pointer blob)
            (int len))
      "return(nn_setsockopt(socket, level, option, blob, len));")
     socket level option value (number-of-bytes value)))))

(define (nn-setsockopt/int socket level option value)
  (assert (fixnum? value))
  (let ((level (%nn-levelize level)) (option (%nn-optionize option)))
    (nn-assert
     ((foreign-lambda*
       int ( (nn-socket socket)
             (int level) (int option)
             (int value))
       "return(nn_setsockopt(socket, level, option, &value, sizeof(value)));")
      socket level option value))))

(define (nn-setsockopt socket level option value)
  (let ((level (%nn-levelize level)) (option (%nn-optionize option)))
    (cond ((string? value) (nn-setsockopt/string socket level option value))
          ((fixnum? value) (nn-setsockopt/string socket level option value))
          (else (error "unhandled type for setsockopt" value)))))

;; ==================== convenience socket options ====================
(define-syntax define-nn-so
  (syntax-rules ()
    ((_ name level option get)
     (define name (lambda (s) (get s level option))))
    ((_ name level option get set)
     (define name
       (getter-with-setter
        (lambda (s) (get s level option))
        (lambda (s v) (set s level option v)))))))

(define-syntax define-nn-so-int ;; int sol-socket
  (syntax-rules (set)
    ((_ name level option)
     (define-nn-so name 'sol-socket option nn-getsockopt/int))
    ((_ name level option set)
     (define-nn-so name 'sol-socket option nn-getsockopt/int nn-setsockopt/int))))

(define-nn-so nn-socket-domain   'sol-socket 'domain
  (compose int->nn-domain nn-getsockopt/int))
(define-nn-so nn-socket-protocol 'sol-socket 'protocol
  (compose int->nn-protocol nn-getsockopt/int))
(define-nn-so nn-socket-name     'sol-socket 'socket-name
  nn-getsockopt/string nn-setsockopt/string)

(define-nn-so-int nn-socket-rcvfd             'sol-socket 'rcvfd)
(define-nn-so-int nn-socket-sndfd             'sol-socket 'sndfd)
(define-nn-so-int nn-socket-linger            'sol-socket 'linger set)
(define-nn-so-int nn-socket-sndbuf            'sol-socket 'sndbuf set)
(define-nn-so-int nn-socket-rcvbuf            'sol-socket 'rcvbuf set)
(define-nn-so-int nn-socket-sndtimeo          'sol-socket 'sndtimeo set)
(define-nn-so-int nn-socket-rcvtimeo          'sol-socket 'rcvtimeo set)
(define-nn-so-int nn-socket-reconnect-ivl     'sol-socket 'reconnect-ivl set)
(define-nn-so-int nn-socket-reconnect-ivl-max 'sol-socket 'reconnect-ivl-max set)
(define-nn-so-int nn-socket-sndprio           'sol-socket 'sndprio set)
(define-nn-so-int nn-socket-rcvprio           'sol-socket 'rcvprio set)
(define-nn-so-int nn-socket-ipv4only          'sol-socket 'ipv4only set)
(define-nn-so-int nn-socket-rcvmaxsize        'sol-socket 'rcvmaxsize set)
(define-nn-so-int nn-socket-maxttl            'sol-socket 'maxttl set)

(define (nn-subscribe socket prefix)
  (nn-setsockopt/string socket 'sub 'sub-subscribe prefix))
(define (nn-unsubscribe socket prefix)
  (nn-setsockopt/string socket 'sub 'sub-unsubscribe prefix))

;; TODO: wrappers for NN_WS_MSG_TYPE and NN_TCP_NODELAY ?

;; ====================

(define (nn-close socket)
  (nn-assert ( (foreign-lambda int "nn_close" nn-socket) socket)))

(define (nn-shutdown socket endpoint)
  (nn-assert ( (foreign-lambda int "nn_shutdown" nn-socket nn-endpoint)
               socket endpoint)))

;; int nn_socket (int domain, int protocol)
;; OBS: args reversed
;; TODO: add finalizer
(define (nn-socket protocol #!optional (domain 'sp))
  (set-finalizer!
   (%nn-socket-box
    (nn-assert ((foreign-lambda int nn_socket nn-domain nn-protocol)
                domain
                protocol)))
   nn-close))

(define (nn-bind socket address)
  (%nn-endpoint-box
   (nn-assert
    ((foreign-lambda int "nn_bind" nn-socket c-string) socket address))))

(define (nn-connect socket address)
  (%nn-endpoint-box
   (nn-assert
    ((foreign-lambda int "nn_connect" nn-socket c-string) socket address))))

(define (nn-freemsg! pointer)
  (nn-assert ( (foreign-lambda int "nn_freemsg" (c-pointer void)) pointer)))

(define (nn-send socket data #!optional (flags 0))
  (nn-assert ( (foreign-lambda int "nn_send" nn-socket blob int int)
              socket data (number-of-bytes data) flags)))

(define (nn-recv! socket data size flags)
  (nn-assert ( (foreign-lambda int "nn_recv" nn-socket (c-pointer void) int int)
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
          (thread-wait-for-i/o! (nn-socket-rcvfd socket) #:input)
          (loop)))))

;; TODO: support nn_sendmsg and nn_recvmsg?
;;
;; example scenario: you want to prefix all messages before sending
;; for routing for purposes. now you'll have to (string-append prefix
;; large-message) which is a lot of string-copying (right?). nn-send
;; could perhaps also accept a list of strings which handled the
;; memory efficiently.

;; OBS: blocks other srfi-13 threads
(define (nn-device s1 s2)
  (nn-assert ((foreign-lambda int "nn_device" nn-socket nn-socket) s1 s2)))

(define nn-term
  (foreign-lambda void "nn_term"))


;; ==================== statistics ====================
(define-foreign-enum-type (nn-statistic int)
  (nn-statistic->int int->nn-statistic)

  (established-connections NN_STAT_ESTABLISHED_CONNECTIONS)
  (accepted-connections    NN_STAT_ACCEPTED_CONNECTIONS)
  (dropped-connections     NN_STAT_DROPPED_CONNECTIONS)
  (broken-connections      NN_STAT_BROKEN_CONNECTIONS)
  (connect-errors          NN_STAT_CONNECT_ERRORS)
  (bind-errors             NN_STAT_BIND_ERRORS)
  (accept-errors           NN_STAT_ACCEPT_ERRORS)
  (current-connections     NN_STAT_CURRENT_CONNECTIONS)
  (inprogress-connections  NN_STAT_INPROGRESS_CONNECTIONS)
  (current-ep-errors       NN_STAT_CURRENT_EP_ERRORS)
  (messages-sent           NN_STAT_MESSAGES_SENT)
  (messages-received       NN_STAT_MESSAGES_RECEIVED)
  (bytes-sent              NN_STAT_BYTES_SENT)
  (bytes-received          NN_STAT_BYTES_RECEIVED)
  (current-snd-priority    NN_STAT_CURRENT_SND_PRIORITY))

(define (nn-get-statistic socket statistic)
  (let-location
   ((ok int 0))
   (let ((result
          ((foreign-lambda*
            unsigned-integer64 ( (nn-socket socket)
                                 (nn-statistic stat)
                                 ((c-pointer int) ok) )
            "uint64_t res = nn_get_statistic(socket, stat);"
             ;; can't represent (uint64_t)-1 with 52 bits:
             ;; http://api.call-cc.org/doc/foreign/types/unsigned-integer64
            "if(res != (uint64_t)-1) *ok = 1;"
            "return(res);")
           socket statistic (location ok))))
     (if (= ok 1)
         result
         (error (nn-strerror) statistic)))))

