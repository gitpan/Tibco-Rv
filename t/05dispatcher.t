$^W = 0;

use Tibco::Rv;

print "1..1\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
# two independent dispatchers doing send/recv
# main loop listening on intraprocess transport, stop on timeout
( 1 ) ? &ok : &nok;

__DATA__
TODO
Rv:
createTransport
createQueue
sendReply
sendRequest
createInbox
QueueGroup:
add
remove
Dispatcher:
name
dispatchable
idleTimeout
Status:
toString
toNum
Queue:
hook
count
name
limitPolicy/priority?
Transport:
description
batchMode
