use Test::More tests => 8;

use strict;
use warnings;

BEGIN {
	use_ok( 'WebService::Lucene' );
	use_ok( 'WebService::Lucene::Client' );
	use_ok( 'WebService::Lucene::Document' );
	use_ok( 'WebService::Lucene::Field' );
	use_ok( 'WebService::Lucene::Index' );
	use_ok( 'WebService::Lucene::Iterator' );
	use_ok( 'WebService::Lucene::Results' );
	use_ok( 'WebService::Lucene::XOXOParser' );
}

