package WebService::Lucene::Index;

use strict;
use warnings;

use base qw( WebService::Lucene::Client Class::Accessor::Fast );

use URI;
use Carp;
use HTTP::Request;

use WebService::Lucene::Results;
use WebService::Lucene::Document;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors( qw( url name properties properties_url ) );

=head1 NAME

WebService::Lucene::Index - Object to represent a Lucene Index

=head1 SYNOPSIS

    # Load the index from $url
    $index = WebService::Lucene::Index->new( { url => $url } );
    
    # Get most recently modified documents
    $results = $index->list;
    
    # Search the index
    $results = $index->search( 'foo' );
    
    # Get a document
    $doc = $index->get_document( $id );
    
    # Create a document
    $doc = $index->create_document( $doc );
    
    # Delete the index
    $index->delete;

=head1 DESCRIPTION

The module represents a Lucene Index.

=head1 METHODS

=head2 new( [$options] )

Create a new index. specifying a C<url> option
will attempt to load its details, otherwise the index
will not be tied to any web service until it is 
officially created.

=cut

sub new {
    my( $class, $params ) = @_;

    my $self  = $class->SUPER::new;
    $params ||= { };
    
    for( keys %$params ) {
        $self->$_( $params->{ $_ } );
    }

    if( my $url = $self->url ) {
        unless( $self->name ) {
            $url =~ /([^\/]+?)\/?$/;
            $self->name( $1 );
        }
        $self->properties_url( URI->new_abs( 'index.properties', $url ) );
        $self->fetch_index_properties;
    }
    
    unless( $self->properties ) {
        $self->properties( { } );
    }

    return $self;
}

=head2 url( [$url] )

Accessor for the index's url.

=head2 name( [$name] )

Accessor for the index's name.

=head2 properties( [$properties] )

Accessor for the index's properties.

=head2 properties_url( [$properties_url] )

Accessor for the index's properties url.

=head2 fetch_index_properties( )

Fetches the C<index.properties> entry and sends the contents
to C<parse_index_properties_xml>.

=cut

sub fetch_index_properties {
    my( $self ) = @_;
    my $entry   = $self->getEntry( $self->properties_url );
    $self->parse_index_properties_xml( $entry->content->body );
}

=head2 parse_index_properties_xml( $xml )

Parses the XOXO document and sets the C<properties> accessor.

=cut

sub parse_index_properties_xml {
    my( $self, $xml ) = @_;

    my $parser = $self->xoxoparser;
    
    $self->properties( {
        map { $_->{ name } => $_->{ value } } $parser->parse( $xml )
    } );
}

=head2 delete( )

Deletes the current index.

=cut

sub delete {
    my( $self ) = @_;
    $self->deleteEntry( $self->url );
}

=head2 update( )

Updates the C<index.properties> file with the current set of properties.

=cut

sub update {
    my( $self ) = @_;
    $self->updateEntry( $self->properties_url, $self->properties_as_entry );
}

=head2 list( )

Returns a L<WebService::Lucene::Results> object with a list of the recently updated documents.

=cut

sub list {
    my( $self ) = @_;
    return WebService::Lucene::Results->new_from_feed( $self->getFeed( $self->url ) );
}

=head2 optimize( )

Optimizes the index.

=cut

sub optimize {
    my( $self ) = @_;
    my $request = HTTP::Request->new( PUT => $self->url . '?optimize' );
    return $self->make_request( $request );
}

=head2 add_document( $document )

Adds C<$document> to the index.

=cut

sub add_document {
    my( $self, $document ) = @_;
    my $url = $self->createEntry( $self->url, $document->as_entry );
    
    croak $self->errstr unless $url;
    
    return WebService::Lucene::Document->new_from_entry( $self->getEntry( $url ) );
}

=head2 get_document( $id )

Returns a L<WebService::Lucene::Document>.

=cut

sub get_document {
    my( $self, $id ) = @_;
    my $entry = $self->getEntry( URI->new_abs( $id, $self->url ) );
    
    croak $self->errstr unless $entry;
    
    return WebService::Lucene::Document->new_from_entry( $entry );
}

=head2 properties_as_entry( )

Constructs an L<XML::Atom::Entry> object representing the index's properties.

=cut

sub properties_as_entry {
    my( $self ) = @_;
    
    my $entry = XML::Atom::Entry->new;
    $entry->title( $self->name );
    
    my $props      = $self->properties;
    my @properties = map +{ name => $_, value => $props->{ $_ } }, keys %$props;
    my $xml        = $self->xoxoparser->construct( @properties );
    
    $entry->content( $xml );
    $entry->content->type( 'xhtml' );
    
    return $entry;
}

=head2 title( )

Shortcut to get the title from the properties.

=cut

sub title {
    return shift->properties->{ 'index.title' };
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