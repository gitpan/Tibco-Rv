package Tibco::Rv::Event;


use vars qw/ $VERSION /;
$VERSION = '1.01';


use Tibco::Rv::Msg;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) =
      ( queue => $Tibco::Rv::Queue::DEFAULT, callback => sub { } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { queue => $params{queue}, id => undef }, $class;

   $self->{callback} = $params{callback};
   $self->{internal_nomsg_callback} = sub { $self->onEvent( ) };
   $self->{internal_msg_callback} =
      sub { $self->onEvent( Tibco::Rv::Msg->_adopt( shift ) ) };

   return $self;
}


sub queue { return shift->{queue} }
sub callback { return shift->{callback} }


sub onEvent
{
   my ( $self, @args ) = @_;
   $self->{callback}->( @args );
}


# callback not supported
sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::Event_DestroyEx( $self->{id} );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Event - Base class for Tibco events

=head1 SYNOPSIS

   use base qw/ Tibco::Rv::Event /;

   sub new
   {
      # ...
      my ( $self ) =
         $proto->SUPER::new( queue => $queue, callback => $callback );
      # ...
   }

=head1 DESCRIPTION

Base class for Tibco Events -- Listeners, Timers, and IO events.  Don't
use this directly.

=head1 CONSTRUCTOR

=over 4

=item $self = $proto->SUPER::new( %args )

   %args:
      queue => $queue,
      callback => sub { ... }

Creates a C<Tibco::Rv::Event>, or more specifically, one of the Event
subclasses -- Listener, Timer, or IO, with queue $queue (defaults to
$Tibco::Rv::Queue::DEFAULT if not specified), and the given callback
(defaults to sub { } if not specified).

=back

=head1 METHODS

=over 4

=item $queue = $event->queue

Returns the queue on which events will be dispatched.

=item $callback = $event->callback

Returns the callback code reference.

=item $event->onEvent

=item $event->onEvent( $msg )

Trigger an event directly.  Subclasses determine which version will be
called.  L<Listener|Tibco::Rv::Listener> objects use the version with a
C<$msg> parameter, L<Timer|Tibco::Rv::Timer> and L<IO|Tibco::Rv::IO>
objects use the version with no paramters.

=item $event->DESTROY

Cancels interest in this event.  Called automatically when C<$event>
goes out of scope.  Calling DESTROY more than once has no effect.

=back

=head1 SEE ALSO

=over 4

=item L<Tibco::Rv::Listener>

=item L<Tibco::Rv::Timer>

=item L<Tibco::Rv::IO>

=back

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
