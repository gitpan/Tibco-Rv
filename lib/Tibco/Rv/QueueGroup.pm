package Tibco::Rv::QueueGroup;


use vars qw/ $VERSION /;
$VERSION = '1.02';


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

   $queueGroup = new Tibco::Rv::QueueGroup;

   $queueGroup->add( $queue );

   while ( 1 ) { $queueGroup->dispatch }

=head1 DESCRIPTION

A C<Tibco::Rv::QueueGroup> manages a set of L<Queues|Tibco::Rv::Queue>.

=head1 CONSTRUCTOR

=over 4

=item $queueGroup = new Tibco::Rv::QueueGroup

Creates a C<Tibco::Rv::QueueGroup> without any queues.  Use a QueueGroup
to manage a set of Queues, by adding and removing queues, and dispatching
events across those queues.

=back

=head1 METHODS

=over 4

=item $dispatcher = $queueGroup->createDispatcher( %args )

   %args:
      name => $name,
      idleTimeout => $idleTimeout

Creates a L<Tibco::Rv::Dispatcher|Tibco::Rv::Dispatcher> with this
C<$queueGroup> as the dispatchable.  See the
L<Dispatcher constructor|Tibco::Rv::Dispatcher/"CONSTRUCTOR"> for more
details.

=item $queue = $queueGroup->createQueue( %args )

   %args:
      policy => $policy,
      maxEvents => $maxEvents,
      discardAmount => $discardAmount,
      name => $name,
      priority => $priority,
      hook => undef

Creates a L<Tibco::Rv::Queue|Tibco::Rv::Queue> and adds it to this
C<$queueGroup> before returning it.  See the
L<Queue constructor|Tibco::Rv::Queue/"CONSTRUCTOR"> for more info on the
C<%arg> parameters.

=item $queueGroup->add( $queue )

Add C<$queue> to this group.

=item $queueGroup->remove( $queue )

Removes C<$queue> from this group.  Dies with a Tibco::Rv::INVALID_QUEUE
Status message if C<$queue> is not actually in this group.

=item $queueGroup->dispatch

Dispatch a single event.  If there are no events currently on any of the
queues, then this method blocks until an event arrives.

=item $status = $queueGroup->poll

Dispatch a single event if there is at least one event waiting any of the
queues.  If there are no events on any of the queues, then this call
returns immediately.  Returns a Tibco::Rv::OK Status object if an event was
dispatched, or Tibco::Rv::TIMEOUT if there were no events on any queues.

=item $status = $queueGroup->timedDispatch( $timeout )

Dispatches a single event if there is at least one event waiting on any of
the queues, or if an event arrives before C<$timeout> seconds have passed.
In either case, returns Tibco::Rv::OK.  If C<$timeout> is reached before
dispatching an event, returns Tibco::Rv::TIMEOUT.  If Tibco::Rv::WAIT_FOREVER
is passed as C<$timeout>, behaves the same as C<dispatch>.  If
Tibco::Rv::NO_WAIT is passed as C<$timeout>, behaves the same as C<poll>.

=item $queueGroup->DESTROY

Destroys the queue group, but all queues in the group continue to exist.
Called automatically when C<$queueGroup> goes out of scope.  Calling DESTROY
more than once has no effect.

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
