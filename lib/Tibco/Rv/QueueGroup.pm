package Tibco::Rv::QueueGroup;


use vars qw/ $VERSION /;
$VERSION = '1.01';


use Tibco::Rv::Queue;


sub new
{
   my ( $proto ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { id => undef }, $class;

   my ( $status ) = Tibco::Rv::QueueGroup_Create( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub createDispatcher
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Dispatcher( dispatchable => $self, %args );
}


sub createQueue
{
   my ( $self, %args ) = @_;
   my ( $queue ) = new Tibco::Rv::Queue( %args );
   $self->add( $queue );
   return $queue;
}


sub add
{
   my ( $self, $queue ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvQueueGroup_Add( $self->{id}, $queue->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub remove
{
   my ( $self, $queue ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvQueueGroup_Remove( $self->{id}, $queue->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub dispatch
{
   my ( $self ) = @_;
   return $self->timedDispatch( Tibco::Rv::WAIT_FOREVER );
}


sub poll
{
   my ( $self ) = @_;
   return $self->timedDispatch( Tibco::Rv::NO_WAIT );
}


sub timedDispatch
{
   my ( $self, $timeout ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvQueueGroup_TimedDispatch( $self->{id}, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return new Tibco::Rv::Status( status => $status );
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::QueueGroup_Destroy( $self->{id} );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::QueueGroup - Tibco Queue Group, queue managing object

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
