package Tibco::Rv::Timer;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION /;
$VERSION = '0.90';


sub new
{
   my ( $proto, $queue, $interval, $callback ) = @_;
   my ( $self ) = $proto->SUPER::new( $queue, $callback );

   $self->{interval} = $interval;

   my ( $status ) = Tibco::Rv::Event_CreateTimer( $self->{id},
      $self->{queue}{id}, $self->{internal_nomsg_callback},
      $self->{interval} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub interval
{
   my ( $self ) = shift;
   return @_ ? $self->resetTimerInterval( @_ ) : $self->{interval};
}


sub resetTimerInterval
{
   my ( $self, $interval ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvEvent_ResetTimerInterval( $self->{id}, $interval );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{interval} = $interval;
}


1;
