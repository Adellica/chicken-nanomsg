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

This egg is (poorly) tested against nanomsg-0.4-beta.

## Development Status
These bindings are incomplete. If you're missing something, please
create github issues.

Currently supported:

- nn-socket, nn-bind, nn-connect and nn-close (must close explicitly!)
- nn-send
- non-blocking nn-recv returning strings
- nn-subscribe

Favored TODO's:
- all socket types (pair, push, pull)
- nn-socket record with nn-close in finalizer
