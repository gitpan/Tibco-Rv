# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tibco::Rv;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my ( $rv ) = new Tibco::Rv;
print $rv->version, "\n";
my ( $msg ) = new Tibco::Rv::Msg;
$msg->markReferences;
$msg->addString( field => 'value' );
$msg->addString( field2 => 'value2' );
$msg->sendSubject( 'ABC' );
$msg->replySubject( 'ABC.REPLY' );
print "NumFields: ", $msg->numFields, "/byteSize: ", $msg->byteSize, "\n";
print "SendSub: ", $msg->sendSubject, "/ReplySub: ", $msg->replySubject, "\n";
my ( $copy ) = $msg->copy;
my ( $bytes ) = $copy->bytesCopy;
my ( $newMsg ) = Tibco::Rv::Msg->createFromBytes( $bytes );
print "newMsg: $newMsg\n";
$copy->expand( 12 );
print "copied message: $copy\n";

$copy->reset;
print "copied message: $copy\n";
$msg->clearReferences;
my ( $transport ) = new Tibco::Rv::Transport;
my ( $queue ) = $Tibco::Rv::Queue::DEFAULT;
my ( $h ) = sub { print "Hook brought me back\n" };
$queue->hook( $h );
print "hook is: ", $queue->hook, "\n";
print "running hook\n";
$queue->hook->( );
my ( $policy, $maxEvents, $discardAmount ) = $queue->limitPolicy;
print "LimitPolicy: $policy/$maxEvents/$discardAmount\n";

my ( $queueGroup ) = new Tibco::Rv::QueueGroup;
$queueGroup->add( $queue );

my ( $listener ) = $queue->createListener( $transport, 'ABC', sub
{
   my ( $msg ) = @_;
   print "Listener: $msg\n";
} );
print "listening on ", $listener->subject, "\n";
my ( $timer ) = $queue->createTimer( 1.5, sub { $transport->send( $msg ) } );
$timer->onEvent;
sleep( 5 );
print "Count: ", $queue->count, "\n";
my ( $dispatcher ) = $queueGroup->createDispatcher;
$dispatcher->name( 'my name' );
print "dispatcher name: ", $dispatcher->name, "\n";
sleep( 5 );
my ( $q ) = new Tibco::Rv::Queue;
$q->limitPolicy( Tibco::Rv::Queue::DISCARD_FIRST, 100, 1 );
( $policy, $maxEvents, $discardAmount ) = $q->limitPolicy;
print "LimitPolicy: $policy/$maxEvents/$discardAmount\n";
$q->name( "my name is simon" );
$q->priority( 33 );
print "name/priority: ", join( '/', $q->name, $q->priority ), "\n";
print "running hook\n";
$queue->hook->( );
undef $timer;
undef $listener;
$transport->description( "my description" );
$transport->batchMode( Tibco::Rv::Transport::TIMER_BATCH );
print "transport: ", join( '/', $transport->service, $transport->network, $transport->daemon, $transport->description, $transport->batchMode ), "\n";
my ( $t ) = $Tibco::Rv::Transport::PROCESS;
print "process: ", join( '/', $t->batchMode ), "\n";
print "Some inboxes: ", $transport->createInbox, "/", $t->createInbox, "\n";

$Tibco::Rv::Queue::DEFAULT->name( "abc" );
print $Tibco::Rv::Queue::DEFAULT->name, "\n";
print "ok 2\n";
