package WebService::Lucene::Exception;

use strict;
use warnings;

use Exception::Class 'WebService::Lucene::Exception' =>
    { fields => [ qw( code status message stacktrace ) ] };
use base qw( Exception::Class::Base );

use XML::Atom::Entry;

=head1 NAME

WebService::Lucene::Exception - Exceptions to catch from the web service

=head1 SYNOPSIS

    my $entry = eval { $index->get_document( 1 ); };
    if( my $e = WebService::Lucene::Exception->caught ) {
        # handle exception
    }

=head1 DESCRIPTION

Object thrown for all exceptions from the web service.

=head1 METHODS

=head2 new( $reponse )

Constructs a new exception from an HTTP::Response.

=cut

sub new {
    my( $class, $response ) = @_;
    my $self = $class->SUPER::new;

    $self->{ code   } = $response->code;
    $self->{ status } = $response->status_line;

    my $source = XML::Atom::Entry->new( \$response->content );
    $self->{ source } = $source;
    $self->{ message } = $source->summary;

    my $content = $source->content;
    if( $content->type eq 'html' ) {
        $self->{ statcktrace } = $content->body;
    }

    return $self;
}

=head1 AUTHORS

=over 4

=item * Brian Cassidy E<lt>brian.cassidy@nald.caE<gt>

=item * Adam Paynter E<lt>adam.paynter@nald.caE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 National Adult Literacy Database

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
