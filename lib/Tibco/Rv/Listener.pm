package Tibco::Rv::Listener;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION /;
$VERSION = '0.03';


sub new
{
   my ( $proto, $queue, $transport, $subject, $callback ) = @_;
   my ( $self ) = $proto->SUPER::new( $queue, $callback );

   @$self{ qw/ transport subject / } = ( $transport, $subject );

   my ( $status ) = Tibco::Rv::Event_CreateListener( $self->{id},
      $self->{queue}{id}, $self->{internal_msg_callback},
      $self->{transport}{id}, $self->{subject} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub transport { return shift->{transport} }
sub subject { return shift->{subject} }


1;
