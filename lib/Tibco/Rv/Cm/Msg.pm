package Tibco::Rv::Cm::Msg;
use base qw/ Tibco::Rv::Msg /;


my ( %defaults );
BEGIN
{
   %defaults = ( CMTimeLimit => undef );
}


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( CMSender => undef, CMSequence => undef, %defaults );
   my ( %args ) = @_;
   foreach my $field ( keys %defaults )
   {
      next unless ( exists $args{$field} );
      $params{$field} = $args{$field};
      delete $args{$field};
   }
   my ( $self ) = $proto->SUPER::new( %args );

   @$self{ keys %params } = ( values %params );
   $self->CMTimeLimit( $params{CMTimeLimit} )
      if ( defined $params{CMTimeLimit} );

   return $self;
}


sub _adopt
{
   my ( $proto, $id ) = @_;
   my ( $self ) = $proto->SUPER::_adopt( $id );
   @$self{ qw/ CMSender CMSequence /, keys %defaults } =
      ( undef, undef, values %defaults );
   $self->_getCMValues;
   return $self;
}


sub _getCMValues
{
   my ( $self ) = @_;
   Tibco::Rv::Msg_GetCMValues(
      @$self{ qw/ id CMSender CMSequence CMTimeLimit / } );
}


sub CMSender { return shift->{CMSender} }
sub CMSequence { return shift->{CMSequence} }


sub CMTimeLimit
{
   my ( $self ) = shift;
   return @_ ? $self->_setCMTimeLimit( @_ ) : $self->{CMTimeLimit};
}


sub _setCMTimeLimit
{
   my ( $self, $CMTimeLimit ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvMsg_SetCMTimeLimit( $self->{id}, $CMTimeLimit );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{CMTimeLimit} = $CMTimeLimit;
}


1;
