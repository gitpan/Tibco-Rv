package Tibco::Rv;


use vars qw/ $VERSION /;

BEGIN
{
   $VERSION = '0.90';
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
   $SIG{TERM} = $SIG{KILL} = sub { $self->stop };
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
tibrv_status tibrvMsg_SetSendSubject( tibrvMsg message, const char * subject );
tibrv_status tibrvMsg_SetReplySubject( tibrvMsg message, const char * subject );
tibrv_status tibrvMsg_AddField( tibrvMsg message, tibrvMsgField * field );
tibrv_status tibrvMsg_ClearReferences( tibrvMsg message );
tibrv_status tibrvMsg_MarkReferences( tibrvMsg message );
tibrv_status tibrvMsg_RemoveFieldEx( tibrvMsg message, const char * fieldName,
   tibrv_u16 fieldId );
tibrv_status tibrvMsg_RemoveFieldInstance( tibrvMsg message,
   const char * fieldName, tibrv_u32 instance );
tibrv_status tibrvMsg_UpdateField( tibrvMsg message, tibrvMsgField * field );
tibrv_status tibrvMsg_Destroy( tibrvMsg message );
tibrv_status tibrvMsg_AddBoolEx( tibrvMsg message, const char * fieldName,
   tibrv_bool value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddF32Ex( tibrvMsg message, const char * fieldName,
   tibrv_f32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddF64Ex( tibrvMsg message, const char * fieldName,
   tibrv_f64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI8Ex( tibrvMsg message, const char * fieldName,
   tibrv_i8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI16Ex( tibrvMsg message, const char * fieldName,
   tibrv_i16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI32Ex( tibrvMsg message, const char * fieldName,
   tibrv_i32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddI64Ex( tibrvMsg message, const char * fieldName,
   tibrv_i64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU8Ex( tibrvMsg message, const char * fieldName,
   tibrv_u8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU16Ex( tibrvMsg message, const char * fieldName,
   tibrv_u16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU32Ex( tibrvMsg message, const char * fieldName,
   tibrv_u32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddU64Ex( tibrvMsg message, const char * fieldName,
   tibrv_u64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddIPAddr32Ex( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddIPPort16Ex( tibrvMsg message, const char * fieldName,
   tibrv_ipport16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddStringEx( tibrvMsg message, const char * fieldName,
   const char * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddMsgEx( tibrvMsg message, const char * fieldName,
   tibrvMsg value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_AddDateTimeEx( tibrvMsg message, const char * fieldName,
   const tibrvMsgDateTime * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateBoolEx( tibrvMsg message, const char * fieldName,
   tibrv_bool value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateF32Ex( tibrvMsg message, const char * fieldName,
   tibrv_f32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateF64Ex( tibrvMsg message, const char * fieldName,
   tibrv_f64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI8Ex( tibrvMsg message, const char * fieldName,
   tibrv_i8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI16Ex( tibrvMsg message, const char * fieldName,
   tibrv_i16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI32Ex( tibrvMsg message, const char * fieldName,
   tibrv_i32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateI64Ex( tibrvMsg message, const char * fieldName,
   tibrv_i64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU8Ex( tibrvMsg message, const char * fieldName,
   tibrv_u8 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU16Ex( tibrvMsg message, const char * fieldName,
   tibrv_u16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU32Ex( tibrvMsg message, const char * fieldName,
   tibrv_u32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateU64Ex( tibrvMsg message, const char * fieldName,
   tibrv_u64 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateIPAddr32Ex( tibrvMsg message,
   const char * fieldName, tibrv_ipaddr32 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateIPPort16Ex( tibrvMsg message,
   const char * fieldName, tibrv_ipport16 value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateStringEx( tibrvMsg message, const char * fieldName,
   const char * value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateMsgEx( tibrvMsg message, const char * fieldName,
   tibrvMsg value, tibrv_u16 fieldId );
tibrv_status tibrvMsg_UpdateDateTimeEx( tibrvMsg message,
   const char * fieldName, const tibrvMsgDateTime * value, tibrv_u16 fieldId );
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


void Msg__GetValues( tibrvMsg message, SV * sv_sendSubject,
   SV * sv_replySubject )
{
   const char * sendSubject = NULL;
   const char * replySubject = NULL;
   tibrvMsg_GetSendSubject( message, &sendSubject );
   tibrvMsg_GetReplySubject( message, &replySubject );
   sv_setpv( sv_sendSubject, sendSubject );
   sv_setpv( sv_replySubject, replySubject );
}


tibrv_status Msg_CreateCopy( tibrvMsg message, SV * sv_copy )
{
   tibrvMsg copy;
   tibrv_status status = tibrvMsg_CreateCopy( message, &copy );
   sv_setiv( sv_copy, (IV)copy );
   return status;
}


tibrv_status Msg_GetField( tibrvMsg message, const char * fieldName,
   SV * sv_field, tibrv_u16 fieldId )
{
   tibrv_status status;
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;
   status = tibrvMsg_GetFieldEx( message, fieldName, field, fieldId );
   sv_setiv( sv_field, (IV)field );
   return status;
}


tibrv_status Msg_GetScalar( tibrvMsg message, tibrv_u8 type,
   const char * fieldName, SV * sv_value, tibrv_u16 fieldId )
{
   tibrv_status status;

   switch ( type )
   {
      case TIBRVMSG_BOOL: {
         tibrv_bool boolean;
         status = tibrvMsg_GetBoolEx( message, fieldName, &boolean, fieldId );
         sv_setiv( sv_value, (IV)boolean );
      } break;
      case TIBRVMSG_F32: {
         tibrv_f32 f32;
         status = tibrvMsg_GetF32Ex( message, fieldName, &f32, fieldId );
         sv_setnv( sv_value, f32 );
      } break;
      case TIBRVMSG_F64: {
         tibrv_f64 f64;
         status = tibrvMsg_GetF64Ex( message, fieldName, &f64, fieldId );
         sv_setnv( sv_value, f64 );
      } break;
      case TIBRVMSG_I8: {
         tibrv_i8 i8;
         status = tibrvMsg_GetI8Ex( message, fieldName, &i8, fieldId );
         sv_setiv( sv_value, (IV)i8 );
      } break;
      case TIBRVMSG_I16: {
         tibrv_i16 i16;
         status = tibrvMsg_GetI16Ex( message, fieldName, &i16, fieldId );
         sv_setiv( sv_value, (IV)i16 );
      } break;
      case TIBRVMSG_I32: {
         tibrv_i32 i32;
         status = tibrvMsg_GetI32Ex( message, fieldName, &i32, fieldId );
         sv_setiv( sv_value, (IV)i32 );
      } break;
      case TIBRVMSG_I64: {
         tibrv_i64 i64;
         status = tibrvMsg_GetI64Ex( message, fieldName, &i64, fieldId );
         sv_setiv( sv_value, (IV)i64 );
      } break;
      case TIBRVMSG_U8: {
         tibrv_u8 u8;
         status = tibrvMsg_GetU8Ex( message, fieldName, &u8, fieldId );
         sv_setuv( sv_value, (UV)u8 );
      } break;
      case TIBRVMSG_U16: {
         tibrv_u16 u16;
         status = tibrvMsg_GetU16Ex( message, fieldName, &u16, fieldId );
         sv_setuv( sv_value, (UV)u16 );
      } break;
      case TIBRVMSG_U32: {
         tibrv_u32 u32;
         status = tibrvMsg_GetU32Ex( message, fieldName, &u32, fieldId );
         sv_setuv( sv_value, (UV)u32 );
      } break;
      case TIBRVMSG_U64: {
         tibrv_u64 u64;
         status = tibrvMsg_GetU64Ex( message, fieldName, &u64, fieldId );
         sv_setuv( sv_value, (UV)u64 );
      } break;
      case TIBRVMSG_IPADDR32: {
         tibrv_ipaddr32 ipaddr32;
         status =
            tibrvMsg_GetIPAddr32Ex( message, fieldName, &ipaddr32, fieldId );
         sv_setuv( sv_value, (UV)ipaddr32 );
      } break;
      case TIBRVMSG_IPPORT16: {
         tibrv_ipport16 ipport16;
         status =
            tibrvMsg_GetIPPort16Ex( message, fieldName, &ipport16, fieldId );
         sv_setiv( sv_value, (IV)ipport16 );
      } break;
      case TIBRVMSG_STRING: {
         const char * str;
         status = tibrvMsg_GetStringEx( message, fieldName, &str, fieldId );
         sv_setpv( sv_value, str );
      } break;
      case TIBRVMSG_OPAQUE: {
         const void * opaque;
         tibrv_u32 len;
         status =
            tibrvMsg_GetOpaqueEx( message, fieldName, &opaque, &len, fieldId );
         sv_setpvn( sv_value, (char *)opaque, len );
      } break;
      case TIBRVMSG_XML: {
         const void * xml;
         tibrv_u32 len;
         status = tibrvMsg_GetXmlEx( message, fieldName, &xml, &len, fieldId );
         sv_setpvn( sv_value, (char *)xml, len );
      } break;
      case TIBRVMSG_MSG: {
         tibrvMsg msg = (tibrvMsg)NULL;
         status = tibrvMsg_GetMsgEx( message, fieldName, &msg, fieldId );
         sv_setiv( sv_value, (IV)msg );
      } break;
      case TIBRVMSG_DATETIME: {
         tibrvMsgDateTime * date =
            (tibrvMsgDateTime *)malloc( sizeof( tibrvMsgDateTime ) );
         if ( date == NULL ) return TIBRV_NO_MEMORY;
         status = tibrvMsg_GetDateTimeEx( message, fieldName, date, fieldId );
         sv_setiv( sv_value, (IV)date );
      } break;
   }

   return status;
}


tibrv_status Msg_GetFieldByIndex( tibrvMsg message, SV * sv_field,
   tibrv_u32 fieldIndex )
{
   tibrv_status status;
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;
   status = tibrvMsg_GetFieldByIndex( message, field, fieldIndex );
   sv_setiv( sv_field, (IV)field );
   return status;
}


tibrv_status Msg_GetFieldInstance( tibrvMsg message, const char * fieldName,
   SV * sv_field, tibrv_u32 instance )
{
   tibrv_status status;
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;
   status = tibrvMsg_GetFieldInstance( message, fieldName, field, instance );
   sv_setiv( sv_field, (IV)field );
   return status;
}


tibrv_status Msg_CreateFromBytes( SV * sv_message, SV * sv_bytes )
{
   tibrvMsg message = (tibrvMsg)NULL;
   const void * bytes = SvPV( sv_bytes, PL_na );
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
   if ( bytes == NULL ) return TIBRV_NO_MEMORY;
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
   sv_setuv( sv_numFields, (UV)numFields );
   return status;
}


tibrv_status Msg_GetByteSize( tibrvMsg message, SV * sv_byteSize )
{
   tibrv_u32 byteSize;
   tibrv_status status = tibrvMsg_GetByteSize( message, &byteSize );
   sv_setuv( sv_byteSize, (UV)byteSize );
   return status;
}


tibrv_status Msg_ConvertToString( tibrvMsg message, SV * sv_str )
{
   const char * str;
   tibrv_status status = tibrvMsg_ConvertToString( message, &str );
   sv_setpv( sv_str, str );
   return status;
}


tibrv_status Msg_AddOpaque( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_AddOpaqueEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_AddXml( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_AddXmlEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_UpdateOpaque( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_UpdateOpaqueEx( message, fieldName, buf, len, fieldId );
}


tibrv_status Msg_UpdateXml( tibrvMsg message, const char * fieldName,
   SV * sv_value, tibrv_u16 fieldId )
{
   STRLEN len;
   void * buf = SvPV( sv_value, len );
   return tibrvMsg_UpdateXmlEx( message, fieldName, buf, len, fieldId );
}


tibrv_status MsgDateTime_Create( SV * sv_date, tibrv_i64 sec, tibrv_u32 nsec );
void MsgField_SetName( tibrvMsgField * field, const char * name );
void MsgField_SetId( tibrvMsgField * field, tibrv_u16 id );


tibrv_status MsgField_Create( SV * sv_field )
{
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;

   MsgField_SetName( field, NULL );
   MsgField_SetId( field, 0 );

   sv_setiv( sv_field, (IV)field );
   return TIBRV_OK;
}


void MsgField__GetValues( tibrvMsgField * field, SV * sv_name, SV * sv_id,
   SV * sv_size, SV * sv_count, SV * sv_type, SV * sv_data )
{
   sv_setpv( sv_name, field->name );
   sv_setuv( sv_id, (UV)field->id );
   sv_setuv( sv_size, (UV)field->size );
   sv_setuv( sv_count, (UV)field->count );
   sv_setuv( sv_type, (UV)field->type );
   switch ( field->type )
   {
      case TIBRVMSG_MSG: sv_setiv( sv_data, (IV)field->data.msg );
      break;
      case TIBRVMSG_STRING: sv_setpvn( sv_data, field->data.str, field->size );
      break;
      case TIBRVMSG_OPAQUE:
      case TIBRVMSG_XML:
         sv_setpvn( sv_data, field->data.buf, field->size );
      break;
      case TIBRVMSG_I8ARRAY:
      break;
      case TIBRVMSG_U8ARRAY:
      break;
      case TIBRVMSG_I16ARRAY:
      break;
      case TIBRVMSG_U16ARRAY:
      break;
      case TIBRVMSG_I32ARRAY:
      break;
      case TIBRVMSG_U32ARRAY:
      break;
      case TIBRVMSG_I64ARRAY:
      break;
      case TIBRVMSG_U64ARRAY:
      break;
      case TIBRVMSG_F32ARRAY:
      break;
      case TIBRVMSG_F64ARRAY:
      break;
      case TIBRVMSG_BOOL: sv_setiv( sv_data, (IV)field->data.boolean ); break;
      case TIBRVMSG_I8: sv_setiv( sv_data, (IV)field->data.i8 ); break;
      case TIBRVMSG_U8: sv_setuv( sv_data, (UV)field->data.u8 ); break;
      case TIBRVMSG_I16: sv_setiv( sv_data, (IV)field->data.i16 ); break;
      case TIBRVMSG_U16: sv_setuv( sv_data, (UV)field->data.u16 ); break;
      case TIBRVMSG_I32: sv_setiv( sv_data, (IV)field->data.i32 ); break;
      case TIBRVMSG_U32: sv_setuv( sv_data, (UV)field->data.u32 ); break;
      case TIBRVMSG_I64: sv_setiv( sv_data, (IV)field->data.i64 ); break;
      case TIBRVMSG_U64: sv_setuv( sv_data, (UV)field->data.u64 ); break;
      case TIBRVMSG_F32: sv_setnv( sv_data, field->data.f32 ); break;
      case TIBRVMSG_F64: sv_setnv( sv_data, field->data.f64 ); break;
      case TIBRVMSG_IPPORT16:
         sv_setuv( sv_data, ntohs( (UV)field->data.ipport16 ) );
      break;
      case TIBRVMSG_IPADDR32:
         sv_setuv( sv_data, ntohs( (UV)field->data.ipaddr32 ) );
      break;
      case TIBRVMSG_DATETIME:
         MsgDateTime_Create( sv_data, (IV)field->data.date.sec,
            (UV)field->data.date.nsec );
      break;
   }
}


void MsgField_SetName( tibrvMsgField * field, const char * name )
{
   field->name = name;
}


void MsgField_SetId( tibrvMsgField * field, tibrv_u16 id )
{
   field->id = id;
}


tibrv_u32 MsgField_SetMsg( tibrvMsgField * field, tibrvMsg message )
{
   field->data.msg = message;
   field->size = 0;
   tibrvMsg_GetByteSize( message, &field->size );
   field->count = 1;
   field->type = TIBRVMSG_MSG;

   return field->size;
}


tibrv_u32 MsgField__SetBuf( tibrvMsgField * field, SV * sv_buf, tibrv_u8 type )
{
   STRLEN len;
   char * buf = SvPV( sv_buf, len );
   switch ( type )
   {
      case TIBRVMSG_STRING:
         SvGROW( sv_buf, len + 1 );
         buf[ len ] = '\0';
         len = strlen( buf ) + 1;
         field->data.str = buf;
      break;
      case TIBRVMSG_OPAQUE:
      case TIBRVMSG_XML:
         field->data.buf = buf;
      break;
   }
   field->count = 1;
   field->type = type;
   return field->size = len;
}


tibrv_u32 MsgField__SetElt( tibrvMsgField * field, SV * sv_elt, tibrv_u8 type )
{
   field->count = 1;
   field->type = type;
   switch ( type )
   {
      case TIBRVMSG_BOOL: field->data.boolean = SvIV( sv_elt ); break;
      case TIBRVMSG_I8: field->data.i8 = SvIV( sv_elt ); break;
      case TIBRVMSG_U8: field->data.u8 = SvUV( sv_elt ); break;
      case TIBRVMSG_I16: field->data.i16 = SvIV( sv_elt ); break;
      case TIBRVMSG_U16: field->data.i16 = SvUV( sv_elt ); break;
      case TIBRVMSG_I32: field->data.i32 = SvIV( sv_elt ); break;
      case TIBRVMSG_U32: field->data.u32 = SvUV( sv_elt ); break;
      case TIBRVMSG_I64: field->data.i64 = SvIV( sv_elt ); break;
      case TIBRVMSG_U64: field->data.u64 = SvUV( sv_elt ); break;
      case TIBRVMSG_F32: field->data.f32 = SvNV( sv_elt ); break;
      case TIBRVMSG_F64: field->data.f64 = SvNV( sv_elt ); break;
      case TIBRVMSG_IPPORT16:
         field->data.ipport16 = htons( SvUV( sv_elt ) );
      break;
      case TIBRVMSG_IPADDR32:
         field->data.ipaddr32 = htons( SvUV( sv_elt ) );
      break;
   }
   switch ( type )
   {
      case TIBRVMSG_BOOL:
         return field->size = sizeof( tibrv_bool );
      case TIBRVMSG_I8:
      case TIBRVMSG_U8:
         return field->size = 1;
      case TIBRVMSG_I16:
      case TIBRVMSG_U16:
      case TIBRVMSG_IPPORT16:
         return field->size = 2;
      case TIBRVMSG_I32:
      case TIBRVMSG_U32:
      case TIBRVMSG_F32:
      case TIBRVMSG_IPADDR32:
         return field->size = 4;
      case TIBRVMSG_I64:
      case TIBRVMSG_U64:
      case TIBRVMSG_F64:
         return field->size = 8;
   }
   return 0;
}


tibrv_u32 MsgField__SetDateTime( tibrvMsgField * field,
   tibrvMsgDateTime * date )
{
   field->data.date.sec = date->sec;
   field->data.date.nsec = date->nsec;
   field->count = 1;
   field->type = TIBRVMSG_DATETIME;

   return field->size = sizeof( tibrvMsgDateTime );
}


tibrv_status MsgField_Destroy( tibrvMsgField * field )
{
   free( field );
   return TIBRV_OK;
}


tibrv_status MsgDateTime_Create( SV * sv_date, tibrv_i64 sec, tibrv_u32 nsec )
{
   tibrvMsgDateTime * date =
      (tibrvMsgDateTime *)malloc( sizeof( tibrvMsgDateTime ) );
   if ( date == NULL ) return TIBRV_NO_MEMORY;
   date->sec = sec;
   date->nsec = nsec;
   sv_setiv( sv_date, (IV)date );
   return TIBRV_OK;
}


void MsgDateTime__GetValues( tibrvMsgDateTime * date, SV * sv_sec,
   SV * sv_nsec )
{
   sv_setiv( sv_sec, date->sec );
   sv_setuv( sv_nsec, date->nsec );
}


void MsgDateTime_SetSec( tibrvMsgDateTime * date, tibrv_i64 sec )
{
   date->sec = sec;
}


void MsgDateTime_SetNsec( tibrvMsgDateTime * date, tibrv_u32 nsec )
{
   date->nsec = nsec;
}


tibrv_status MsgDateTime_Destroy( tibrvMsgDateTime * date )
{
   free( date );
   return TIBRV_OK;
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
   sv_setuv( sv_count, (UV)count );
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
