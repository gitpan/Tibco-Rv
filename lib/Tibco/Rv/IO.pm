package Tibco::Rv::IO;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION /;
$VERSION = '0.03';


# untested
sub new
{
   my ( $proto, $queue, $socketId, $ioType, $callback ) = @_;
   my ( $self ) = $proto->SUPER::new( $queue, $callback );

   @$self{ qw/ socketId ioType / } = ( $socketId, $ioType );

   my ( $status ) = Tibco::Rv::Event_CreateIO( $self->{id}, $self->{queue}{id},
      $self->{internal_nomsg_callback}, $self->{socketId}, $self->{ioType} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub socketId { return shift->{socketId} }
sub ioType { return shift->{ioType} }


1;
