package Tibco::Rv::Msg::DateTime;


use vars qw/ $VERSION /;
$VERSION = '0.90';


my ( %defaults );
BEGIN
{
   %defaults = ( sec => 0, nsec => 0 );
}


use overload '""' => 'toString', '0+' => 'toNum', fallback => 1;


sub new
{
   my ( $proto ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Tibco::Rv::MsgDateTime_Create( $self->{ptr}, 0, 0 );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub _new
{
   my ( $class, $ptr ) = @_;
   return bless { ptr => $ptr, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $ptr ) = @_;
   my ( $self );
   my ( $class ) = ref( $proto );
   if ( $class )
   {
      $self = $proto;
      $self->DESTROY;
      @$self{ 'ptr', keys %defaults } = ( $ptr, values %defaults );
   } else {
      $self = bless $proto->_new( $ptr ), $proto;
   }
   $self->_getValues;
   return $self;
}


sub _getValues
{
   my ( $self ) = @_;
   Tibco::Rv::MsgDateTime__GetValues( @$self{ qw/ ptr sec nsec / } );
}


sub now
{
   my ( $self ) = @_;
   $self->sec( time );
   $self->nsec( 0 );
}


sub toString { return scalar( gmtime shift->{sec} ) . 'Z' }
sub toNum { return shift->{sec} } 


sub sec
{
   my ( $self ) = shift;
   return @_ ? $self->_setSec( @_ ) : $self->{sec};
}


sub nsec
{
   my ( $self ) = shift;
   return @_ ? $self->_setNsec( @_ ) : $self->{nsec};
}


sub _setSec
{
   my ( $self, $sec ) = @_;
   Tibco::Rv::MsgDateTime_SetSec( $self->{ptr}, $sec );
   return $self->{sec} = $sec;
}


sub _setNsec
{
   my ( $self, $nsec ) = @_;
   Tibco::Rv::MsgDateTime_SetNsec( $self->{ptr}, $nsec );
   return $self->{nsec} = $nsec;
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{ptr} );

   my ( $status ) = Tibco::Rv::MsgDateTime_Destroy( $self->{ptr} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;
