$^W = 0;

use Tibco::Rv;

print "1..20\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
my ( $msg ) = $rv->createMsg;
( defined $msg ) ? &ok : &nok;

( $msg->sendSubject( 'SEND' ) && $msg->sendSubject eq 'SEND' ) ? &ok : &nok;
( $msg->replySubject( 'REPLY' ) && $msg->replySubject eq 'REPLY' ) ? &ok : &nok;
$msg->addBool( bool => Tibco::Rv::TRUE, 1024 );
( $msg->addF32( f32 => 1.5 ) && $msg->getF32( 'f32' ) == 1.5 ) ? &ok : &nok;
( $msg->addF64( f64 => 1.5 ) && $msg->getF64( 'f64' ) == 1.5 ) ? &ok : &nok;
( $msg->addI8( i8 => -20 ) && $msg->getI8( 'i8' ) == -20 ) ? &ok : &nok;
( $msg->addI16( i16 => -20 ) && $msg->getI16( 'i16' ) == -20 ) ? &ok : &nok;
( $msg->addI32( i32 => -20 ) && $msg->getI32( 'i32' ) == -20 ) ? &ok : &nok;
( $msg->addI64( i64 => -20 ) && $msg->getI64( 'i64' ) == -20 ) ? &ok : &nok;
( $msg->addU8( u8 => 20 ) && $msg->getU8( 'u8' ) == 20 ) ? &ok : &nok;
( $msg->addU16( u16 => 20 ) && $msg->getU16( 'u16' ) == 20 ) ? &ok : &nok;
( $msg->addU32( u32 => 20 ) && $msg->getU32( 'u32' ) == 20 ) ? &ok : &nok;
( $msg->addU64( u64 => 20 ) && $msg->getU64( 'u64' ) == 20 ) ? &ok : &nok;
{
   my ( $copy ) = $msg->copy;
   my ( $bytes ) = $copy->bytes;
   undef $msg;
   $msg = Tibco::Rv::Msg->createFromBytes( $bytes );
   $msg->expand( 100 );
}
( $msg->numFields == 11 ) ? &ok : &nok;
$msg->reset;
$msg->markReferences;
( $msg->numFields == 0 ) ? &ok : &nok;
( $msg->sendSubject eq '' ) ? &ok : &nok;
$msg->clearReferences;
$msg->addIPAddr32( ipaddr32 => '10.1.21.156' );
$msg->addIPPort16( ipport16 => 1024 );
( "$msg" =~ /10\.1\.21\.156/ && "$msg" =~ /1024/ ) ? &ok : &nok;
my ( $field ) = $msg->createField;
( $msg->getField( 'ipaddr32' )->ipaddr32 eq '10.1.21.156' ) ? &ok : &nok;
( $msg->getField( 'ipport16' )->ipport16 == 1024 ) ? &ok : &nok;
$msg->addString( string => 'abc' );
$msg->addXml( xml => '<data>' . $msg->getString( 'string' ) . '</data>' );
$msg->addOpaque( opaque => $msg->getXml( 'xml' ) );
my ( $op ) = $msg->getOpaque( 'opaque' );
( $msg->getOpaque( 'opaque' ) eq '<data>abc</data>' ) ? &ok : &nok;


__DATA__
TODO
bytesCopy

add
Field/Msg/DateTime/Arrays

get
IPAddr32/IPort16/Msg/DateTime/Arrays

update
Field/Bool/F32/F64/I*/U*/IPAddr32/IPort16/String/Opaque/Xml/Msg/DateTime/Arrays

getFieldByIndex
getFieldInstance
removeField
removeFieldInstance
