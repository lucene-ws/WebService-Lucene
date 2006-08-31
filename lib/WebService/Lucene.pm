package WebService::Lucene;

use strict;
use warnings;

use base qw( WebService::Lucene::Client Class::Accessor::Fast );

use Carp;
use URI;
use XML::LibXML;

use WebService::Lucene::Index;
use XML::Atom::Entry;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors( qw( base_url properties_url indices_ref title properties ) );

=head1 NAME

WebService::Lucene - Module to interface with the Lucene indexing webservice

=head1 SYNOPSIS

    # Connect to the web service
    $ws = WebService::Lucene->new( $url );
    
    # Create an index
    $ndex = $ws->create_index( $index );
    
    # Get a particular index
    $index = $ws->get_index( $name );
    
    # Index a document
    $document = $index->add_document( $document );
    
    # Get a document
    $document = $index->get_document( $id );
    
    # Delete the document
    $document->delete;
    
    # Search an index
    $results = $index->search( $query );
    
    # Get documents from search
    @documents = $results->documents;
    
    # Delete an index
    $index->delete;

=head1 DESCRIPTION

This module is a Perl API in to the Lucene indexing web service.
http://lucene-ws.sourceforge.net/

=head1 METHODS

=head2 new( $url )

This method will connect to the Lucene Web Service located at C<$url>,
load it's settings and initialize all of its indices.

    my $ws = WebService::Lucene->new( 'http://localhost:8080/lucene/' );

=cut

sub new {
    my( $class, $url ) = @_;
    
    croak "No URL specified" unless $url;

    my $self = $class->SUPER::new;

    $self->base_url( URI->new( $url ) );
    $self->properties_url( URI->new_abs( 'service.properties', $self->base_url ) );
    $self->indices_ref( [ ] );
    $self->properties( { } );
    
    $self->fetch_service;
    $self->fetch_service_properties;

    return $self;
}

=head2 base_url( [$url] )

Accessor for the base url of the service.

=head2 fetch_service( )

Connects to the service url and passes the contents on to C<parse_service_xml>.

=cut

sub fetch_service {
    my( $self ) = @_;
    $self->parse_service_xml( $self->_fetch_content( $self->base_url ) );
}

=head2 parse_service_xml( $xml )

Parses the Atom Publishing Protocol introspection document and populates
the services C<indices>.

=cut

sub parse_service_xml {
    my( $self, $xml ) = @_;
    
    my $parser = XML::LibXML->new;
    my $doc    = $parser->parse_string( $xml );

    my @indices;
    my( $workspace ) = $doc->documentElement->getChildrenByTagName( 'workspace' );

    $self->title( $workspace->getAttributeNode( 'title' )->value );
    
    for my $collection ( $workspace->getChildrenByTagName( 'collection' ) ) {
        my $url  = $collection->getAttributeNode( 'href' )->value;

        push @indices,
            WebService::Lucene::Index->new( {
                url   => URI->new( $url )
            } )
    }
    
    $self->indices_ref( \@indices );
}

=head2 title( [$title] )

Accessor for the title of the service.

=head2 properties_url( [$url] )

Accessor for the C<service.properties> document url.

=head2 fetch_service_properties( )

Grabs the C<service.properties> documents and sends the contents
to C<parse_service_properties_xml>.

=cut

sub fetch_service_properties {
    my( $self ) = @_;
    my $entry   = $self->getEntry( $self->properties_url );
    $self->parse_service_properties_xml( $entry->content->body );
}

=head2 parse_service_properties_xml( $xml )

Parses the XML and populates the object's C<properties>

=cut

sub parse_service_properties_xml {
    my( $self, $xml ) = @_;

    my $parser = $self->xoxoparser;
    
    $self->properties( {
        map { $_->{ name } => $_->{ value } } $parser->parse( $xml )
    } );
}

=head2 properties( [$properties] )

Hash reference to a list of properties for the service.

=head2 indices_ref( [$indices] )

Array reference to a list of indices.

=head2 indices( )

Returns an array of L<WebService::Lucene::Index> objects.

=cut

sub indices {
    return @{ shift->indices_ref };
}

=head2 search( $query, $options )

Searches one or more indices for C<$query>. Returns an
L<WebService::Lucene::Results> object.

    my $results = $ws->search( 'foo', { indices => [ $index1, $index2 ] } );

=head2 get_index( $name )

Greps the list of indices to match C<$name> to index's name or title fields.

=cut

sub get_index {
    my( $self, $name ) = @_;

    # refresh the service ... this should be fixed at some point
    # $self->fetch_service;

    my @indices = grep { $_->name eq $name || ( $_->title || '' ) eq $name } $self->indices;

    return wantarray ? @indices : $indices[ 0 ];
}

=head2 create_index( $index )

Given a L<WebService::Lucene::Index> object it will create the
corresponding index on the server and return a index object.

=cut

sub create_index {
    my( $self, $index ) = @_;

    my $url = $self->createEntry( $self->base_url, $index->properties_as_entry );
    
    croak $self->errstr unless $url;
    
    return WebService::Lucene::Index->new( {
        name => $index->name,
        url  => $url
    } );
}

=head2 update( )

Updates the C<service.properties> document.

=cut

sub update {
    my( $self ) = @_;
    $self->updateEntry( $self->properties_url, $self->properties_as_entry );
}

=head2 properties_as_entry( )

Genereates an L<XML::Atom::Entry> suitable for updating
the C<service.properties> document.

=cut

sub properties_as_entry {
    my( $self ) = @_;
    
    my $entry = XML::Atom::Entry->new;
    $entry->title( 'service.properties' );
    
    my $props      = $self->properties;
    my @properties = map +{ name => $_, value => $props->{ $_ } }, keys %$props;
    my $xml        = $self->xoxoparser->construct( @properties );
    
    $entry->content( $xml );
    $entry->content->type( 'xhtml' );
    
    return $entry;
}

=head2 agent( )

Shortcut to the L<LWP::UserAgent> object.

=cut

sub agent {
    return shift->{ ua };
}

=head2 _fetch_content( $url )

Shortcut for fetching the content at C<$url>.

=cut

sub _fetch_content {
    my( $self, $url ) = @_;
    
    my $response = $self->agent->get( $url );
    
    unless( $response->is_success ) {
        croak "Error while fetching $url: " . $response->status_line;
    }
    
    return $response->content;
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
