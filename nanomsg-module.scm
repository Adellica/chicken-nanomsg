
(module nanomsg (;; types
                 nn-endpoint? nn-socket?

                 nn-domain->int int->nn-domain
                 nn-option->int int->nn-option
                 nn-option-level->int int->nn-option-level
                 nn-protocol->int int->nn-protocol
                 nn-statistic->int int->nn-statistic

                 nn-term nn-device
                 nn-recv nn-recv* nn-recv!
                 nn-send nn-send*
                 ;; nn-freemsg!
                 nn-connect nn-bind
                 nn-socket nn-socket*  nn-shutdown nn-close

                 nn-unsubscribe nn-subscribe

                 ;; socket options
                 nn-setsockopt nn-setsockopt/int nn-getsockopt/int
                 nn-setsockopt/string nn-getsockopt/string nn-getsockopt/string!

                 ;; socket option wrappers
                 nn-socket-name nn-socket-linger
                 nn-socket-rcvtimeo nn-socket-sndtimeo
                 nn-socket-rcvbuf nn-socket-sndbuf
                 nn-socket-sndfd nn-socket-rcvfd
                 nn-socket-protocol nn-socket-domain
                 nn-socket-maxttl nn-socket-rcvmaxsize
                 nn-socket-rcvprio nn-socket-sndprio
                 nn-socket-reconnect-ivl-max nn-socket-reconnect-ivl
                 nn-socket-ipv4only
                 nn-req-socket-resend-ivl

                 ;; flags
                 nn/ws-msg-type-binary
                 nn/ws-msg-type-text
                 nn/dontwait

                 ;; util
                 nn-get-statistic)
(import scheme) ;; make sure we have cond-expand
(cond-expand
 (chicken-5 (import (chicken base) (chicken foreign)))
 (else (import chicken foreign)))

(include "nanomsg.scm")
)
