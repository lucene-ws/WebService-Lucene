use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'WebService::Lucene',
    dist_author        => 'Brian Cassidy <brian.cassidy@nald.ca>',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        'Class::Accessor'  => 0,
        'Data::Page'       => 0,
        'Encode'           => 0,
        'Exception::Class' => 0,
        'Scalar::Util'     => 0,
        'URI'              => 0,
        'WWW::OpenSearch'  => '0.11', # uses URI::Template
        'XML::Atom'        => '0.25', # fixes memleak
        'XML::LibXML'      => 0,
    },
    build_requres      => {
        'Test::More' => 0,
    }
);

$build->create_build_script;
