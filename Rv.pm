package Tibco::Rv;


use vars qw/ $VERSION $TIBRV_VERSION_RELEASE /;

BEGIN
{
   $VERSION = '1.10';
   $TIBRV_VERSION_RELEASE = 7;
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
   AUTO_INCLUDE => <<END,
#include <tibrv/cm.h>
#define TIBRV_VERSION_RELEASE $TIBRV_VERSION_RELEASE
END
   AUTOWRAP => 'ENABLE',
   TYPEMAPS => 'typemap',
   LIBS => "-L$ENV{TIB_RV_HOME}/lib -ltibrv -ltibrvcm",
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

use constant WAIT_FOREVER => -1.0;
use constant NO_WAIT => 0.0;


use Tibco::Rv::Status;
use Tibco::Rv::Transport;
use Tibco::Rv::QueueGroup;
use Tibco::Rv::Cm::Transport;


sub die
{
   my ( $status ) = @_;
   $status = new Tibco::Rv::Status( status => $status )
      unless ( UNIVERSAL::isa( $status, 'Tibco::Rv::Status' ) );
   local( $Carp::CarpLevel ) = 1;
   croak 0+$status . ": $status\n";
}


sub version
{
   return 'tibrv ' . tibrv_Version( ) . '; tibrvcm ' . tibrvcm_Version( ) .
      "; Tibco::Rv $VERSION";
}


sub new
{
   my ( $proto ) = shift;
   my ( %params ) =
      ( service => undef, network => undef, daemon => 'tcp:7500' );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { processTransport => $Tibco::Rv::Transport::PROCESS,
      queue => $Tibco::Rv::Queue::DEFAULT, stop => 1, created => 1 }, $class;

   my ( $status ) = tibrv_Open( );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->{transport} = $self->createTransport( %params );
   $self->{queueGroup} = new Tibco::Rv::QueueGroup;
   $self->{queueGroup}->add( $self->{queue} );

   return $self;
}


sub processTransport { return shift->{processTransport} }
sub transport { return shift->{transport} }
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
sub createCmMsg { shift; return new Tibco::Rv::Cm::Msg( @_ ) }
sub createQueueGroup { shift; return new Tibco::Rv::QueueGroup( @_ ) }
sub createTransport { shift; return new Tibco::Rv::Transport( @_ ) }
sub createCmTransport { shift; return new Tibco::Rv::Cm::Transport( @_ ) }

sub createDispatcher { return shift->{queueGroup}->createDispatcher( @_ ) }
sub createQueue { return shift->{queueGroup}->createQueue( @_ ) }
sub add { shift->{queueGroup}->add( @_ ) }
sub remove { shift->{queueGroup}->remove( @_ ) }

sub createTimer { return shift->{queue}->createTimer( @_ ) }
sub createIO { return shift->{queue}->createIO( @_ ) }


sub createListener
{
   my ( $self, %args ) = @_;
   return
      $self->{queue}->createListener( transport => $self->{transport}, %args );
}


sub createCmListener
{
}


sub send { shift->{transport}->send( @_ ) }
sub sendReply { shift->{transport}->sendReply( @_ ) }
sub sendRequest { shift->{transport}->sendRequest( @_ ) }
sub createInbox { shift->{transport}->createInbox( @_ ) }


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{created} );

   my ( $status ) = tibrv_Close( );
   delete @$self{ keys %$self };
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
      $rv->createListener( subject => 'ABC', callback => sub
   {
      my ( $msg ) = @_;
      print "Listener got a message: $msg\n";
   } );

   my ( $timer ) = $rv->createTimer( timeout => 2, callback => sub
   {
      my ( $msg ) = $rv->createMsg;
      $msg->addString( field1 => 'myvalue' );
      $msg->addString( field2 => 'myothervalue' );
      $msg->sendSubject( 'ABC' );
      print "Timer kicking out a message: $msg\n";
      $rv->send( $msg );
   } );

   my ( $killTimer ) =
      $rv->createTimer( timeout => 7, callback => sub { $rv->stop } );

   $rv->start;
   print "finished\n"

=head1 DESCRIPTION

C<Tibco::Rv> provides bindings and Object-Oriented classes for TIBCO's
TIB/Rendezvous message passing C API.

All methods die with a L<Tibco::Rv::Status|Tibco::Rv::Status> message if
there are any TIB/Rendezvous errors.

=head1 CONSTRUCTOR

=over 4

=item $rv = new Tibco::Rv( %args )

   %args:
      service => $service,
      network => $network,
      daemon => $daemon

Creates a C<Tibco::Rv>, which is the top-level object that manages all your
TIB/Rendezvous needs.  There should only ever be one of these created.
Calling this method does the following: opens up the internal Rendezvous
machinery; creates objects for the Intra-Process Transport and the Default
Queue; creates a default QueueGroup and adds the Default Queue to it; and,
creates the Default Transport using the supplied service/network/daemon
arguments.  Supply C<undef> (or supply nothing) as the arguments to create a
Default Transport connection to a Rendezvous daemon running under the default
service/network/daemon settings.

See the Transport documentation section on the
L<Intra-Process Transport|Tibco::Rv::Transport/"INTRA-PROCESS TRANSPORT">
for information on the Intra-Process Transport.

See the Queue documentation section on the
L<Default Queue|Tibco::Rv::Queue/"DEFAULT QUEUE"> for information on the
Default Queue.

See L<Tibco::Rv::QueueGroup> for information on QueueGroups.

See your TIB/Rendezvous documentation for information on
service/network/daemon arguments and connecting to Rendezvous daemons, and
all other TIB/Rendezvous concepts.

=back

=head1 METHODS

=over 4

=item Tibco::Rv::die( $status )

Dies (raises an exception) with the given C<$status>.  C<$status> can either
be a L<Status|Tibco::Rv::Status> object, or one of the
L<Status Constants|"STATUS CONSTANTS"> (below).  The exception is of the form:

   %d: %s

... where '%d' is the status number, and '%s' is a description of the error.

All Tibco::Rv methods use this method to raise an exception when they
encounter a TIB/Rendezvous error.  Use an C<eval { .. }; if ( $@ )> block
around all Tibco::Rv code if you care about that sort of thing.

=item $ver = Tibco::Rv->version (or $ver = $rv->version)

Returns a string of the form:

   tibrv x.x.xx; tibrvcm y.y.yy; Tibco::Rv z.zz

where x.x.xx is the version of TIB/Rendezvous (the tibrv C library) that is
being used, y.y.yy is the version of TIB/Rv Certified Messaging (the tibrvcm
C library) that is being used, and z.zz is the version of Tibco::Rv (this Perl
 module) that is being used.

=item $transport = $rv->processTransport

Returns the Intra-Process Transport.

=item $transport = $rv->transport

Returns the Default Transport.

=item $queue = $rv->defaultQueue

Returns the Default Queue.

=item $queueGroup = $rv->defaultQueueGroup

Returns the Default QueueGroup.  The Default QueueGroup originally contains
only the Default Queue.

=item $rv->start

Begin processing events on the Default QueueGroup.  This call remains in
its own process loop until C<stop> is called.  Also, this call sets
up a signal handler for TERM and KILL signals, which calls C<stop>
when either of those signals are received.  It may also be useful to
create a Listener which listens to a special subject, which, when triggered,
calls C<stop>.

=item $rv->stop

Stops the process loop started by C<start>.  If the process loop is not
happening, this call does nothing.

=item $msg = $rv->createMsg

   %args:
      sendSubject => $sendSubject,
      replySubject => $replySubject,
      $fieldName1 => $stringValue1,
      $fieldName2 => $stringValue2, ...

Returns a new L<Msg|Tibco::Rv::Msg> object, with sendSubject and replySubject
as given in %args (sendSubject and replySubject default to C<undef> if not
specified).  Any other name => value pairs are added as string fields.

=item $queueGroup = $rv->createQueueGroup

Returns a new L<QueueGroup|Tibco::Rv::QueueGroup> object.

=item $transport = $rv->createTransport( %args )

   %args:
      service => $service,
      network => $network,
      daemon => $daemon

Returns a new L<Transport|Tibco::Rv::Transport> object, using the given
service/network/daemon arguments.  These arguments can be C<undef> or
not specified to use the default arguments.

=item $dispatcher = $rv->createDispatcher( %args )

   %args:
      idleTimeout => $idleTimeout

Returns a new L<Dispatcher|Tibco::Rv::Dispatcher> object to dispatch on the
Default QueueGroup, with the given idleTimeout argument (idleTimeout
defaults to C<Tibco::Rv::WAIT_FOREVER> if it is C<undef> or not specified).

=item $queue = $rv->createQueue

Returns a new L<Queue|Tibco::Rv::Queue> object, added to the Default
QueueGroup.

=item $rv->add( $queue )

Add C<$queue> to the Default QueueGroup.

=item $rv->remove( $queue )

Remove C<$queue> from the Default QueueGroup.

=item $timer = $rv->createTimer( %args )

   %args:
      interval => $interval,
      callback => sub { ... }

Returns a new L<Timer|Tibco::Rv::Timer> object with the Default Queue and
given interval, callback arguments.

=item $io = $rv->createIO( %args )

   %args:
      socketId => $socketId,
      ioType => $ioType,
      callback => sub { ... }

Returns a new L<IO|Tibco::Rv::IO> object with the Default Queue and
given socketId, ioType, callback arguments.

=item $listener = $rv->createListener( %args )

   %args:
      subject => $subject,
      callback => sub { ... }

Returns a new L<Listener|Tibco::Rv::Listener> object with the Default Queue,
the Default Transport, and the given subject, callback arguments.

=item $rv->send( $msg )

Sends C<$msg> via the Default Transport.

=item $reply = $rv->sendRequest( $request, $timeout )

Sends the given C<$request> message via the Default Transport, using the
given C<$timeout>.  C<$timeout> defaults to Tibco::Rv::WAIT_FOREVER if given
as C<undef> or not specified.  Returns the C<$reply> message, or C<undef>
if the timeout is reached before receiving a reply.

=item $rv->sendReply( $reply, $request )

Sends the given C<$reply> message in response to the given C<$request> message
via the Default Transport.

=item $inbox = $rv->createInbox

Returns a new C<$inbox> subject.  See L<Tibco::Rv::Msg|Tibco::Rv::Msg> for
a more detailed discussion of sendRequest, sendReply, and createInbox.

=item $cmMsg = $rv->createCmMsg

   %args:
      sendSubject => $sendSubject,
      replySubject => $replySubject,
      $fieldName1 => $stringValue1,
      $fieldName2 => $stringValue2, ...

Returns a new L<CmMsg|Tibco::Rv::Cm::Msg> object, with sendSubject and
replySubject as given in %args (sendSubject and replySubject default to
C<undef> if not specified).  Any other name => value pairs are added as
string fields.

... other args ... ??

=item $cmTransport = $rv->createCmTransport( %args )

   %args:
      service => $service,
      network => $network,
      daemon => $daemon

Returns a new L<CmTransport|Tibco::Rv::Cm::Transport> object, using the given
service/network/daemon arguments.  These arguments can be C<undef> or
not specified to use the default arguments.

... plenty of other args ...

=item $rv->DESTROY

Closes the TIB/Rendezvous machinery.  DESTROY is called automatically when
C<$rv> goes out of scope, but you may also call it explicitly.  All Tibco
objects that you have created are invalidated (except for Tibco::Rv::Msg
objects).  Nothing will happen if DESTROY is called on an already-destroyed
C<$rv>.

=back

=head1 STATUS CONSTANTS

=over 4

=item Tibco::Rv::OK => 0

=item Tibco::Rv::INIT_FAILURE => 1

=item Tibco::Rv::INVALID_TRANSPORT => 2

=item Tibco::Rv::INVALID_ARG => 3

=item Tibco::Rv::NOT_INITIALIZED => 4

=item Tibco::Rv::ARG_CONFLICT => 5

=item Tibco::Rv::SERVICE_NOT_FOUND => 16

=item Tibco::Rv::NETWORK_NOT_FOUND => 17

=item Tibco::Rv::DAEMON_NOT_FOUND => 18

=item Tibco::Rv::NO_MEMORY => 19

=item Tibco::Rv::INVALID_SUBJECT => 20

=item Tibco::Rv::DAEMON_NOT_CONNECTED => 21

=item Tibco::Rv::VERSION_MISMATCH => 22

=item Tibco::Rv::SUBJECT_COLLISION => 23

=item Tibco::Rv::VC_NOT_CONNECTED => 24

=item Tibco::Rv::NOT_PERMITTED => 27

=item Tibco::Rv::INVALID_NAME => 30

=item Tibco::Rv::INVALID_TYPE => 31

=item Tibco::Rv::INVALID_SIZE => 32

=item Tibco::Rv::INVALID_COUNT => 33

=item Tibco::Rv::NOT_FOUND => 35

=item Tibco::Rv::ID_IN_USE => 36

=item Tibco::Rv::ID_CONFLICT => 37

=item Tibco::Rv::CONVERSION_FAILED => 38

=item Tibco::Rv::RESERVED_HANDLER => 39

=item Tibco::Rv::ENCODER_FAILED => 40

=item Tibco::Rv::DECODER_FAILED => 41

=item Tibco::Rv::INVALID_MSG => 42

=item Tibco::Rv::INVALID_FIELD => 43

=item Tibco::Rv::INVALID_INSTANCE => 44

=item Tibco::Rv::CORRUPT_MSG => 45

=item Tibco::Rv::TIMEOUT => 50

=item Tibco::Rv::INTR => 51

=item Tibco::Rv::INVALID_DISPATCHABLE => 52

=item Tibco::Rv::INVALID_DISPATCHER => 53

=item Tibco::Rv::INVALID_EVENT => 60

=item Tibco::Rv::INVALID_CALLBACK => 61

=item Tibco::Rv::INVALID_QUEUE => 62

=item Tibco::Rv::INVALID_QUEUE_GROUP => 63

=item Tibco::Rv::INVALID_TIME_INTERVAL => 64

=item Tibco::Rv::INVALID_IO_SOURCE => 65

=item Tibco::Rv::INVALID_IO_CONDITION => 66

=item Tibco::Rv::SOCKET_LIMIT => 67

=item Tibco::Rv::OS_ERROR => 68

=item Tibco::Rv::INSUFFICIENT_BUFFER => 70

=item Tibco::Rv::EOF => 71

=item Tibco::Rv::INVALID_FILE => 72

=item Tibco::Rv::FILE_NOT_FOUND => 73

=item Tibco::Rv::IO_FAILED => 74

=item Tibco::Rv::NOT_FILE_OWNER => 80

=item Tibco::Rv::TOO_MANY_NEIGHBORS => 90

=item Tibco::Rv::ALREADY_EXISTS => 91

=item Tibco::Rv::PORT_BUSY => 100

=back

=head1 OTHER CONSTANTS

=over 4

=item Tibco::Rv::SUBJECT_MAX => 255

Maximum length of a subject

=item Tibco::Rv::SUBJECT_TOKEN_MAX => 127

Maximum number of tokens a subject can contain

=item Tibco::Rv::FALSE => 0

Boolean false

=item Tibco::Rv::TRUE => 1

Boolean true

=item Tibco::Rv::WAIT_FOREVER => -1.0

Blocking wait on event dispatch calls (waits until an event occurs)

=item Tibco::Rv::NO_WAIT => 0.0

Non-blocking wait on event dispatch calls (returns immediately)

=item Tibco::Rv::VERSION => <this version>

Programmatically access the installed version of Tibco::Rv, in the form 'x.xx'

=item Tibco::Rv::TIBRV_VERSION_RELEASE => <build option>

Programmatically access the major version of TIB/Rendezvous.  For instance,
TIBRV_VERSION_RELEASE = 7 for all releases in the Rv 7.x series, or 6 for
all releases in the Rv 6.x series.  This allows for backwards compatibility
when building Tibco::Rv against any version of tibrv, 6.x or later.

If Tibco::Rv is built against an Rv 6.x release, then using any function
available only in Rv 7.x will die with a Tibco::Rv::VERSION_MISMATCH Status
message.

=back

=head1 SEE ALSO

=over 4

=item L<Tibco::Rv::Status>

=item L<Tibco::Rv::Event>

=item L<Tibco::Rv::QueueGroup>

=item L<Tibco::Rv::Queue>

=item L<Tibco::Rv::Dispatcher>

=item L<Tibco::Rv::Transport>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Paul Sturm.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

Tibco::Rv will not operate without TIB/Rendezvous, which is not included
in this distribution.  You must obtain TIB/Rendezvous (and a license to use
it) from TIBCO, Inc. (http://www.tibco.com).

TIBCO and TIB/Rendezvous are trademarks of TIBCO, Inc.

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

=cut


__C__


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
tibrv_status tibrvTransport_SetDescription( tibrvTransport transport,
   const char * description );
tibrv_status tibrvTransport_Send( tibrvTransport transport, tibrvMsg message );
tibrv_status tibrvTransport_SendReply( tibrvTransport transport,
   tibrvMsg reply, tibrvMsg request ); 
#if TIBRV_VERSION_RELEASE >= 7
tibrv_status tibrvTransport_SetBatchMode( tibrvTransport transport,
   tibrvTransportBatchMode mode ); 
#endif
tibrv_status tibrvTransport_Destroy( tibrvTransport transport );

const char * tibrvcm_Version( );
tibrv_status tibrvcmTransport_Destroy( tibrvcmTransport cmTransport );
tibrv_status tibrvcmTransport_SetDefaultCMTimeLimit(
   tibrvcmTransport cmTransport, tibrv_f64 timeLimit );
tibrv_status tibrvcmTransport_Send( tibrvcmTransport cmTransport,
   tibrvMsg message );
tibrv_status tibrvcmTransport_SendReply( tibrvcmTransport cmTransport,
   tibrvMsg reply, tibrvMsg request ); 
tibrv_status tibrvcmTransport_AddListener( tibrvcmTransport cmTransport,
   const char * cmName, const char * subject ); 
tibrv_status tibrvcmTransport_AllowListener( tibrvcmTransport cmTransport,
   const char * cmName ); 
tibrv_status tibrvcmTransport_DisallowListener( tibrvcmTransport cmTransport,
   const char * cmName ); 
tibrv_status tibrvcmTransport_RemoveListener( tibrvcmTransport cmTransport,
   const char * cmName, const char * subject ); 
tibrv_status tibrvcmTransport_ConnectToRelayAgent(
   tibrvcmTransport cmTransport );
tibrv_status tibrvcmTransport_DisconnectFromRelayAgent(
   tibrvcmTransport cmTransport ); 
tibrv_status tibrvcmTransport_RemoveSendState( tibrvcmTransport cmTransport,
   const char * subject ); 
tibrv_status tibrvcmTransport_SyncLedger( tibrvcmTransport cmTransport ); 
tibrv_status tibrvcmEvent_SetExplicitConfirm( tibrvcmEvent cmListener ); 
tibrv_status tibrvcmEvent_ConfirmMsg( tibrvcmEvent cmListener,
   tibrvMsg message );
tibrv_status tibrvMsg_SetCMTimeLimit( tibrvMsg message, tibrv_f64 timeLimit ); 


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


void Msg_GetValues( tibrvMsg message, SV * sv_sendSubject,
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
         sv_setuv( sv_value, (UV)ntohl( ipaddr32 ) );
      } break;
      case TIBRVMSG_IPPORT16: {
         tibrv_ipport16 ipport16;
         status =
            tibrvMsg_GetIPPort16Ex( message, fieldName, &ipport16, fieldId );
         sv_setuv( sv_value, (UV)ntohs( ipport16 ) );
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


tibrv_status Msg_GetArray( tibrvMsg message, tibrv_u8 type, const char * name,
   SV * elts, tibrv_u16 id )
{
   int i = 0;
   tibrv_status status = TIBRV_OK;
   tibrv_u32 n = 0;
   AV * e = (AV *)SvRV( elts );

   switch ( type )
   {
      case TIBRVMSG_F32ARRAY: {
         const tibrv_f32 * f32s;
         status = tibrvMsg_GetF32ArrayEx( message, name, &f32s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSVnv( f32s[ i ] ) );
      } break;
      case TIBRVMSG_F64ARRAY: {
         const tibrv_f64 * f64s;
         status = tibrvMsg_GetF64ArrayEx( message, name, &f64s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSVnv( f64s[ i ] ) );
      } break;
      case TIBRVMSG_I8ARRAY: {
         const tibrv_i8 * i8s;
         status = tibrvMsg_GetI8ArrayEx( message, name, &i8s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i8s[ i ] ) );
      } break;
      case TIBRVMSG_I16ARRAY: {
         const tibrv_i16 * i16s;
         status = tibrvMsg_GetI16ArrayEx( message, name, &i16s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i16s[ i ] ) );
      } break;
      case TIBRVMSG_I32ARRAY: {
         const tibrv_i32 * i32s;
         status = tibrvMsg_GetI32ArrayEx( message, name, &i32s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i32s[ i ] ) );
      } break;
      case TIBRVMSG_I64ARRAY: {
         const tibrv_i64 * i64s;
         status = tibrvMsg_GetI64ArrayEx( message, name, &i64s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( i64s[ i ] ) );
      } break;
      case TIBRVMSG_U8ARRAY: {
         const tibrv_u8 * u8s;
         status = tibrvMsg_GetU8ArrayEx( message, name, &u8s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u8s[ i ] ) );
      } break;
      case TIBRVMSG_U16ARRAY: {
         const tibrv_u16 * u16s;
         status = tibrvMsg_GetU16ArrayEx( message, name, &u16s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u16s[ i ] ) );
      } break;
      case TIBRVMSG_U32ARRAY: {
         const tibrv_u32 * u32s;
         status = tibrvMsg_GetU32ArrayEx( message, name, &u32s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u32s[ i ] ) );
      } break;
      case TIBRVMSG_U64ARRAY: {
         const tibrv_u64 * u64s;
         status = tibrvMsg_GetU64ArrayEx( message, name, &u64s, &n, id );
         av_extend( e, n );
         for ( i = 0; i < n; i ++ ) av_store( e, i, newSViv( u64s[ i ] ) );
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


tibrv_status Msg_AddIPAddr32( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId )
{
   return tibrvMsg_AddIPAddr32Ex( message, fieldName, htonl( value ), fieldId );
}


tibrv_status Msg_AddIPPort16( tibrvMsg message, const char * fieldName,
   tibrv_ipport16 value, tibrv_u16 fieldId )
{
   return tibrvMsg_AddIPPort16Ex( message, fieldName, htons( value ), fieldId );
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


tibrv_status Msg_AddOrUpdateArray( tibrvMsg message, tibrv_bool isAdd,
   tibrv_u8 type, const char * fieldName, SV * elts, tibrv_u16 fieldId )
{
   tibrv_status status = TIBRV_OK;
   I32 len;
   AV * e;
   int i;
   if ( SvTYPE( SvRV( elts ) ) != SVt_PVAV ) return TIBRV_INVALID_ARG;
   e = (AV *)SvRV( elts );

   len = av_len( e ) + 1;
   if ( len == 0 ) return TIBRV_OK;
   switch ( type )
   {
      case TIBRVMSG_F32ARRAY: {
         tibrv_f32 f32s[ len ];
         for ( i = 0; i < len; i ++ ) f32s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddF32ArrayEx( message, fieldName, f32s, len, fieldId ) :
            tibrvMsg_UpdateF32ArrayEx( message, fieldName, f32s, len, fieldId );
      } break;
      case TIBRVMSG_F64ARRAY: {
         tibrv_f64 f64s[ len ];
         for ( i = 0; i < len; i ++ ) f64s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddF64ArrayEx( message, fieldName, f64s, len, fieldId ) :
            tibrvMsg_UpdateF64ArrayEx( message, fieldName, f64s, len, fieldId );
      } break;
      case TIBRVMSG_I8ARRAY: {
         tibrv_i8 i8s[ len ];
         for ( i = 0; i < len; i ++ ) i8s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI8ArrayEx( message, fieldName, i8s, len, fieldId ) :
            tibrvMsg_UpdateI8ArrayEx( message, fieldName, i8s, len, fieldId );
      } break;
      case TIBRVMSG_I16ARRAY: {
         tibrv_i16 i16s[ len ];
         for ( i = 0; i < len; i ++ ) i16s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI16ArrayEx( message, fieldName, i16s, len, fieldId ) :
            tibrvMsg_UpdateI16ArrayEx( message, fieldName, i16s, len, fieldId );
      } break;
      case TIBRVMSG_I32ARRAY: {
         tibrv_i32 i32s[ len ];
         for ( i = 0; i < len; i ++ ) i32s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI32ArrayEx( message, fieldName, i32s, len, fieldId ) :
            tibrvMsg_UpdateI32ArrayEx( message, fieldName, i32s, len, fieldId );
      } break;
      case TIBRVMSG_I64ARRAY: {
         tibrv_i64 i64s[ len ];
         for ( i = 0; i < len; i ++ ) i64s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddI64ArrayEx( message, fieldName, i64s, len, fieldId ) :
            tibrvMsg_UpdateI64ArrayEx( message, fieldName, i64s, len, fieldId );
      } break;
      case TIBRVMSG_U8ARRAY: {
         tibrv_u8 u8s[ len ];
         for ( i = 0; i < len; i ++ ) u8s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU8ArrayEx( message, fieldName, u8s, len, fieldId ) :
            tibrvMsg_UpdateU8ArrayEx( message, fieldName, u8s, len, fieldId );
      } break;
      case TIBRVMSG_U16ARRAY: {
         tibrv_u16 u16s[ len ];
         for ( i = 0; i < len; i ++ ) u16s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU16ArrayEx( message, fieldName, u16s, len, fieldId ) :
            tibrvMsg_UpdateU16ArrayEx( message, fieldName, u16s, len, fieldId );
      } break;
      case TIBRVMSG_U32ARRAY: {
         tibrv_u32 u32s[ len ];
         for ( i = 0; i < len; i ++ ) u32s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU32ArrayEx( message, fieldName, u32s, len, fieldId ) :
            tibrvMsg_UpdateU32ArrayEx( message, fieldName, u32s, len, fieldId );
      } break;
      case TIBRVMSG_U64ARRAY: {
         tibrv_u64 u64s[ len ];
         for ( i = 0; i < len; i ++ ) u64s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         status = isAdd ?
            tibrvMsg_AddU64ArrayEx( message, fieldName, u64s, len, fieldId ) :
            tibrvMsg_UpdateU64ArrayEx( message, fieldName, u64s, len, fieldId );
      } break;
   }

   return status;
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


tibrv_status Msg_UpdateIPAddr32( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId )
{
   return
      tibrvMsg_UpdateIPAddr32Ex( message, fieldName, htonl( value ), fieldId );
}


tibrv_status Msg_UpdateIPPort16( tibrvMsg message, const char * fieldName,
   tibrv_ipaddr32 value, tibrv_u16 fieldId )
{
   return
      tibrvMsg_UpdateIPPort16Ex( message, fieldName, htons( value ), fieldId );
}


tibrv_status MsgDateTime_Create( SV * sv_date, tibrv_i64 sec, tibrv_u32 nsec );


tibrv_status MsgField_Create( SV * sv_field, const char * name, tibrv_u16 id )
{
   tibrvMsgField * field = (tibrvMsgField *)malloc( sizeof( tibrvMsgField ) );
   if ( field == NULL ) return TIBRV_NO_MEMORY;

   field->name = name;
   field->id = id;

   sv_setiv( sv_field, (IV)field );
   return TIBRV_OK;
}


void MsgField_GetArrayValue( tibrvMsgField * field, SV * sv_data )
{
   int i;
   AV * e = newAV( );
   av_extend( e, field->count );

   switch ( field->type )
   {
      case TIBRVMSG_F32ARRAY: {
         tibrv_f32 * f32s = (tibrv_f32 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSVnv( f32s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_F64ARRAY: {
         tibrv_f64 * f64s = (tibrv_f64 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSVnv( f64s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I8ARRAY: {
         tibrv_i8 * i8s = (tibrv_i8 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i8s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I16ARRAY: {
         tibrv_i16 * i16s = (tibrv_i16 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i16s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I32ARRAY: {
         tibrv_i32 * i32s = (tibrv_i32 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i32s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_I64ARRAY: {
         tibrv_i64 * i64s = (tibrv_i64 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( i64s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U8ARRAY: {
         tibrv_u8 * u8s = (tibrv_u8 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u8s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U16ARRAY: {
         tibrv_u16 * u16s = (tibrv_u16 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u16s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U32ARRAY: {
         tibrv_u32 * u32s = (tibrv_u32 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u32s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
      case TIBRVMSG_U64ARRAY: {
         tibrv_u64 * u64s = (tibrv_u64 *)field->data.array;
         for ( i = 0; i < field->count; i ++ )
         {
            SV * elt = newSViv( u64s[ i ] );
            SvREFCNT_inc( elt );
            if ( av_store( e, i, elt ) == NULL ) SvREFCNT_dec( elt );
         }
      } break;
   }
   sv_setsv( sv_data, newRV( (SV *)e ) );
}


void MsgField_GetValues( tibrvMsgField * field, SV * sv_name, SV * sv_id,
   SV * sv_size, SV * sv_count, SV * sv_type, SV * sv_data )
{
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
      case TIBRVMSG_U8ARRAY:
      case TIBRVMSG_I16ARRAY:
      case TIBRVMSG_U16ARRAY:
      case TIBRVMSG_I32ARRAY:
      case TIBRVMSG_U32ARRAY:
      case TIBRVMSG_I64ARRAY:
      case TIBRVMSG_U64ARRAY:
      case TIBRVMSG_F32ARRAY:
      case TIBRVMSG_F64ARRAY: {
         size_t len = field->size * field->count;
         void * array = malloc( len );
         if ( array == NULL )
         {
            field->size = field->count = 0;
            break;
         }
         field->data.array = memcpy( array, field->data.array, len );
         MsgField_GetArrayValue( field, sv_data );
      } break;
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
         sv_setuv( sv_data, (UV)ntohs( field->data.ipport16 ) );
      break;
      case TIBRVMSG_IPADDR32:
         sv_setuv( sv_data, (UV)ntohl( field->data.ipaddr32 ) );
      break;
      case TIBRVMSG_DATETIME:
         MsgDateTime_Create( sv_data, (IV)field->data.date.sec,
            (UV)field->data.date.nsec );
      break;
   }
   if ( ! field->name ) field->name = strdup( "" );
   sv_setpv( sv_name, field->name );
   sv_setuv( sv_id, (UV)field->id );
   sv_setuv( sv_size, (UV)field->size );
   sv_setuv( sv_count, (UV)field->count );
   sv_setuv( sv_type, (UV)field->type );
}


void MsgField_SetName( tibrvMsgField * field, const char * name )
{
   field->name = name;
}


void MsgField_SetId( tibrvMsgField * field, tibrv_u16 id )
{
   field->id = id;
}


void MsgField_CheckDelOldArray( tibrvMsgField * field )
{
   switch ( field->type )
   {
      case TIBRVMSG_F32ARRAY:
      case TIBRVMSG_F64ARRAY:
      case TIBRVMSG_I8ARRAY:
      case TIBRVMSG_I16ARRAY:
      case TIBRVMSG_I32ARRAY:
      case TIBRVMSG_I64ARRAY:
      case TIBRVMSG_U8ARRAY:
      case TIBRVMSG_U16ARRAY:
      case TIBRVMSG_U32ARRAY:
      case TIBRVMSG_U64ARRAY:
         free( (void *)field->data.array );
         field->data.array = NULL;
   }
}


tibrv_u32 MsgField_SetMsg( tibrvMsgField * field, tibrvMsg message )
{
   MsgField_CheckDelOldArray( field );
   field->data.msg = message;
   field->size = 0;
   tibrvMsg_GetByteSize( message, &field->size );
   field->count = 1;
   field->type = TIBRVMSG_MSG;

   return field->size;
}


tibrv_u32 MsgField_SetBuf( tibrvMsgField * field, tibrv_u8 type, SV * sv_buf )
{
   STRLEN len;
   char * buf = SvPV( sv_buf, len );
   MsgField_CheckDelOldArray( field );
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


tibrv_u32 MsgField_SetElt( tibrvMsgField * field, tibrv_u8 type, SV * sv_elt )
{
   MsgField_CheckDelOldArray( field );
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
         field->data.ipaddr32 = htonl( SvUV( sv_elt ) );
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


tibrv_u32 MsgField_SetAry( tibrvMsgField * field, tibrv_u8 type, SV * sv_ary )
{
   AV * e;
   I32 len = 0;
   int i;
   MsgField_CheckDelOldArray( field );

   if ( SvTYPE( SvRV( sv_ary ) ) != SVt_PVAV ) return 0;

   e = (AV *)SvRV( sv_ary );
   field->count = len = av_len( e ) + 1;
   field->type = type;
   field->size = 0;

   switch ( type )
   {
      case TIBRVMSG_F32ARRAY: {
         tibrv_f32 * f32s = (tibrv_f32 *)malloc( len * sizeof( tibrv_f32 ) );
         if ( f32s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) f32s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         field->data.array = f32s;
         field->size = sizeof( tibrv_f32 );
      } break;
      case TIBRVMSG_F64ARRAY: {
         tibrv_f64 * f64s = (tibrv_f64 *)malloc( len * sizeof( tibrv_f64 ) );
         if ( f64s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) f64s[ i ] = SvNV( *av_fetch( e, i, 0 ) );
         field->data.array = f64s;
         field->size = sizeof( tibrv_f64 );
      } break;
      case TIBRVMSG_I8ARRAY: {
         tibrv_i8 * i8s = (tibrv_i8 *)malloc( len * sizeof( tibrv_i8 ) );
         if ( i8s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i8s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i8s;
         field->size = sizeof( tibrv_i8 );
      } break;
      case TIBRVMSG_I16ARRAY: {
         tibrv_i16 * i16s = (tibrv_i16 *)malloc( len * sizeof( tibrv_i16 ) );
         if ( i16s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i16s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i16s;
         field->size = sizeof( tibrv_i16 );
      } break;
      case TIBRVMSG_I32ARRAY: {
         tibrv_i32 * i32s = (tibrv_i32 *)malloc( len * sizeof( tibrv_i32 ) );
         if ( i32s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i32s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i32s;
         field->size = sizeof( tibrv_i32 );
      } break;
      case TIBRVMSG_I64ARRAY: {
         tibrv_i64 * i64s = (tibrv_i64 *)malloc( len * sizeof( tibrv_i64 ) );
         if ( i64s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) i64s[ i ] = SvIV( *av_fetch( e, i, 0 ) );
         field->data.array = i64s;
         field->size = sizeof( tibrv_i64 );
      } break;
      case TIBRVMSG_U8ARRAY: {
         tibrv_u8 * u8s = (tibrv_u8 *)malloc( len * sizeof( tibrv_u8 ) );
         if ( u8s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u8s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u8s;
         field->size = sizeof( tibrv_u8 );
      } break;
      case TIBRVMSG_U16ARRAY: {
         tibrv_u16 * u16s = (tibrv_u16 *)malloc( len * sizeof( tibrv_u16 ) );
         if ( u16s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u16s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u16s;
         field->size = sizeof( tibrv_u16 );
      } break;
      case TIBRVMSG_U32ARRAY: {
         tibrv_u32 * u32s = (tibrv_u32 *)malloc( len * sizeof( tibrv_u32 ) );
         if ( u32s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u32s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u32s;
         field->size = sizeof( tibrv_u32 );
      } break;
      case TIBRVMSG_U64ARRAY: {
         tibrv_u64 * u64s = (tibrv_u64 *)malloc( len * sizeof( tibrv_u64 ) );
         if ( u64s == NULL ) return 0;
         for ( i = 0; i < len; i ++ ) u64s[ i ] = SvUV( *av_fetch( e, i, 0 ) );
         field->data.array = u64s;
         field->size = sizeof( tibrv_u64 );
      } break;
   }
   return field->size;
}


tibrv_u32 MsgField_SetDateTime( tibrvMsgField * field,
   tibrvMsgDateTime * date )
{
   MsgField_CheckDelOldArray( field );
   field->data.date.sec = date->sec;
   field->data.date.nsec = date->nsec;
   field->count = 1;
   field->type = TIBRVMSG_DATETIME;

   return field->size = sizeof( tibrvMsgDateTime );
}


tibrv_status MsgField_Destroy( tibrvMsgField * field )
{
   MsgField_CheckDelOldArray( field );
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


void MsgDateTime_GetValues( tibrvMsgDateTime * date, SV * sv_sec,
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
 * and have a "completionCallback" argument in constructor
 */
tibrv_status Event_DestroyEx( tibrvEvent event )
{
   return tibrvEvent_DestroyEx( event, NULL );
}


tibrv_status cmEvent_DestroyEx( tibrvcmEvent cmEvent,
   tibrv_bool cancelAgreements )
{
   return tibrvcmEvent_DestroyEx( cmEvent, cancelAgreements, NULL );
}


static void onEventMsg( tibrvEvent event, tibrvMsg message, void * closure )
{
   callback_perl_msg( (SV *)closure, message );
}


static void onEventCmMsg( tibrvcmEvent event, tibrvMsg message, void * closure )
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


tibrv_status cmTransport_Create( SV * sv_cmTransport, tibrvTransport transport,
   SV * sv_cmName, tibrv_bool requestOld, SV * sv_ledgerName,
   tibrv_bool syncLedger, SV * sv_relayAgent )
{
   const char * cmName = NULL;
   const char * ledgerName = NULL;
   const char * relayAgent = NULL;
   tibrvcmTransport cmTransport = (tibrvcmTransport)NULL;
   tibrv_status status;

   if ( SvOK( sv_cmName ) ) cmName = SvPV( sv_cmName, PL_na );
   if ( SvOK( sv_ledgerName ) ) ledgerName = SvPV( sv_ledgerName, PL_na );
   if ( SvOK( sv_relayAgent ) ) relayAgent = SvPV( sv_relayAgent, PL_na );

   status = tibrvcmTransport_Create( &cmTransport, transport, cmName,
      requestOld, ledgerName, syncLedger, relayAgent );
   sv_setiv( sv_cmTransport, (IV)cmTransport );
   return status;
}


void cmTransport_GetName( tibrvcmTransport cmTransport, SV * sv_cmName )
{
   const char * cmName;
   tibrvcmTransport_GetName( cmTransport, &cmName );
   sv_setpv( sv_cmName, cmName );
}


tibrv_status cmTransport_SendRequest( tibrvcmTransport cmTransport,
   tibrvMsg request, SV * sv_reply, tibrv_f64 timeout )
{
   tibrvMsg reply = (tibrvMsg)NULL;
   tibrv_status status =
      tibrvcmTransport_SendRequest( cmTransport, request, &reply, timeout );
   sv_setiv( sv_reply, (IV)reply );
   return status;
}


static void * onLedgerSubject( tibrvcmTransport cmTransport,
   const char * subject, tibrvMsg message, void * closure )
{
   tibrvMsg copy = NULL;
   tibrv_status status = tibrvMsg_CreateCopy( message, &copy );
   if ( status == TIBRV_OK ) callback_perl_msg( (SV *)closure, copy );
   return NULL;
}


tibrv_status cmTransport_ReviewLedger( tibrvcmTransport cmTransport,
   const char * subject, SV * callback )
{
   return tibrvcmTransport_ReviewLedger( cmTransport, onLedgerSubject, subject,
      callback );
}


tibrv_status cmEvent_CreateListener( SV * sv_event, tibrvQueue queue,
   SV * callback, tibrvcmTransport transport, const char * subject )
{
   tibrvEvent event = (tibrvEvent)NULL;
   tibrv_status status = tibrvcmEvent_CreateListener( &event, queue,
      onEventCmMsg, transport, subject, callback );
   sv_setiv( sv_event, (IV)event );
   return status;
}


void Msg_GetCMValues( tibrvMsg message, SV * sv_CMSender, SV * sv_CMSequence,
   SV * sv_CMTimeLimit )
{
   const char * CMSender = NULL;
   tibrv_u64 CMSequence = 0;
   tibrv_f64 CMTimeLimit = 0.0;

   if ( tibrvMsg_GetCMSender( message, &CMSender ) == TIBRV_OK )
      sv_setpv( sv_CMSender, CMSender );
   if ( tibrvMsg_GetCMSequence( message, &CMSequence ) == TIBRV_OK )
      sv_setuv( sv_CMSequence, (UV)CMSequence );
   if ( tibrvMsg_GetCMTimeLimit( message, &CMTimeLimit ) == TIBRV_OK )
      sv_setnv( sv_CMTimeLimit, CMTimeLimit );
}
