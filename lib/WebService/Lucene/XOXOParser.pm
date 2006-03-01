package WebService::Lucene::XOXOParser;

use strict;
use warnings;

use XML::LibXML;
use CGI qw( dl dt dd escapeHTML );

=head1 NAME

WebService::Lucene::XOXOParser - Simple XOXO Parser

=head1 SYNOPSIS

    use WebService::Lucene::XOXOParser;
    
    my $parser     = WebService::Lucene::XOXOParser->new;
    my @properties = $parser->parse( $xml );

=head1 DESCRIPTION

This module provides simple XOXO parsing for Lucene documents.

=head1 METHODS

=head2 new( )

Creates a new parser instance.

=cut

sub new {
    my( $class ) = @_;
    return bless { }, $class;
}

=head2 parse( $xml )

Parses XML and returns an array of hashrefs decribing each
property.

=cut

sub parse {
    my( $self, $xml ) = @_;
    
    my $parser  = XML::LibXML->new;
    my $root    = $parser->parse_string( $xml )->documentElement;
    my @nodes   = $root->findnodes( '//dt | //dd' );

    my @properties;
    while ( @nodes ) {
        my( $term, $value ) = ( shift( @nodes ), shift( @nodes ) );

        my $property = {
            name  => $term->textContent,
            value => $value->textContent,
            map { $_->name => $_->value } $term->attributes
        };

        push @properties, $property;
    }

    return @properties;
}

=head2 construct( @properties )

Takes an array of properties and constructs
an XOXO XML structure.

=cut

sub construct {
    my( $self, @properties ) = @_;

    return dl(
	{ class => 'xoxo' },
        map {
            my $node = $_;
            dt(
                {
                    map {
                        $_ => $node->{ $_ }
                    } grep { $_ !~ /^(name|value)$/ } keys %$_
                },
                escapeHTML( $_->{ name } )
            ),
            dd(
                escapeHTML( $_->{ value } )
            )
        } @properties
    );
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