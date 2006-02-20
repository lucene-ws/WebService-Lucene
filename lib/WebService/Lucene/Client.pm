package WebService::Lucene::Client;

use strict;
use warnings;

use base qw( XML::Atom::Client Class::Accessor::Fast );

use WWW::OpenSearch;
use Carp;

use WebService::Lucene::Results;
use WebService::Lucene::XOXOParser;

__PACKAGE__->mk_accessors( qw( xoxoparser opensearch_clients ) );

=head1 NAME

WebService::Lucene::Client - Interface with Atom stores and OpenSearch targets

=head1 SYNOPSIS

    package My::Client;
    
    use base qw( WebService::Lucene::Client );
    
    # ...

=head1 DESCRIPTION

This module acts as a base class for any object that wants to
do HTTP interaction with the Lucene Web Service. It incorporates
L<XML::Atom::Client>, L<WWW::OpenSearch> and
L<WebService::Lucene::XOXOParser>.

=head1 METHODS

=head2 new( )

Creates a new instance and sets the C<opensearch_clients> and 
C<xoxoparser> settings.

=cut

sub new {
    my( $class ) = @_;
    
    my $self = $class->SUPER::new;
    
    $self->xoxoparser( WebService::Lucene::XOXOParser->new );
    $self->opensearch_clients( { } );
    
    return $self;
}

=head2 xoxoparser( [$parser] )

Accessor for an XOXOParser object.

=head2 opensearch_clients( [$clients] )

Accessor to a hashref of OpenSeach clients keyed by index name.

=head2 search( $query, [$options] )

Performs a search and returns a L<WebService::Lucene::Results> object.

=cut

sub search {
    my( $self, $query, $params ) = @_;
    my @indices = $self->_get_indices( $params );
    my $clients = $self->opensearch_clients;

    croak "No index specified" unless @indices;
   
    my $name  = join( ',', map { $_->name } @indices );
    
    my $client;
    unless( $client = $clients->{ $name } ) {
        my $url;
        if( @indices == 1 ) {
            $url = URI->new_abs( "opensearchdescription.xml", $indices[ 0 ]->url );
        }
        else {
            $url = URI->new_abs( "$name/opensearchdescription.xml", $self->base_url );
        }
        
        $client = WWW::OpenSearch->new( $url );
        $clients->{ $name } = $client;
    }
    
    my $response = $client->search( $query, $params );
    
    croak "Search failed: " . $response->status_line unless $response->is_success;
    
    return WebService::Lucene::Results->new_from_opensearch( $response );
}

=head2 _get_indices( [$options] )

Attempts to return a list of indices based on
the options pased in or the current object.

=cut

sub _get_indices {
    my( $self, $param ) = @_;
    
    $param ||= {};
    
    if( my $index = delete $param->{ index } ) {
        return $index;
    }
    elsif( my $indices = delete $param->{ indices } ) {
        return @$indices;
    }
    elsif( $self->can( 'url' ) ) {
        return $self;
    }
    
    return;
}

=head1 SEE ALSO

=over 4

=item * L<XML::Atom::Client>

=item * L<WWW::OpenSearch>

=back

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