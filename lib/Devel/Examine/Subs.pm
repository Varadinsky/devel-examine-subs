package Devel::Examine::Subs;

use strict;
use warnings;

use Data::Dumper;

our $VERSION = '1.05';

sub new {
    my $self = {};
    bless $self, shift;
    return $self;
}
sub has {
    my $self    = shift;
    my $p       = shift;

    if ( ! exists $p->{ search } or $p->{ search } eq '' ){
        return ();
    }
    $p->{ want_what } = 'has';
    return @{ $self->_get( $p ) };
}
sub missing {
    my $self    = shift;
    my $p       = shift;

    if ( ! exists $p->{ search } or $p->{ search } eq '' ){
        return ();
    }
    $p->{ want_what } = 'missing';
    return @{ $self->_get( $p ) };
}
sub all {
    my $self    = shift;
    my $p       = shift;

    $p->{ want_what } = 'all';
    return @{ $self->_get( $p ) };
}
sub line_numbers {
    my $self = shift;
    my $p = shift;

    $p->{ want_what } = 'line_numbers';

    if ($p->{ get } and $p->{ get } =~ /obj/){
        return $self->sublist( $p );
    }
    else {
        return $self->_get( $p );
    }
}
sub _objects {

    my $self = shift;
    my $subs = shift;

    my @sub_list;

    package Devel::Examine::Subs::Sub;
        sub new {
            my $class = shift;
            my $data = shift;
            my $name = shift;

            my $self = bless {}, $class;

            $self->{data} = $data;
            $self->{name} = $name || '';
            $self->{start_line} = $data->{start};
            $self->{stop_line} = $data->{stop};
            if ($data->{stop} and $data->{start}){
                $self->{count_line} = $data->{stop} - $data->{start};
            }
                     
            return $self;
        }
        sub name {
            my $self = shift;
            return $self->{name};
        }
        sub start {
            my $self = shift;
            return $self->{start_line};
        }
        sub stop {
            my $self = shift;
            return $self->{stop_line};
        }
        sub count {
            my $self = shift;
            return $self->{count_line};
        }

    for my $sub (keys %$subs){
        my $obj = Devel::Examine::Subs::Sub->new($subs->{$sub}, $sub);
        push @sub_list, $obj;
    }

    $self->{sublist} = \@sub_list;
}
sub sublist {
    my $self = shift;
    my $p = shift;

    $p->{ want_what } = 'sublist';

    $self->_get($p);

    return $self->{sublist};
}
sub _get {
   
    my $self        = shift;
    my $p           = shift;
    my $file        = $p->{ file };
    my $search      = $p->{ search }; 
    my $want_what   = $p->{ want_what }; # 0=missing 1=has 2=all 3=names
    
    my $subs = _subs({
                        file => $file,
                        want => $search,
                    });

    # configure the object with the data

    if ($want_what eq 'sublist'){
        $self->_objects($subs);
    }

    # return early if we want all sub names
    
    return [ sort keys %$subs ] if $want_what eq 'all';

    # return if we want line nums

    if ( $want_what eq 'line_numbers' ){
        my @line_nums;

        for my $k ( keys %$subs ){
            delete $subs->{ $k }{ want };
        }
        return $subs;
    }

    # want_what eq sublist

    if ( $want_what eq 'sublist' ){
        return $subs;
    }
    
    my ( @has, @hasnt );

    for my $k ( keys %$subs ){
        push @has,   $k if $subs->{$k}{ want };
        push @hasnt, $k if ! $subs->{$k}{ want };
    }

    return \@has if $want_what eq 'has';
    return \@hasnt if $want_what eq 'missing';
}
sub _subs {

    my $p       = shift;
    my $file    = $p->{ file };
    my $want    = $p->{ want };
    open my $fh, '<', $file or die "Invalid file supplied: $!";

    my %subs;
    my $name; 
    
    while ( my $line = <$fh> ){
        if ( $line =~ /^sub\s/ ){
            $name = (split /\s+/, $line)[1];
            $subs{ $name }{ want } = 0;
            $subs{ $name }{ start } = $.;
            next;
        }
        if ( $name and $line =~ /^\}/ ){
            $subs{ $name }{ stop } = $.;
        }

        next if ! $name or ! $want;
        $subs{ $name }{ want } = 1 if $line =~ /$want/;

    }
    
    return \%subs;
}
sub _pod{} #vim placeholder
1;
__END__

=head1 NAME

Devel::Examine::Subs - Get information about subroutines within module and program files

=head1 SYNOPSIS

    use Devel::Examine::Subs;

    my $file = 'perl.pl';
    my $find = 'string';
    
    # get all sub names in a file

    my @subs = Devel::Examine::Subs->all({ file => $file });

    # list of sub names where the sub contains the text "string"
    
    my @has = Devel::Examine::Subs->has({ file => $file, search => $find });
    
    # same as has(), but returns the opposite
   
    my @missing = Devel::Examine::Subs->missing({ file => $file, search => $find });

    # get all sub names with their start and end line numbers in the file
    
    my $href = Devel::Examine::Subs->line_numbers({ file => $file })
    
    # There's also an OO interface to save typing if you will be making
    # multiple calls

    my $des = Devel::Examine::Subs->new({ file => $file });

    $des->all(...);
    $des->has(...);
    $des->missing(...);
    $des->line_numbers(...);
    
    # return an aref of subroutine objects

    $aref = $des->sublist(...)
    
    $aref->[0]->name() # name of sub
    $aref->[0]->start() # first line of sub
    $aref->[0]->stop() # last line of sub
    $aref->[0]->count() # number of lines in sub


=head1 DESCRIPTION

Reads into Perl program and module files returning the names
of its subroutines, optionally limiting the names returned to
subs that contain or do not contain specified text, or the
start and end line numbers of the sub.


=head1 METHODS

=head2 new

Instantiates a new object. This module was designed for one-off
calls through the class methods. Creating an object will save
keystrokes if multiple calls are required.

=head2 has( { file => $filename, search => $text } )

Takes the name of a file to search, and the text you want to
search for within each sub. Useful to find out which subs call
other methods.

Returns a list of names of the subs where the subroutine containes
the text. In scalar context, returns the count of subs containing
the found text.

=head2 missing( { file => $filename, search => $text } )

The exact opposite of has.

=head2 all( { file => $filename } )

Returns a list of the names of all subroutines found in the file.

=head2 line_numbers( { file => $filename, get => 'object' } )

If the optional parameter 'get' is not present or set to a
value of 'object' or 'obj', returns a hash of hashes. 
Top level keys are the function names, and the subkeys 'start' 
and 'stop' contain the line numbers of the respective position 
in the file for the subroutine.

If the optional parameter 'get' is sent in with a value of object,
will return an array reference of subroutine objects. Each object
has the following methods:

=head3 name()

Returns the name of the subroutine

=head3 start()

Returns the line number where the sub starts

=head3 stop()

Returns the line number where the sub ends

=head3 count()

Returns the number of lines in the subroutine

=head2 sublist({ file => $filename })

Returns an array reference of subroutine objects. See line_numbers()
with the 'get' parameter set for details.

=head1 CAVEATS

Subs that begin indented (such as closures and those within other
blocks) will not be counted. For line_numbers() the closing brace
must be in column one of the file as well.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Examine::Subs

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
