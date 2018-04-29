(cond-expand
 (chicken-5 (import test))
 (else      (use test)))
(test-group "sockopts" (include "sockopts.scm"))
(test-group "pubsub"   (include "pubsub.scm"))
(test-group "stats"    (include "stats.scm"))
(test-group "shutdown" (include "shutdown.scm"))
