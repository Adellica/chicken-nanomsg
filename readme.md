chicken-nanomsg
===============

 [Chicken Scheme]: http://call-cc.org/
 [nanomsg]: http://nanomsg.org/

[Chicken Scheme] bindings for the lightweight ZMQ-alternative,
[nanomsg]. There
[exists Chicken ZMQ bindings](http://api.call-cc.org/doc/zmq), but
this turned out to be a little troublesome with zmq_poll blocking
other srfi-18 threads.

## Why nanomsg

Nanomsg is smaller, written in C, has a simplified API (sockets are
simple ints), no multipart messages, and has explicit support for poll
on a socket's recv file-descriptor.

## Requirements

Version `1.0.0.2` of this egg requires
[nanomsg-1.0.0](https://github.com/nanomsg/nanomsg/releases/tag/1.0.0).

## API

    [procedure] (nn-socket protocol [domain])

[Create](http://nanomsg.org/v1.0.0/nn_socket.3.html) a nanomsg
socket. Protocol can be any of the symbols `pair`, `pub`, `sub`,
`pull`, `push`, `req`, `rep`, `surveyor`, `respondent` or
`bus`. Domain can be the symbol `sp` or `sp-raw`, and defaults to
`sp`.

    [procedure] (nn-bind socket address)

[Binds](http://nanomsg.org/v1.0.0/nn_bind.3.html) nanomsg socket to
address, where address is a string of the form
`"ipc:///var/ipc/music.nn.pair"` or `"tcp://0.0.0.0:10080"`. If the
nn-library can't parse the address string, it throws an "Illegal
argument" error.

    [procedure] (nn-connect socket address)

[Connects](http://nanomsg.org/v1.0.0/nn_connect.3.html) nanomsg socket
`socket` to `address`.

    [procedure] (nn-subscribe socket prefix)

Set the [NN_SUB_SUBSCRIBE](http://nanomsg.org/v1.0.0/nn_pubsub.7.html)
option on `socket` which will make the socket receive to all messages
that start with `prefix`.

> Note that if this is never called, `(nn-sock 'sub)` sockets will
> never receive anything.

    [procedure] (nn-send socket msg)

Send a message on `socket`, using the socket's semantics. `msg` must
be a string. This will not block other srfi-18 threads. Returns the
number of bytes sent.

    [procedure] (nn-send* socket msg flags)

Like `nn-send`, but may block other srfi-18 threads when `flags` is
`0`. `flags` may be `nn/dontwait` in which case `nn-send*` always
returns immediately, and returns `#f` is the operation would block
(number of bytes otherwise).

    [procedure] (nn-recv socket)

Receive a message from socket. This blocks until a message is received
from nanomsg, but it does not block other srfi-18 threads. It always
returns a string. An error is thrown if the socket is in an illegal
state.

> Note that memory is copied from the nanomsg buffer into a new scheme
> string.

    [procedure] (nn-recv* socket flags)

Receive a message from socket. This will block other srfi-18 threads,
unless the `nn/dontwait` flag is specified, in which case `nn-recv*`
will exit immediately with either a message as a string or #f (for
`EAGAIN`). An error is thrown if `socket` is in an illegal state.

> Note that this can be combined with `(nn-socket-rcvfd socket)` for
> custom polling.

    [procedure] (nn-close socket)

Explicitly close `socket`. This is normally not needed as this is done
in the socket's finalizer.

    [procedure] (nn-shutdown socket endpoint)

Removed `endpoint` from `socket`.
See [nn_shutdown](http://nanomsg.org/v1.0.0/nn_shutdown.3.html).

    [procedure] (nn-get-statistic socket statistic)

Retrieve a statistic from `socket`. `statistic` may be any one of
these symbols: `established-connections` `accepted-connections`
`dropped-connections` `broken-connections` `connect-errors`
`bind-errors` `accept-errors` `current-connections`
`inprogress-connections` `current-ep-errors` `messages-sent`
`messages-received` `bytes-sent` `bytes-received`
`current-snd-priority`. See
[nn_get_statistic](http://nanomsg.org/v1.0.0/nn_get_statistic.3.html).

    [procedure] (nn-socket-name socket)
    [procedure] (nn-socket-linger socket)
    [procedure] (nn-socket-rcvtimeo socket)
    [procedure] (nn-socket-sndtimeo socket)
    [procedure] (nn-socket-rcvbuf socket)
    [procedure] (nn-socket-sndbuf socket)
    [procedure] (nn-socket-sndfd socket)
    [procedure] (nn-socket-rcvfd socket)
    [procedure] (nn-socket-protocol socket)
    [procedure] (nn-socket-domain socket)
    [procedure] (nn-socket-maxttl socket)
    [procedure] (nn-socket-rcvmaxsize socket)
    [procedure] (nn-socket-rcvprio socket)
    [procedure] (nn-socket-sndprio socket)
    [procedure] (nn-socket-reconnect-ivl-max socket)
    [procedure] (nn-socket-reconnect-ivl socket)
    [procedure] (nn-socket-ipv4only socket)
    [procedure] (nn-req-socket-resend-ivl socket)

Retrieve the socket option associated with `socket`. Most of these
also provide setters so that you can, for example, can do `(set!
(nn-socket-name s) "foo")`.

For other socket options, try `nn-getsockopt/string`,
`nn-getsockopt/int`, `nn-setsockopt/string` and `nn-setsockopt/int`.

## Development Status

These bindings to nanomsg 1.0.0 should be fairly complete, the only
missing functionality is the control messages (`nn_recvmsg`,
`nn_sendmsg` and `nn_cmsg`). Also, note that the egg hasn't undergode
rigerous testing int the field yet.

## Sample

```scheme
;; test.scm
(use nanomsg)

(define s (nn-socket 'rep))
(nn-bind s "tcp://127.0.0.1:22022")

(let loop ((n 0))
  (nn-send s (conc (nn-recv s) " " n))
  (loop (add1 n)))

(nn-close s)
```

then test with the brilliant `nanocat` util that comes with [nanomsg]:


```bash
$ csi -s test.scm &
$ nanocat --req -l22022 -D"bottles of beer:" -A --interval 1
```
