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

This egg requires nanomsg-0.4-beta.

## Development Status
These bindings are incomplete. If you're missing something, please
create github issues!

Currently supported:

- nn-socket (which finalizer closes), nn-bind, nn-connect and nn-close
- nn-send
- non-blocking nn-recv returning strings
- nn-subscribe

Favored TODO's:
- all socket types (pair, push, pull)
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
