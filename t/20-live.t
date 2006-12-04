use Test::More;

use strict;
use warnings;

plan skip_all => '$ENV{LUCENE_SERVER} not set' unless $ENV{ LUCENE_SERVER };
plan tests => 1;

use_ok( 'WebService::Lucene' );

my $index_name = '_temp' . $$;
my $service = WebService::Lucene->new( $ENV{ LUCENE_SERVER } );


