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
my ( $msg ) = $rv->createMsg;
$msg->markReferences;
$msg->addString( field => 'value' );
$msg->addString( field2 => 'value2' );
$msg->sendSubject( 'ABC' );
$msg->replySubject( 'ABC.REPLY' );
print "NumFields: ", $msg->numFields, "/byteSize: ", $msg->byteSize, "\n";
print "SendSub: ", $msg->sendSubject, "/ReplySub: ", $msg->replySubject, "\n";
print "msg: $msg\n";


{
my ( $m2 ) = $rv->createMsg;
my ( $field ) = new Tibco::Rv::Msg::Field;
$field->name( 'aBool' );
print "bool: ", $field->bool, "\n";
$field->bool( Tibco::Rv::TRUE );
$m2->addField( $field );
$field->name( 'aString' );
$field->str( 'my string' );
$m2->addField( $field );
$field->name( 'aOpaque' );
$field->opaque( "my\0 opaque\0 data" );
$m2->addField( $field );
$field->name( 'aXML' );
$field->xml( "<abc><xyz>123</xyz>456</abc>" );
$m2->addField( $field );
$field->name( 'aMsg' );
$msg->sendSubject( 'MY.SEND.SUBJECT' );
$msg->replySubject( 'MY.REPLY.SUBJECT' );
$field->msg( $msg );
$m2->addField( $field );
$field->name( 'aI8' );
$field->i8( -8 );
$m2->addField( $field );
$field->name( 'aU8' );
$field->u8( 8 );
$m2->addField( $field );
$field->name( 'aI16' );
$field->i16( -16 );
$m2->addField( $field );
$field->name( 'aU16' );
$field->u16( 16 );
$m2->addField( $field );
$field->name( 'aI32' );
$field->i32( -32 );
$m2->addField( $field );
$field->name( 'aU32' );
$field->u32( 32 );
$m2->addField( $field );
$field->name( 'aI64' );
$field->i64( -64 );
$m2->addField( $field );
$field->name( 'aU64' );
$field->u64( 64 );
$m2->addField( $field );
$field->name( 'aF32' );
$field->f32( 32.5 );
$m2->addField( $field );
$field->name( 'aF64' );
$field->f64( 64.555555555 );
$m2->addField( $field );
$field->name( 'aIPPORT16' );
$field->ipport16( 2316 );
$m2->addField( $field );
$field->name( 'aIPADDR32' );
$field->ipaddr32( 2332 );
$m2->addField( $field );
my ( $date ) = new Tibco::Rv::Msg::DateTime;
print $date->{sec}, "/", $date->{nsec}, "---->", scalar( localtime( $date ) ), "\n";
print "---->", scalar( gmtime( 0 ) ), "\n";
$date->now;
$field->name( 'aDATETIME' );
$field->date( $date );
$m2->addField( $field );
$m2->addBool( "myBool", Tibco::Rv::TRUE, 23 );
$m2->addF32( 'myF32', 1212 );
$m2->addF64( 'myF64', 123123 );
$m2->addI8( 'myI8', 1 );
$m2->addI16( 'myI16', 16 );
$m2->addI32( 'myI32', 32 );
$m2->addI64( 'myI64', 64 );
$m2->addU8( 'myU8', 1 );
$m2->addU16( 'myU16', 16 );
$m2->addU32( 'myU32', 32 );
$m2->addU64( 'myU64', 64 );
$m2->addMsg( 'myMsg', $msg );
$m2->addString( 'myString', "abc" );
$m2->addOpaque( 'myOpaque', "abc\0xyz" );
$m2->addXml( 'myXml', '<abc/>' );
$m2->addDateTime( 'myDateTime', $date );
$m2->addIPAddr32( 'myIPAddr32', 1212 );
$m2->addIPPort16( 'myIPPort16', 1212 );
$m2->updateBool( "myBool", Tibco::Rv::FALSE, 23 );
$m2->updateF32( 'myF32', 12121 );
$m2->updateF64( 'myF64', 1231231 );
$m2->updateI8( 'myI8', 11 );
$m2->updateI16( 'myI16', 161 );
$m2->updateI32( 'myI32', 321 );
$m2->updateI64( 'myI64', 641 );
$m2->updateU8( 'myU8', 11 );
$m2->updateU16( 'myU16', 161 );
$m2->updateU32( 'myU32', 321 );
$m2->updateU64( 'myU64', 641 );
$m2->updateMsg( 'myMsg', $msg );
$m2->updateString( 'myString', "abc1" );
$m2->updateOpaque( 'myOpaque', "abc\0xyz1" );
$m2->updateXml( 'myXml', '<ab11c/>' );
$m2->updateDateTime( 'myDateTime', $date );
$m2->updateIPAddr32( 'myIPAddr32', 12121 );
$m2->updateIPPort16( 'myIPPort16', 12121 );
##############################      arrays
print "m2: $m2\n";
print "numFields: ", $m2->numFields, "\n";
for my $i ( 0 .. $m2->numFields - 1 )
{
   my ( $f ) = $m2->getFieldByIndex( $i );
   print join( '/', $f->name, $f->id, $f->type, $f->{data}, $f->size ), "\n";
}
my ( $gotten ) = $m2->getField( 'aIPPORT16' );
print "got $gotten (", $gotten->ipport16, ")\n";
$gotten->ipport16( 10 );
print "got $gotten (", $gotten->ipport16, ")\n";
$m2->updateField( $gotten );
print "--$m2--\n";
print "F32: ", $m2->getF32( 'myF32' ), "\n";
print "I8: ", $m2->getI8( 'myI8' ), "\n";
print "U32: ", $m2->getF32( 'myU32' ), "\n";
print "IPAddr32: ", $m2->getIPAddr32( 'myIPAddr32' ), "\n";
print "String: ", $m2->getString( 'myString' ), "\n";
print "Opaque: ", $m2->getOpaque( 'myOpaque' ), "\n";
print "Xml: ", $m2->getXml( 'myXml' ), "\n";
print "Msg: ", $m2->getMsg( 'myMsg' ), "\n";
print "DateTime: ", $m2->getDateTime( 'myDateTime' ), "\n";
$field->bool( Tibco::Rv::TRUE );
print "bool: ", $field->bool, "\n";
$field->str( "abc" );
print "str: ", $field->str, "\n";
$field->msg( $msg );
print "msg: ", $field->msg, "\n";
my ( $m ) = $rv->createMsg;
$m->addField( $field );
$field->name( 'other name' );
$field->id( 13 );
$m->addField( $field );
print "message '$m'\n";
my ( $numFields ) = $m->numFields;
print "numFields: $numFields\n";
my ( $f ) = $m->getFieldByIndex( 0 );
use Data::Dumper;
print "getFieldByIndex 0 field: ", Data::Dumper->Dump( [ $f ], [ qw/ f / ] ), "\n";
$f = $m->getFieldInstance( 'other name', 1 );
print "getFieldInstance field: ", Data::Dumper->Dump( [ $f ], [ qw/ f / ] ), "\n";
$m->removeField( 'other name' );
$m->removeFieldInstance( 'my field name', 1 );
print "after all is said and done, $m\n";
$field->bool( Tibco::Rv::TRUE );
$field->str( 'xyz' );
print "----count---: ", $field->count, "\n";
$field->bool( Tibco::Rv::TRUE );
$field->opaque( "heres a large chunk\0 of data: abc" );
#$field->str( "heres a large chunk\0 of data: abc" );
$field->id( 64 );
$m->addField( $field );
print "--------$m---------\n";
print "field: ", Data::Dumper->Dump( [ $field ], [ qw/ field / ] ), "\n";
print join( '-', '', $field->opaque, '' ), "\n";
undef $field;
}


if ( 0 )
{
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
}
print "ok 2\n";
