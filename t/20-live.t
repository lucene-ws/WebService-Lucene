use Test::More;

use strict;
use warnings;
use Data::Dumper;
plan skip_all => '$ENV{LUCENE_SERVER} not set' unless $ENV{ LUCENE_SERVER };
plan tests => 9;

use_ok( 'WebService::Lucene' );
use_ok( 'WebService::Lucene::Document' );

my $index_name = '_temp' . $$;
my $service = WebService::Lucene->new( $ENV{ LUCENE_SERVER } );
isa_ok( $service, 'WebService::Lucene' );

my $index = $service->create_index( $index_name );
isa_ok( $index, 'WebService::Lucene::Index' );

my $doc = WebService::Lucene::Document->new;
isa_ok( $doc, 'WebService::Lucene::Document' );

$doc->add_keyword( id  => 1 );
is( scalar $doc->id, 1 );
$doc->add_text( foo => 'bar' );
is( $doc->foo, 'bar' );

$index->add_document( $doc );

my $doc1 = $index->get_document( 1 );
is( scalar $doc1->id, 1 );
is( $doc->foo, 'bar' );

$index->delete;
