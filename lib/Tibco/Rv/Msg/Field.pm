package Tibco::Rv::Msg::Field;


use vars qw/ $VERSION /;
$VERSION = '0.90';


use Tibco::Rv::Msg::DateTime;


my ( %defaults );
BEGIN
{
   %defaults = ( name => undef, id => 0,
      size => undef, count => undef, type => undef, data => undef );
}


sub new
{
   my ( $proto ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Tibco::Rv::MsgField_Create( $self->{ptr} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   $self->bool( Tibco::Rv::FALSE );

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
   Tibco::Rv::MsgField__GetValues(
      @$self{ qw/ ptr name id size count type data / } );
   if ( $self->{type} == Tibco::Rv::Msg::MSG )
   {
      $self->{data} = Tibco::Rv::Msg->_adopt( $self->{data} );
   } elsif ( $self->{type} == Tibco::Rv::Msg::DATETIME ) {
      $self->{data} = Tibco::Rv::Msg::DateTime->_adopt( $self->{data} );
   }
}


sub name
{
   my ( $self ) = shift;
   return @_ ? $self->_setName( @_ ) : $self->{name};
}


sub _setName
{
   my ( $self, $name ) = @_;
   Tibco::Rv::MsgField_SetName( $self->{ptr}, $name );
   return $self->{name} = $name;
}


sub id
{
   my ( $self ) = shift;
   return @_ ? $self->_setId( @_ ) : $self->{id};
}


sub _setId
{
   my ( $self, $id ) = @_;
   Tibco::Rv::MsgField_SetId( $self->{ptr}, $id );
   return $self->{id} = $id;
}


sub count { return shift->{count} }
sub size { return shift->{size} }
sub type { return shift->{type} }


sub msg
{
   my ( $self ) = shift;
   return @_ ? $self->_setMsg( @_ ) : $self->_get( Tibco::Rv::Msg::MSG );
}


sub str { return shift->_bufAccessor( Tibco::Rv::Msg::STRING, @_ ) }
sub opaque { return shift->_bufAccessor( Tibco::Rv::Msg::OPAQUE, @_ ) }
sub xml { return shift->_bufAccessor( Tibco::Rv::Msg::XML, @_ ) }

sub bool { return shift->_eltAccessor( Tibco::Rv::Msg::BOOL, @_ ) }
sub i8 { return shift->_eltAccessor( Tibco::Rv::Msg::I8, @_ ) }
sub u8 { return shift->_eltAccessor( Tibco::Rv::Msg::U8, @_ ) }
sub i16 { return shift->_eltAccessor( Tibco::Rv::Msg::I16, @_ ) }
sub u16 { return shift->_eltAccessor( Tibco::Rv::Msg::U16, @_ ) }
sub i32 { return shift->_eltAccessor( Tibco::Rv::Msg::I32, @_ ) }
sub u32 { return shift->_eltAccessor( Tibco::Rv::Msg::U32, @_ ) }
sub i64 { return shift->_eltAccessor( Tibco::Rv::Msg::I64, @_ ) }
sub u64 { return shift->_eltAccessor( Tibco::Rv::Msg::U64, @_ ) }
sub f32 { return shift->_eltAccessor( Tibco::Rv::Msg::F32, @_ ) }
sub f64 { return shift->_eltAccessor( Tibco::Rv::Msg::F64, @_ ) }
sub ipport16 { return shift->_eltAccessor( Tibco::Rv::Msg::IPPORT16, @_ ) }
sub ipaddr32 { return shift->_eltAccessor( Tibco::Rv::Msg::IPADDR32, @_ ) }
# ipaddr32 should accept dotted quad
# use Socket/inet_aton


sub date
{
   my ( $self ) = shift;
   return @_ ? $self->_setDate( @_ ) : $self->_get( Tibco::Rv::Msg::DATETIME );
}


sub _bufAccessor
{
   my ( $self ) = shift;
   my ( $type ) = shift;
   return @_ ? $self->_setBuf( @_, $type ) : $self->_get( $type );
}


sub _eltAccessor
{
   my ( $self ) = shift;
   my ( $type ) = shift;
   return @_ ? $self->_setElt( @_, $type ) : $self->_get( $type );
}


sub _setDate
{
   my ( $self, $date ) = @_;
   @$self{ qw/ data type count / } = ( $date, Tibco::Rv::Msg::DATETIME, 1 );
   $self->{size} =
      Tibco::Rv::MsgField__SetDateTime( $self->{ptr}, $self->{data}{ptr} );
   return $self->{data};
}


sub _get
{
   my ( $self, $type ) = @_;
   Tibco::Rv::die( Tibco::Rv::ARG_CONFLICT ) unless ( $self->{type} == $type );
   return $self->{data};
}


sub _setMsg
{
   my ( $self, $msg ) = @_;
   @$self{ qw/ data type count / } = ( $msg, Tibco::Rv::Msg::MSG, 1 );
   $self->{size} =
      Tibco::Rv::MsgField_SetMsg( $self->{ptr}, $self->{data}{id} );
   return $self->{data};
}


sub _setBuf
{
   my ( $self, $buf, $type ) = @_;
   @$self{ qw/ data type count / } = ( $buf, $type, 1 );
   $self->{size} =
      Tibco::Rv::MsgField__SetBuf( $self->{ptr}, $self->{data}, $type );
   $self->{data} = substr( $self->{data}, 0, $self->{size} )
      if ( $type == Tibco::Rv::Msg::STRING );
   return $self->{data};
}


sub _setElt
{
   my ( $self, $elt, $type ) = @_;
   @$self{ qw/ data type count / } = ( $elt, $type, 1 );
   $self->{size} =
      Tibco::Rv::MsgField__SetElt( @$self{ qw/ ptr data type / } );
   return $self->{data};
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{ptr} );

   my ( $status ) = Tibco::Rv::MsgField_Destroy( $self->{ptr} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;
