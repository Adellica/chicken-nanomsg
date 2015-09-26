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

This egg requires nanomsg-[0.4|0.5|0.6]-beta.

## API

    [procedure] (nn-socket protocol [domain])

Create a nanomsg socket. Protocol can be any of the symbols pair, pub,
sub, pull, push, req, rep, surveyor, respondent or bus. Domain can be
the symbol sp or raw, and defaults to sp.

    [procedure] (nn-bind socket address)

[Binds](http://nanomsg.org/v0.6/nn_bind.3.html) nanomsg socket to
address, where address is a string of the form
"ipc:///var/ipc/music.nn.pair" or "tcp://0.0.0.0:10080". If the
nn-library can't parse the address string, it throws an "Illegal
argument" error.

    [procedure] (nn-connect socket address)

[Connects](http://nanomsg.org/v0.6/nn_connect.3.html) nanomsg socket
`socket` to `address`.

    [procedure] (nn-subscribe socket prefix)

Set the [NN_SUB_SUBSCRIBE](http://nanomsg.org/v0.6/nn_pubsub.7.html)
option on `socket` which will make the socket receive to all messages
that start with `prefix`. Note that if this is never called, `(nn-sock
'sub)` sockets will never receive anything.

    [procedure] (nn-recv socket)

Receive a message from socket. This blocks until a message is received
from nanomsg, but it does not block other srfi-18 threads. It always
returns a string. An error is thrown if the socket is in an illegal
state.

    [procedure] (nn-send socket msg)

Send a message on `socket`, using the socket's semantics. `msg` must
be a string.

In the current implementation, this operation may block for certain
protocols in which case other srfi-18 threads block too.

    [procedure] (nn-recv* socket flags)

Receive a message from socket. This will block other srfi-18 threads,
unless the `nn/dontwait` flag is specified, in which case `nn-recv*`
will immediately with either a message as a string or #f (for
EAGAIN). An error is thrown if `socket` is in an illegal state.

Note that memory is copied from the nanomsg buffer into a new scheme
string.

    [procedure] (nn-recv! socket buffer size flags)

A version of `nn-recv*` which requires a preallocated buffer. If the
size of the buffer can be found automatically (using
`number-of-bytes`), size can be `#f`.

    [procedure] (nn-close socket)

Explicitly close `socket`. This is normally not needed as this is done
in the socket's finalizer.

## Development Status

These bindings are incomplete, but all protocols and transport types
should be supported. However, socket options (`nn_setsockopt` and
`nn_getsockopt`) aren't supported with the exception of
`nn-subscribe`. Patches are welcome!

Favored TODO's:
- support socket options
- bundle nanomsg itself?

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
