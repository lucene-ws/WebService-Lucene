package WebService::Lucene::Exception;

use strict;
use warnings;

use Exception::Class 'WebService::Lucene::Exception' =>
    { fields => [ qw( response entry stacktrace ) ] };
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

    $self->{ response } = $response;

    my $entry = XML::Atom::Entry->new( \$response->content );
    $self->{ entry   } = $entry;
    $self->{ message } = $entry->summary;

    my $content = $entry->content;
    if( $content->type eq 'html' ) {
        $self->{ statcktrace } = $content->body;
    }

    return $self;
}

=head2 response ( )

The L<HTTP::Response> object passed to this exception.

=head2 entry( )

The XML::Atom Entry for the error returned from the server.

=head2 stacktrace( )

If debug mode is enabled, a full stracktrace from the server-side will
be found here.

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
