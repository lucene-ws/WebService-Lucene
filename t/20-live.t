use Test::More;

# TODO: Add error checking, and test it.

use strict;
use warnings;

plan skip_all => '$ENV{LUCENE_SERVER} not set' unless $ENV{ LUCENE_SERVER };
plan tests => 20;

use_ok( 'WebService::Lucene' );
use_ok( 'WebService::Lucene::Document' );

my $index_name = '_temp' . $$;
my $service = WebService::Lucene->new( $ENV{ LUCENE_SERVER } );
isa_ok( $service, 'WebService::Lucene' );

# fetch service properties
{
    my $properties = $service->properties;
    ok( keys %$properties );
    $properties->{ $index_name } = 1;
    $service->update;
    is( $properties->{ $index_name }, 1 );
    delete $properties->{ $index_name };
    $service->update;
    ok( ! defined $properties->{ $index_name } );
}

my $index = $service->create_index( $index_name );
isa_ok( $index, 'WebService::Lucene::Index' );

# fetch service document
{
    my @indices = $service->indices;
    ok( grep { $_->name eq $index_name } @indices );
    ok( $service->title );
}

# fetch index properties
{
    my $properties = $index->properties;
    # new indices have no properties!
    ok( !keys %$properties );
    $properties->{ $index_name } = 1;
    $index->update;
    is( $properties->{ $index_name }, 1 );
    delete $properties->{ $index_name };
    $index->update;
    ok( ! defined $properties->{ $index_name } );
}

# fetch OSD
{
    my $os_client = $index->opensearch_client;
    isa_ok( $os_client, 'WWW::OpenSearch' );
}

my $doc = WebService::Lucene::Document->new;
isa_ok( $doc, 'WebService::Lucene::Document' );

$doc->add_keyword( id  => 1 );
is( $doc->id, 1 );
$doc->add_text( foo => 'bar' );
is( $doc->foo, 'bar' );

$index->add_document( $doc );

my $doc1 = $index->get_document( 1 );
is( $doc1->id, 1 );
is( $doc1->foo, 'bar' );

$doc1->add_text( foo => 'baz' );
$doc1->update;

my $doc1u = $index->get_document( 1 );
is( $doc1u->id, 1 );
is_deeply( [ $doc1u->foo ], [ qw( bar baz ) ] );

$index->delete_document( 1 );
$index->optimize;

$service->delete_index( $index_name );
