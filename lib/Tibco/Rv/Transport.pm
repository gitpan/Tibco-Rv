package Tibco::Rv::Transport;


use vars qw/ $VERSION $PROCESS /;
$VERSION = '0.90';


use constant PROCESS_TRANSPORT => 10;

use constant DEFAULT_BATCH => 0;
use constant TIMER_BATCH => 1;


my ( %defaults );
BEGIN
{
   %defaults = ( service => undef, network => undef, daemon => 'tcp:7500',
      batchMode => DEFAULT_BATCH, description => '' );
}


sub new
{
   my ( $proto, $service, $network, $daemon ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   $self->{service} = $service if ( defined $service );
   $self->{network} = $network if ( defined $network );
   $self->{daemon} = $daemon if ( defined $daemon );

   my ( $status ) = Tibco::Rv::Transport_Create( $self->{id},
      $self->{service}, $self->{network}, $self->{daemon} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $id ) = @_;

   my ( $class ) = ref( $proto );
   return bless $proto->_new( $id ), $proto unless ( $class );

   $proto->DESTROY;
   @$proto{ 'id', keys %defaults } = ( $id, values %defaults );
}


sub service { return shift->{service} }
sub network { return shift->{network} }
sub daemon { return shift->{daemon} }


sub send
{
   my ( $self, $msg ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvTransport_Send( $self->{id}, $msg->{id} );
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
   my ( $status ) = Tibco::Rv::Transport_SendRequest( $self->{id},
      $request->{id}, $reply, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg->_adopt( $reply ) : undef;
}


sub description
{
   my ( $self ) = shift;
   return @_ ? $self->_setDescription( @_ ) : $self->{description};
}


sub _setDescription
{
   my ( $self, $description ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvTransport_SetDescription( $self->{id}, $description );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{description} = $description;
}


sub batchMode
{
   my ( $self ) = shift;
   return @_ ? $self->_setBatchMode( @_ ) : $self->{batchMode};
}


sub _setBatchMode
{
   my ( $self, $batchMode ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvTransport_SetBatchMode( $self->{id}, $batchMode );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{batchMode} = $batchMode;
}


sub createInbox
{
   my ( $self ) = @_;
   my ( $inbox );
   my ( $status ) = Tibco::Rv::Transport_CreateInbox( $self->{id}, $inbox );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $inbox;
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( defined $self->{id} );

   my ( $status ) = Tibco::Rv::tibrvTransport_Destroy( $self->{id} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


BEGIN { $PROCESS = Tibco::Rv::Transport->_adopt( PROCESS_TRANSPORT ) }


1;
