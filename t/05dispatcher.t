$^W = 0;

use Tibco::Rv;

print "1..3\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
# two independent dispatchers doing send/recv
# main loop listening on intraprocess transport, stop on timeout
( defined $rv ) ? &ok : &nok;

my ( $transport ) = $rv->createTransport( description => 'myTransport' );
( $transport->description eq 'myTransport' ) ? &ok : &nok;
eval
{
   ( $transport->batchMode( Tibco::Rv::Transport::TIMER_BATCH ) &&
      $transport->batchMode == Tibco::Rv::Transport::TIMER_BATCH ) ? &ok : &nok;
};
if ( $@ )
{
   ( $Tibco::Rv::TIBRV_VERSION_RELEASE < 7 &&
      $@ == Tibco::Rv::VERSION_MISMATCH ) ? &ok : &nok;
}


__DATA__
TODO
Rv:
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
limitPolicy/priority
