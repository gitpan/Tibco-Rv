package Tibco::Rv::Msg;


use vars qw/ $VERSION /;
$VERSION = '0.99';


use constant FIELDNAME_MAX => 127;

use constant MSG => 1;
use constant DATETIME => 3;
use constant OPAQUE => 7;
use constant STRING => 8;
use constant BOOL => 9;
use constant I8 => 14;
use constant U8 => 15;
use constant I16 => 16;
use constant U16 => 17;
use constant I32 => 18;
use constant U32 => 19;
use constant I64 => 20;
use constant U64 => 21;
use constant F32 => 24;
use constant F64 => 25;
use constant IPPORT16 => 26;
use constant IPADDR32 => 27;
use constant ENCRYPTED => 32;
use constant NONE => 22;
use constant I8ARRAY => 34;
use constant U8ARRAY => 35;
use constant I16ARRAY => 36;
use constant U16ARRAY => 37;
use constant I32ARRAY => 38;
use constant U32ARRAY => 39;
use constant I64ARRAY => 40;
use constant U64ARRAY => 41;
use constant F32ARRAY => 44;
use constant F64ARRAY => 45;

use constant XML => 47;

use constant USER_FIRST => 128;
use constant USER_LAST => 255;

use constant NO_TAG => 0;


use Tibco::Rv::Msg::Field;


use overload '""' => 'toString';


my ( %defaults );
BEGIN { %defaults = ( sendSubject => undef, replySubject => undef ) }


sub new
{
   my ( $proto ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Tibco::Rv::Msg_Create( $self->{id} );
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
   my ( $self );
   my ( $class ) = ref( $proto );
   if ( $class )
   {
      $self->DESDTROY;
      @$self{ 'id', keys %defaults } = ( $id, values %defaults );
   } else {
      $self = bless $proto->_new( $id ), $proto;
   }
   $self->_getValues;
   return $self;
}


sub _getValues
{
   my ( $self ) = @_;
   Tibco::Rv::Msg_GetValues( @$self{ qw/ id sendSubject replySubject / } );
}


sub createField { shift; return new Tibco::Rv::Msg::Field( @_ ) }
sub createDateTime { shift; return new Tibco::Rv::Msg::DateTime( @_ ) }


sub copy
{
   my ( $self ) = @_;
   my ( $copy );
   my ( $status ) = Tibco::Rv::Msg_CreateCopy( $self->{id}, $copy );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return Tibco::Rv::Msg->_adopt( $copy );
}


sub createFromBytes
{
   my ( $proto, $bytes ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Tibco::Rv::Msg_CreateFromBytes( $self->{id}, $bytes );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub bytes
{
   my ( $self ) = @_;
   my ( $bytes );
   my ( $status ) = Tibco::Rv::Msg_GetAsBytes( $self->{id}, $bytes );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $bytes;
}


sub bytesCopy
{
   my ( $self ) = @_;
   my ( $bytes );
   my ( $status ) = Tibco::Rv::Msg_GetAsBytesCopy( $self->{id}, $bytes );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $bytes;
}


sub expand
{
   my ( $self, $additionalStorage ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvMsg_Expand( $self->{id}, $additionalStorage );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub reset
{
   my ( $self ) = @_;
   my ( $status ) = Tibco::Rv::tibrvMsg_Reset( $self->{id} );
   @$self{ keys %defaults } = values %defaults;
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub numFields
{
   my ( $self ) = @_;
   my ( $num );
   my ( $status ) = Tibco::Rv::Msg_GetNumFields( $self->{id}, $num );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $num;
}


sub byteSize
{
   my ( $self ) = @_;
   my ( $size );
   my ( $status ) = Tibco::Rv::Msg_GetByteSize( $self->{id}, $size );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $size;
}


sub toString
{
   my ( $self ) = @_;
   my ( $str );
   my ( $status ) = Tibco::Rv::Msg_ConvertToString( $self->{id}, $str );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $str;
}


sub sendSubject
{
   my ( $self ) = shift;
   return @_ ? $self->_setSendSubject( @_ ) : $self->{sendSubject};
}


sub _setSendSubject
{
   my ( $self, $subject ) = @_;
   my ( $status ) = Tibco::Rv::tibrvMsg_SetSendSubject( $self->{id}, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{sendSubject} = $subject;
}


sub replySubject
{
   my ( $self ) = shift;
   return @_ ? $self->_setReplySubject( @_ ) : $self->{replySubject};
}


sub _setReplySubject
{
   my ( $self, $subject ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvMsg_SetReplySubject( $self->{id}, $subject );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{replySubject} = $subject;
}


sub addField
{
   my ( $self, $field ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvMsg_AddField( $self->{id}, $field->{ptr} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub addBool { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddBoolEx', @_ ) }
sub addF32 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddF32Ex', @_ ) }
sub addF64 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddF64Ex', @_ ) }
sub addI8 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddI8Ex', @_ ) }
sub addI16 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddI16Ex', @_ ) }
sub addI32 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddI32Ex', @_ ) }
sub addI64 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddI64Ex', @_ ) }
sub addU8 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddU8Ex', @_ ) }
sub addU16 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddU16Ex', @_ ) }
sub addU32 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddU32Ex', @_ ) }
sub addU64 { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddU64Ex', @_ ) }
sub addIPPort16 { shift->_addScalar( 'Tibco::Rv::Msg_AddIPPort16', @_ ) }
sub addString { shift->_addScalar( 'Tibco::Rv::tibrvMsg_AddStringEx', @_ ) }
sub addOpaque { shift->_addScalar( 'Tibco::Rv::Msg_AddOpaque', @_ ) }
sub addXml { shift->_addScalar( 'Tibco::Rv::Msg_AddXml', @_ ) }


sub addIPAddr32
{
   my ( $self, $fieldName, $ipaddr32, $fieldId ) = @_;
   my ( $a, $b, $c, $d ) = split( /\./, $ipaddr32 );
   $ipaddr32 = ( $a << 24 ) + ( $b << 16 ) + ( $c << 8 ) + $d;
   $self->_addScalar( 'Tibco::Rv::Msg_AddIPAddr32',
      $fieldName, $ipaddr32, $fieldId );
}


sub addMsg
{
   my ( $self, $fieldName, $msg, $fieldId ) = @_;
   $self->_addScalar( 'Tibco::Rv::tibrvMsg_AddMsgEx',
      $fieldName, $msg->{id}, $fieldId );
}


sub addDateTime
{
   my ( $self, $fieldName, $date, $fieldId ) = @_;
   $self->_addScalar( 'Tibco::Rv::tibrvMsg_AddDateTimeEx',
      $fieldName, $date->{ptr}, $fieldId );
}


sub addF32Array { shift->_addArray( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub addF64Array { shift->_addArray( Tibco::Rv::Msg::F64ARRAY, @_ ) }
sub addI8Array { shift->_addArray( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub addI16Array { shift->_addArray( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub addI32Array { shift->_addArray( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub addI64Array { shift->_addArray( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub addU8Array { shift->_addArray( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub addU16Array { shift->_addArray( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub addU32Array { shift->_addArray( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub addU64Array { shift->_addArray( Tibco::Rv::Msg::U64ARRAY, @_ ) }


sub getField
{
   my ( $self, $fieldName, $fieldId ) = @_;
   my ( $field );
   my ( $status ) =
      Tibco::Rv::Msg_GetField( $self->{id}, $fieldName, $field, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg::Field->_adopt( $field ) : undef;
}


sub getBool { return shift->_getScalar( Tibco::Rv::Msg::BOOL, @_ ) }
sub getF32 { return shift->_getScalar( Tibco::Rv::Msg::F32, @_ ) }
sub getF64 { return shift->_getScalar( Tibco::Rv::Msg::F64, @_ ) }
sub getI8 { return shift->_getScalar( Tibco::Rv::Msg::I8, @_ ) }
sub getI16 { return shift->_getScalar( Tibco::Rv::Msg::I16, @_ ) }
sub getI32 { return shift->_getScalar( Tibco::Rv::Msg::I32, @_ ) }
sub getI64 { return shift->_getScalar( Tibco::Rv::Msg::I64, @_ ) }
sub getU8 { return shift->_getScalar( Tibco::Rv::Msg::U8, @_ ) }
sub getU16 { return shift->_getScalar( Tibco::Rv::Msg::U16, @_ ) }
sub getU32 { return shift->_getScalar( Tibco::Rv::Msg::U32, @_ ) }
sub getU64 { return shift->_getScalar( Tibco::Rv::Msg::U64, @_ ) }
sub getIPPort16 { return shift->_getScalar( Tibco::Rv::Msg::IPPORT16, @_ ) }
sub getString { return shift->_getScalar( Tibco::Rv::Msg::STRING, @_ ) }
sub getOpaque { return shift->_getScalar( Tibco::Rv::Msg::OPAQUE, @_ ) }
sub getXml { return shift->_getScalar( Tibco::Rv::Msg::XML, @_ ) }


sub getIPAddr32
{
   my ( $self, $fieldName, $fieldId ) = @_;
   my ( $ipaddr32 ) =
      $self->_getScalar( Tibco::Rv::Msg::IPADDR32, $fieldName, $fieldId );
   my ( $a, $b, $c, $d );
   $a = $ipaddr32; $a >>= 24; $ipaddr32 -= $a << 24;
   $b = $ipaddr32; $b >>= 16; $ipaddr32 -= $b << 16;
   $c = $ipaddr32; $c >>= 8; $ipaddr32 -= $c << 8;
   $d = $ipaddr32;
   return "$a.$b.$c.$d";
}


sub getMsg
{
   my ( $self, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $msg );
   my ( $status ) = Tibco::Rv::Msg_GetScalar( $self->{id},
      Tibco::Rv::Msg::MSG, $fieldName, $msg, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK ) ? Tibco::Rv::Msg->_adopt( $msg ) : undef;
}


sub getDateTime
{
   my ( $self, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $date );
   my ( $status ) = Tibco::Rv::Msg_GetScalar( $self->{id},
      Tibco::Rv::Msg::DATETIME, $fieldName, $date, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg::DateTime->_adopt( $date ) : undef;
}


sub getF32Array { return shift->_getArray( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub getF64Array { return shift->_getArray( Tibco::Rv::Msg::F64ARRAY, @_ ) }
sub getI8Array { return shift->_getArray( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub getI16Array { return shift->_getArray( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub getI32Array { return shift->_getArray( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub getI64Array { return shift->_getArray( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub getU8Array { return shift->_getArray( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub getU16Array { return shift->_getArray( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub getU32Array { return shift->_getArray( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub getU64Array { return shift->_getArray( Tibco::Rv::Msg::U64ARRAY, @_ ) }


sub getFieldByIndex
{
   my ( $self, $fieldIndex ) = @_;
   my ( $field );
   my ( $status ) =
      Tibco::Rv::Msg_GetFieldByIndex( $self->{id}, $field, $fieldIndex );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return Tibco::Rv::Msg::Field->_adopt( $field );
}


sub getFieldInstance
{
   my ( $self, $fieldName, $instance ) = @_;
   my ( $field );
   my ( $status ) = Tibco::Rv::Msg_GetFieldInstance( $self->{id}, $fieldName,
      $field, $instance );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK )
      ? Tibco::Rv::Msg::Field->_adopt( $field ) : undef;
}


sub removeField
{
   my ( $self, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) =
      Tibco::Rv::tibrvMsg_RemoveFieldEx( $self->{id}, $fieldName, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return new Tibco::Rv::Status( $status );
}


sub removeFieldInstance
{
   my ( $self, $fieldName, $instance ) = @_;
   my ( $status ) = Tibco::Rv::tibrvMsg_RemoveFieldInstance( $self->{id},
      $fieldName, $instance );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return new Tibco::Rv::Status( $status );
}


sub updateField
{
   my ( $self, $field ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvMsg_UpdateField( $self->{id}, $field->{ptr} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub updateBool { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateBoolEx', @_ ) }
sub updateF32 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateF32Ex', @_ ) }
sub updateF64 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateF64Ex', @_ ) }
sub updateI8 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateI8Ex', @_ ) }
sub updateI16 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateI16Ex', @_ ) }
sub updateI32 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateI32Ex', @_ ) }
sub updateI64 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateI64Ex', @_ ) }
sub updateU8 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateU8Ex', @_ ) }
sub updateU16 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateU16Ex', @_ ) }
sub updateU32 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateU32Ex', @_ ) }
sub updateU64 { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateU64Ex', @_ ) }
sub updateIPPort16 { shift->_updScalar( 'Tibco::Rv::Msg_UpdateIPPort16', @_ ) }
sub updateString
   { shift->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateStringEx', @_ ) }
sub updateOpaque { shift->_updScalar( 'Tibco::Rv::Msg_UpdateOpaque', @_ ) }
sub updateXml { shift->_updScalar( 'Tibco::Rv::Msg_UpdateXml', @_ ) }


sub updateIPAddr32
{
   my ( $self, $fieldName, $ipaddr32, $fieldId ) = @_;
   my ( $a, $b, $c, $d ) = split( /\./, $ipaddr32 );
   $ipaddr32 = ( $a << 24 ) + ( $b << 16 ) + ( $c << 8 ) + $d;
   $self->_updScalar( 'Tibco::Rv::Msg_UpdateIPAddr32',
      $fieldName, $ipaddr32, $fieldId );
}


sub updateMsg
{
   my ( $self, $fieldName, $msg, $fieldId ) = @_;
   $self->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateMsgEx',
      $fieldName, $msg->{id}, $fieldId );
}


sub updateDateTime
{
   my ( $self, $fieldName, $date, $fieldId ) = @_;
   $self->_updScalar( 'Tibco::Rv::tibrvMsg_UpdateDateTimeEx',
      $fieldName, $date->{ptr}, $fieldId );
}


sub updateF32Array { shift->_updArray( Tibco::Rv::Msg::F32ARRAY, @_ ) }
sub updateF64Array { shift->_updArray( Tibco::Rv::Msg::F64ARRAY, @_ ) }
sub updateI8Array { shift->_updArray( Tibco::Rv::Msg::I8ARRAY, @_ ) }
sub updateI16Array { shift->_updArray( Tibco::Rv::Msg::I16ARRAY, @_ ) }
sub updateI32Array { shift->_updArray( Tibco::Rv::Msg::I32ARRAY, @_ ) }
sub updateI64Array { shift->_updArray( Tibco::Rv::Msg::I64ARRAY, @_ ) }
sub updateU8Array { shift->_updArray( Tibco::Rv::Msg::U8ARRAY, @_ ) }
sub updateU16Array { shift->_updArray( Tibco::Rv::Msg::U16ARRAY, @_ ) }
sub updateU32Array { shift->_updArray( Tibco::Rv::Msg::U32ARRAY, @_ ) }
sub updateU64Array { shift->_updArray( Tibco::Rv::Msg::U64ARRAY, @_ ) }


sub clearReferences
{
   my ( $self ) = @_;
   my ( $status ) = Tibco::Rv::tibrvMsg_ClearReferences( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub markReferences
{
   my ( $self ) = @_;
   my ( $status ) = Tibco::Rv::tibrvMsg_MarkReferences( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub _addScalar
{
   my ( $self, $fxn, $fieldName, $value, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = $fxn->( $self->{id}, $fieldName, $value, $fieldId );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub _getScalar
{
   my ( $self, $type, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $value );
   my ( $status ) = Tibco::Rv::Msg_GetScalar( $self->{id}, $type, $fieldName,
      $value, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK ) ? $value : undef;
}


sub _updScalar
{
   my ( $self, $fxn, $fieldName, $value, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = $fxn->( $self->{id}, $fieldName, $value, $fieldId );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub _getArray
{
   my ( $self, $type, $fieldName, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $elts ) = [ ];
   my ( $status ) = Tibco::Rv::Msg_GetArray( $self->{id}, $type, $fieldName,
      $elts, $fieldId );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::NOT_FOUND );
   return ( $status == Tibco::Rv::OK ) ? $elts : undef;
}


sub _addArray { shift->_addOrUpdArray( Tibco::Rv::TRUE, @_ ) }
sub _updArray { shift->_addOrUpdArray( Tibco::Rv::FALSE, @_ ) }


sub _addOrUpdArray
{
   my ( $self, $isAdd, $type, $fieldName, $elts, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = Tibco::Rv::Msg_AddOrUpdateArray( $self->{id}, $isAdd,
      $type, $fieldName, $elts, $fieldId );
   die Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::tibrvMsg_Destroy( $self->{id} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;
