package Tibco::Rv::Cm::Transport;


use vars qw/ $VERSION /;
$VERSION = '1.10';


use Tibco::Rv::Transport;
use Tibco::Rv::Cm::Msg;
use Tibco::Rv::Msg;


my ( %defaults );
BEGIN
{
   %defaults = ( transport => undef, cmName => undef,
      requestOld => Tibco::Rv::FALSE, ledgerName => undef,
      syncLedger => Tibco::Rv::FALSE, relayAgent => undef,
      defaultCMTimeLimit => 0 );
}


sub new
{
   my ( $proto ) = shift;
   my ( %args ) = @_;
   $args{transport} = new Tibco::Rv::Transport( service => $args{service},
      network => $args{network}, daemon => $args{daemon} )
         unless ( exists $args{transport} and defined $args{transport} );
   delete @args{ qw/ service network daemon / };
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $defaults{$_} ) } keys %args;
   my ( %params ) = ( %defaults, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   @$self{ keys %defaults } = @params{ keys %defaults };

   my ( $status ) =
      Tibco::Rv::cmTransport_Create( $self->{id}, $self->{transport}{id},
         @$self{ qw/ cmName requestOld ledgerName syncLedger relayAgent / } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->_getName unless ( defined $self->{cmName} );
   $self->defaultCMTimeLimit( $self->{defaultCMTimeLimit} )
      if ( $self->{defaultCMTimeLimit} != 0 );

   return $self;
}


sub _getName
{
   my ( $self ) = @_;
   Tibco::Rv::cmTransport_GetName( @$self{ qw/ id cmName / } );
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
}


sub name { return shift->{cmName} }
sub ledgerName { return shift->{ledgerName} }
sub relayAgent { return shift->{relayAgent} }
sub requestOld { return shift->{requestOld} }
sub syncLedger { return shift->{syncLedger} }
sub transport { return shift->{transport} }


sub defaultCMTimeLimit
{
   my ( $self ) = shift;
   return @_ ?
      $self->_setDefaultCMTimeLimit( @_ ) : $self->{defaultCMTimeLimit};
}


sub service { return shift->{transport}->service( @_ ) }
sub network { return shift->{transport}->transport( @_ ) }
sub daemon { return shift->{transport}->daemon( @_ ) }
sub description { return shift->{transport}->description( @_ ) }
sub batchMode { return shift->{transport}->batchMode( @_ ) }
sub createInbox { return shift->{transport}->createInbox( @_ ) }


sub _setDefaultCMTimeLimit
{
   my ( $self, $defaultCMTimeLimit ) = @_;
   my ( $status ) = Tibco::Rv::tibrvcmTransport_SetDefaultCMTimeLimit(
      $self->{id}, $defaultCMTimeLimit );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{defaultCMTimeLimit} = $defaultCMTimeLimit;
}


sub send
{
   my ( $self, $msg ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_Send( $self->{id}, $msg->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sendReply
{
   my ( $self, $reply, $request ) = @_;
   my ( $status ) = Tibco::Rv::tibrvTransport_SendReply( $self->{id},
      $reply->{id}, $request->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sendRequest
{
   my ( $self, $request, $timeout ) = @_;
   $timeout = Tibco::Rv::WAIT_FOREVER unless ( defined $timeout );
   my ( $reply );
   my ( $status ) = Tibco::Rv::cmTransport_SendRequest( $self->{id},
      $request->{id}, $reply, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Cm::Msg->_adopt( $reply ) : undef;
}


sub addListener
{
   my ( $self, $cmName, $subject ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_AddListener( $self->{id}, $cmName, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::NOT_PERMITTED );
   return new Tibco::Rv::Status( status => $status );
}


sub allowListener
{
   my ( $self, $cmName ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_AllowListener( $self->{id}, $cmName );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub disallowListener
{
   my ( $self, $cmName ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_DisallowListener( $self->{id}, $cmName );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub removeListener
{
   my ( $self, $cmName, $subject ) = @_;
   my ( $status ) = Tibco::Rv::tibrvcmTransport_RemoveListener(
      $self->{id}, $cmName, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_SUBJECT );
   return new Tibco::Rv::Status( status => $status );
}


sub removeSendState
{
   my ( $self, $subject ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_RemoveSendState( $self->{id}, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub sync
{
   my ( $self ) = @_;
   my ( $status ) = Tibco::Rv::tibrvcmTransport_SyncLedger( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_ARG );
   return new Tibco::Rv::Status( status => $status );
}


sub reviewLedger
{
   my ( $self, $subject, $callback ) = @_;
   my ( $status ) = Tibco::Rv::cmTransport_ReviewLedger( $self->{id},
      $subject, sub { $callback->( Tibco::Rv::Msg->_adopt( shift ) ) } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub connectToRelayAgent
{
   my ( $self ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_ConnectToRelayAgent( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_ARG );
   return new Tibco::Rv::Status( status => $status );
}


sub disconnectFromRelayAgent
{
   my ( $self ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvcmTransport_DisconnectFromRelayAgent( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK
      or $status == Tibco::Rv::INVALID_ARG );
   return new Tibco::Rv::Status( status => $status );
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( defined $self->{id} );

   my ( $status ) = Tibco::Rv::tibrvcmTransport_Destroy( $self->{id} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Cm::Transport - Tibco Certified Messaging transport object

=head1 SYNOPSIS

   #$transport = new Tibco::Rv::Cm::Transport;

=head1 DESCRIPTION

A C<Tibco::Rv::Cm::Transport> object ...

=head1 CONSTRUCTOR

=over 4

=item $transport = new Tibco::Rv::Transport( %args )

   %args:
      ...

Creates a C<Tibco::Rv::Cm::Transport>.  If not specified ...

=back

=head1 METHODS

=over 4

=item FIX ALL THESE

=item $service = $transport->service

Returns the service setting C<$transport> is connected to.

=item $network = $transport->network

Returns the network setting C<$transport> is connected to.

=item $daemon = $transport->daemon

Returns the daemon setting C<$transport> is connected to.

=item $description = $transport->description

Returns the description of C<$transport>.

=item $transport->description( $description )

Sets the description of C<$transport>.  Description identifies this transport
to TIB/Rendezvous components.  It is displayed in the browser administration
interface.

=item $batchMode = $transport->batchMode

Returns the batchMode of C<$transport>.  If Tibco::Rv was built against
an Rv 6.x version, this method will always return
Tibco::Rv::Transport::DEFAULT_BATCH.

=item $transport->batchMode( $batchMode )

Sets the batchMode of C<$transport>.  See the L<Constants|"CONSTANTS">
section below for a discussion of the available batchModes.  If Tibco::Rv
was built against an Rv 6.x version, this method will die with a
Tibco::Rv::VERSION_MISMATCH Status message.

=item $transport->send( $msg )

Sends C<$msg> via C<$transport> on the subject specified by C<$msg>'s
sendSubject.

=item $reply = $transport->sendRequest( $request, $timeout )

Sends C<$request> (a L<Tibco::Rv::Msg|Tibco::Rv::Msg>) and waits for a reply
message.  This method blocks while waiting for a reply.  C<$timeout>
specifies how long it should wait for a reply.  Using
C<Tibco::Rv::WAIT_FOREVER> causes this method to wait indefinately for a
reply.

If C<$timeout> is not specified (or C<undef>), then this method uses
C<Tibco::Rv::WAIT_FOREVER>.

If C<$timeout> is something other than C<Tibco::Rv::WAIT_FOREVER> and that
timeout is reached before receiving a reply, then this method returns
C<undef>.

=item $transport->sendReply( $reply, $request )

Sends C<$reply> (a L<Tibco::Rv::Msg|Tibco::Rv::Msg>) in response to the
C<$request> message.  This method extracts the replySubject from C<$request>,
and uses it to send C<$reply>.

=item $inbox = $transport->createInbox

Returns a subject that is unique within C<$transport>'s domain.  If
C<$transport> is the L<Intra-Process Transport|"INTRA-PROCESS TRANSPORT">,
then $inbox is unique within this process; otherwise, $inbox is unique
across all processes within the local router domain.

Use createInbox to set up a subject for point-to-point communications.
That is, messages sent to this subject will go to a single destination.

createInbox should be used in conjunction with sendReply and sendRequest
to enable point-to-point communication, as follows:

On the replying end, create a listener that listens to some subject.  In
the callback of that listener, create a routine that sends a reply to
incoming requests via the sendReply method.

On the requesting end, create an inbox subject using createInbox.  Then,
create your request message, and use that message's replySubject method to
set the reply subject to be the inbox subject you just created.  Send that
request message via the transport's sendRequest method.  The sendRequest
method internally creates a listener and waits for the replying end to
send a reply.

=item $transport->DESTROY

Destroy this connection to a TIB/Rendezvous daemon after flushing all
outbound messages.  Events created with this transport are invalidated.
Called automatically when C<$transport> goes out of scope.  Calling
DESTROY more than once has no effect.

=back

=head1 SEE ALSO

L<Tibco::Rv::Transport>

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
