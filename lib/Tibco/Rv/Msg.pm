package Tibco::Rv::Msg;


use vars qw/ $VERSION /;
$VERSION = '0.03';


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

use constant NO_TAG => 0;


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

   my ( $class ) = ref( $proto );
   return bless $proto->_new( $id ), $proto unless ( $class );

   $proto->DESTROY;
   @$proto{ 'id', keys %defaults } = ( $id, values %defaults );
}


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


sub addString
{
   my ( $self, $fieldName, $value, $fieldId ) = @_;
   $fieldId = 0 unless ( defined $fieldId );
   my ( $status ) = Tibco::Rv::tibrvMsg_AddStringEx( $self->{id}, $fieldName,
      $value, $fieldId );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


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


sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::tibrvMsg_Destroy( $self->{id} );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;
