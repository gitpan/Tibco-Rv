package Tibco::Rv;


use vars qw/ $VERSION /;

BEGIN
{
   $VERSION = '0.03';
   my ( $env_err ) = q/one of: TIB_HOME, TIB_RV_HOME, or TIBRV_DIR must be set
TIB_HOME must be your base Tibco directory, and it must contain "tibrv"; or:
TIB_RV_HOME or TIBRV_DIR must be your Rendezvous installation directory
/;
   unless ( exists $ENV{TIB_RV_HOME} )
   {
      if ( exists $ENV{TIBRV_DIR} )
      {
         $ENV{TIB_RV_HOME} = $ENV{TIBRV_DIR};
      } elsif ( exists $ENV{TIB_HOME} ) {
         $ENV{TIB_RV_HOME} = "$ENV{TIB_HOME}/tibrv";
      }
   }
   die $env_err
      unless ( -d "$ENV{TIB_RV_HOME}/include" and -d "$ENV{TIB_RV_HOME}/lib" );
}

use Inline C => Config =>
   AUTOWRAP => 'ENABLE',
   TYPEMAPS => 'typemap',
   LIBS => "-L$ENV{TIB_RV_HOME}/lib -ltibrv",
   INC => "-I$ENV{TIB_RV_HOME}/include";
use Inline C => 'DATA', NAME => 'Tibco::Rv', VERSION => $VERSION;


use Carp;

use constant OK => 0;

use constant INIT_FAILURE => 1;
use constant INVALID_TRANSPORT => 2;
use constant INVALID_ARG => 3;
use constant NOT_INITIALIZED => 4;
use constant ARG_CONFLICT => 5;

use constant SERVICE_NOT_FOUND => 16;
use constant NETWORK_NOT_FOUND => 17;
use constant DAEMON_NOT_FOUND => 18;
use constant NO_MEMORY => 19;
use constant INVALID_SUBJECT => 20;
use constant DAEMON_NOT_CONNECTED => 21;
use constant VERSION_MISMATCH => 22;
use constant SUBJECT_COLLISION => 23;
use constant VC_NOT_CONNECTED => 24;

use constant NOT_PERMITTED => 27;

use constant INVALID_NAME => 30;
use constant INVALID_TYPE => 31;
use constant INVALID_SIZE => 32;
use constant INVALID_COUNT => 33;

use constant NOT_FOUND => 35;
use constant ID_IN_USE => 36;
use constant ID_CONFLICT => 37;
use constant CONVERSION_FAILED => 38;
use constant RESERVED_HANDLER => 39;
use constant ENCODER_FAILED => 40;
use constant DECODER_FAILED => 41;
use constant INVALID_MSG => 42;
use constant INVALID_FIELD => 43;
use constant INVALID_INSTANCE => 44;
use constant CORRUPT_MSG => 45;

use constant TIMEOUT => 50;
use constant INTR => 51;

use constant INVALID_DISPATCHABLE => 52;
use constant INVALID_DISPATCHER => 53;

use constant INVALID_EVENT => 60;
use constant INVALID_CALLBACK => 61;
use constant INVALID_QUEUE => 62;
use constant INVALID_QUEUE_GROUP => 63;

use constant INVALID_TIME_INTERVAL => 64;

use constant INVALID_IO_SOURCE => 65;
use constant INVALID_IO_CONDITION => 66;
use constant SOCKET_LIMIT => 67;

use constant OS_ERROR => 68;

use constant INSUFFICIENT_BUFFER => 70;
use constant EOF => 71;
use constant INVALID_FILE => 72;
use constant FILE_NOT_FOUND => 73;
use constant IO_FAILED => 74;

use constant NOT_FILE_OWNER => 80;

use constant TOO_MANY_NEIGHBORS => 90;
use constant ALREADY_EXISTS => 91;

use constant PORT_BUSY => 100;

use constant SUBJECT_MAX => 255;
use constant SUBJECT_TOKEN_MAX => 127;

use constant FALSE => 0;
use constant TRUE => 1;

use constant TIMER_EVENT => 1;
use constant IO_EVENT => 2;
use constant LISTEN_EVENT => 3;

use constant WAIT_FOREVER => -1.0;
use constant NO_WAIT => 0.0;

use constant IO_READ => 1;
use constant IO_WRITE => 2;
use constant IO_EXCEPTION => 4;


use Tibco::Rv::Status;
use Tibco::Rv::Transport;
use Tibco::Rv::QueueGroup;


sub die
{
   my ( $status ) = @_;
   $status = new Tibco::Rv::Status( $status )
      unless ( UNIVERSAL::isa( $status, 'Tibco::Rv::Status' ) );
   local( $Carp::CarpLevel ) = 1;
   croak 0+$status . ": $status\n";
}


sub version
{
   return 'tibrv ' . tibrv_Version( ) . "; Tibco::Rv $VERSION";
}


my ( %defaults );
BEGIN
{
   %defaults = ( stop => 1, processTransport => $Tibco::Rv::Transport::PROCESS,
      transport => undef, queue => $Tibco::Rv::Queue::DEFAULT,
      queueGroup => undef );
}


sub new
{
   my ( $proto, $service, $network, $daemon ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { %defaults }, $class;

   my ( $status ) = tibrv_Open( );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->{transport} = $self->createTransport( $service, $network, $daemon );
   $self->{queueGroup} = new Tibco::Rv::QueueGroup;
   $self->{queueGroup}->add( $self->{queue} );

   return $self;
}


sub processTransport { return shift->{processTransport} }
sub defaultTransport { return shift->{transport} }
sub defaultQueue { return shift->{queue} }
sub defaultQueueGroup { return shift->{queueGroup} }


sub start
{
   my ( $self ) = @_;
   $self->{stop} = 0;
   $self->{queueGroup}->dispatch until ( $self->{stop} );
}


sub stop
{
   my ( $self ) = @_;
   $self->{stop} = 1;
}


sub createMsg { shift; return new Tibco::Rv::Msg( @_ ) }
sub createQueueGroup { shift; return new Tibco::Rv::QueueGroup( @_ ) }
sub createTransport { shift; return new Tibco::Rv::Transport( @_ ) }

sub createDispatcher { return shift->{queueGroup}->createDispatcher( @_ ) }
sub createQueue { return shift->{queueGroup}->createQueue( @_ ) }
sub add { shift->{queueGroup}->add( @_ ) }
sub remove { shift->{queueGroup}->remove( @_ ) }

sub createListener { return shift->{queue}->createListener( @_ ) }
sub createTimer { return shift->{queue}->createTimer( @_ ) }
sub createIO { return shift->{queue}->createIO( @_ ) }

sub send { shift->{transport}->send( @_ ) }
sub sendReply { shift->{transport}->sendReply( @_ ) }
sub sendRequest { shift->{transport}->sendRequest( @_ ) }
sub createInbox { shift->{transport}->createInbox( @_ ) }


sub DESTROY
{
   my ( $self ) = @_;

   my ( $status ) = tibrv_Close( );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


__DATA__

=pod

=head1 NAME

Tibco::Rv - Perl bindings and Object-Oriented library for TIBCO's TIB/Rendezvous

=head1 SYNOPSIS

	use Tibco::Rv;

	my ( $rv ) = new Tibco::Rv;

	my ( $listener ) =
	   $rv->createListener( $rv->defaultTransport, 'ABC', sub
	{
	   my ( $msg ) = @_;
	   print "Listener got a message: $msg\n";
	} );

	my ( $timer ) = $rv->createTimer( 2, sub
	{
	   my ( $msg ) = $rv->createMsg;
	   $msg->addString( field1 => 'myvalue' );
	   $msg->addString( field2 => 'myothervalue' );
	   $msg->sendSubject( 'ABC' );
	   print "Timer kicking out a message: $msg\n";
	   $rv->defaultTransport->send( $msg );
	} );

	my ( $killTimer ) = $rv->createTimer( 7, sub { $rv->stop } );

	$rv->start;
	print "finished\n"

=head1 DESCRIPTION


=head1 AUTHOR

Paul Sturm, sturm@branewave.com


TIB/Rendezvous copyright notice:

/*
 * Copyright (c) 1998-2000 TIBCO Software Inc.
 * All rights reserved.
 * TIB/Rendezvous is protected under US Patent No. 5,187,787.
 * For more information, please contact:
 * TIBCO Software Inc., Palo Alto, California, USA
 *
 * @(#)tibrv.h  2.9
 */


=head1 SEE ALSO

http://www.tibco.com

=cut


__C__

#include <tibrv/tibrv.h>


tibrv_status tibrv_Open( );
tibrv_status tibrv_Close( );
const char * tibrv_Version( );
const char * tibrvStatus_GetText( tibrv_status status );
tibrv_status tibrvMsg_Expand( tibrvMsg message, tibrv_i32 additionalStorage );
tibrv_status tibrvMsg_Reset( tibrvMsg message );
tibrv_status tibrvMsg_AddStringEx( tibrvMsg message,
   const char * fieldName, const char * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_SetSendSubject( tibrvMsg message, const char * subject );
tibrv_status tibrvMsg_SetReplySubject( tibrvMsg message, const char * subject );
tibrv_status tibrvMsg_ClearReferences( tibrvMsg message );
tibrv_status tibrvMsg_MarkReferences( tibrvMsg message );
tibrv_status tibrvMsg_Destroy( tibrvMsg message );
tibrv_status tibrvEvent_ResetTimerInterval( tibrvEvent event,
   tibrv_f64 interval );
tibrv_status tibrvQueue_TimedDispatch( tibrvQueue queue, tibrv_f64 timeout );
tibrv_status tibrvQueue_SetLimitPolicy( tibrvQueue queue,
   tibrvQueueLimitPolicy policy, tibrv_u32 maxEvents, tibrv_u32 discardAmount );
tibrv_status tibrvQueue_SetName( tibrvQueue queue, const char * name );
tibrv_status tibrvQueue_SetPriority( tibrvQueue queue, tibrv_u32 priority );
tibrv_status tibrvQueueGroup_Add( tibrvQueueGroup queueGroup,
   tibrvQueue queue );
tibrv_status tibrvQueueGroup_Remove( tibrvQueueGroup queueGroup,
   tibrvQueue queue );
tibrv_status tibrvQueueGroup_TimedDispatch( tibrvQueueGroup queueGroup,
   tibrv_f64 timeout );
tibrv_status tibrvQueueGroup_Destroy( tibrvQueueGroup queueGroup );
tibrv_status tibrvDispatcher_SetName( tibrvDispatcher dispatcher,
   const char * name );
tibrv_status tibrvDispatcher_Destroy( tibrvDispatcher dispatcher );
tibrv_status tibrvTransport_Send( tibrvTransport transport, tibrvMsg message );
tibrv_status tibrvTransport_SendReply( tibrvTransport transport,
   tibrvMsg reply, tibrvMsg request ); 
tibrv_status tibrvTransport_SetDescription( tibrvTransport transport,
   const char * description ); 
tibrv_status tibrvTransport_SetBatchMode( tibrvTransport transport,
   tibrvTransportBatchMode mode ); 
tibrv_status tibrvTransport_Destroy( tibrvTransport transport );


static void callback_perl_noargs( SV * callback )
{
   dSP;
   PUSHMARK( SP );
   perl_call_sv( callback, G_VOID | G_DISCARD );
}


static void callback_perl_msg( SV * callback, tibrvMsg message )
{
   dSP;

   ENTER;
   SAVETMPS;

   PUSHMARK( SP );
   tibrvMsg_Detach( message );
   XPUSHs( sv_2mortal( newSViv( (IV)message ) ) );
   PUTBACK;

   perl_call_sv( callback, G_VOID | G_DISCARD );

   FREETMPS;
   LEAVE;
}


tibrv_status Msg_Create( SV * sv_message )
{
   tibrvMsg message = (tibrvMsg)NULL;
   tibrv_status status = tibrvMsg_Create( &message );
   sv_setiv( sv_message, (IV)message );
   return status;
}


tibrv_status Msg_CreateCopy( tibrvMsg message, SV * sv_copy )
{
   tibrvMsg copy;
   tibrv_status status = tibrvMsg_CreateCopy( message, &copy );
   sv_setiv( sv_copy, (IV)copy );
   return status;
}


tibrv_status Msg_CreateFromBytes( SV * sv_message, SV * sv_bytes )
{
   tibrvMsg message = (tibrvMsg)NULL;
   void * bytes = SvPV( sv_bytes, PL_na );
   tibrv_status status = tibrvMsg_CreateFromBytes( &message, bytes );
   sv_setiv( sv_message, (IV)message );
   return status;
}


tibrv_status Msg_GetAsBytes( tibrvMsg message, SV * sv_bytes )
{
   tibrv_u32 byteSize;
   const void * bytes;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   if ( status != TIBRV_OK ) return status;
   status = tibrvMsg_GetAsBytes( message, &bytes );
   if ( status != TIBRV_OK ) return status;
   sv_setpvn( sv_bytes, (char *)bytes, byteSize );
   return status;
}


tibrv_status Msg_GetAsBytesCopy( tibrvMsg message, SV * sv_bytes )
{
   void * bytes;
   tibrv_u32 byteSize;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   bytes = malloc( byteSize );
   if ( status != TIBRV_OK ) return status;
   status = tibrvMsg_GetAsBytesCopy( message, bytes, byteSize );
   if ( status != TIBRV_OK ) return status;
   sv_setpvn( sv_bytes, (char *)bytes, byteSize );
   free( bytes );
   return status;
}


tibrv_status Msg_GetNumFields( tibrvMsg message, SV * sv_numFields )
{
   tibrv_u32 numFields;
   tibrv_status status = tibrvMsg_GetNumFields( message, &numFields );
   sv_setiv( sv_numFields, (IV)numFields );
   return status;
}


tibrv_status Msg_GetByteSize( tibrvMsg message, SV * sv_byteSize )
{
   tibrv_u32 byteSize;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   sv_setiv( sv_byteSize, (IV)byteSize );
   return status;
}


tibrv_status Msg_ConvertToString( tibrvMsg message, SV * sv_str )
{
   const char * str;
   tibrv_status status = tibrvMsg_ConvertToString( message, &str );
   sv_setpv( sv_str, str );
   return status;
}


/*
static void onEventDestroy( tibrvEvent event, void * closure )
{
   callback_perl_noargs( (SV *)closure );
}
*/


/* no closure data here -- it gets closure data from constructor
 * so to support this, we'd have to store both callbacks in the closure
 * and have a "completionCallback" parameter in constructor
 */
tibrv_status Event_DestroyEx( tibrvEvent event )
{
   return tibrvEvent_DestroyEx( event, NULL );
}


static void onEventMsg( tibrvEvent event, tibrvMsg message, void * closure )
{
   callback_perl_msg( (SV *)closure, message );
}


static void onEventNoMsg( tibrvEvent event, tibrvMsg message, void * closure )
{
   callback_perl_noargs( (SV *)closure );
}


tibrv_status Event_CreateListener( SV * sv_event, tibrvQueue queue,
   SV * callback, tibrvTransport transport, const char * subject )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvEvent_CreateListener( &event, queue, onEventMsg,
      transport, subject, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


tibrv_status Event_CreateTimer( SV * sv_event, tibrvQueue queue, SV * callback,
   tibrv_f64 interval )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvEvent_CreateTimer( &event, queue, onEventNoMsg,
      interval, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


tibrv_status Event_CreateIO( SV * sv_event, tibrvQueue queue, SV * callback,
   tibrv_i32 socketId, tibrvIOType ioType )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvEvent_CreateIO( &event, queue, onEventNoMsg,
      socketId, ioType, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


tibrv_status Queue_Create( SV * sv_queue )
{
   tibrvQueue queue = (tibrvQueue)NULL;
   tibrv_status status = tibrvQueue_Create( &queue );
   sv_setiv( sv_queue, (IV)queue );
   return status;
}


tibrv_status Queue_GetCount( tibrvQueue queue, SV * sv_count )
{
   tibrv_u32 count;
   tibrv_status status = tibrvQueue_GetCount( queue, &count );
   sv_setiv( sv_count, (IV)count );
   return status;
}


static void onQueueEvent( tibrvQueue queue, void * closure )
{
   callback_perl_noargs( (SV *)closure );
}


tibrv_status Queue_SetHook( tibrvQueue queue, SV * callback )
{
   tibrvQueueHook eventQueueHook = NULL;
   if ( SvOK( callback ) ) eventQueueHook = onQueueEvent;
   return tibrvQueue_SetHook( queue, eventQueueHook, callback );
}


static void onQueueDestroy( tibrvQueue queue, void * closure )
{
   SV * callback = (SV *)closure;
   callback_perl_noargs( callback );
   SvREFCNT_dec( callback );
}


tibrv_status Queue_DestroyEx( tibrvQueue queue, SV * callback )
{
   tibrvQueueOnComplete completionFn = NULL;
   if ( SvOK( callback ) )
   {
      completionFn = onQueueDestroy;
      SvREFCNT_inc( callback );
   }
   return tibrvQueue_DestroyEx( queue, completionFn, callback );
}


tibrv_status QueueGroup_Create( SV * sv_queueGroup )
{
   tibrvQueueGroup queueGroup = (tibrvQueueGroup)NULL;
   tibrv_status status = tibrvQueueGroup_Create( &queueGroup );
   sv_setiv( sv_queueGroup, (IV)queueGroup );
   return status;
}


tibrv_status Dispatcher_Create( SV * sv_dispatcher,
   tibrvDispatchable dispatchable, tibrv_f64 idleTimeout )
{
   tibrvDispatcher dispatcher = (tibrvDispatcher)NULL;
   tibrv_status status = tibrvDispatcher_CreateEx( &dispatcher, dispatchable,
      idleTimeout );
   sv_setiv( sv_dispatcher, (IV)dispatcher );
   return status;
}


tibrv_status Transport_Create( SV * sv_transport, const char * service,
   const char * network, const char * daemon ) 
{
   tibrvTransport transport = (tibrvTransport)NULL;
   tibrv_status status =
      tibrvTransport_Create( &transport, service, network, daemon );
   sv_setiv( sv_transport, (IV)transport );
   return status;
}


tibrv_status Transport_SendRequest( tibrvTransport transport, tibrvMsg request,
   SV * sv_reply, tibrv_f64 timeout )
{
   tibrvMsg reply = (tibrvMsg)NULL;
   tibrv_status status =
      tibrvTransport_SendRequest( transport, request, &reply, timeout );
   sv_setiv( sv_reply, (IV)reply );
   return status;
}


tibrv_status Transport_CreateInbox( tibrvTransport transport, SV * sv_inbox )
{
   tibrv_u32 limit = TIBRV_SUBJECT_MAX + 1;
   char inbox[ limit ];
   tibrv_status status = tibrvTransport_CreateInbox( transport, inbox, limit );
   sv_setpv( sv_inbox, inbox );
   return status;
}
