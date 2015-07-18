package Devel::Examine::Subs::Preprocessor;

use strict; use warnings;

use Carp;
use Data::Dumper;

our $VERSION = '1.18';

sub new {
    my $self = {};
    bless $self, shift;

    my $struct = shift;

    $self->{pre_procs} = $self->_dt();

    return $self;
}

sub _dt {
    my $self = shift;

    my $dt = {
        module => \&module,
    };

    return $dt;
}

sub module {

    return sub {

        no strict 'refs';

        my $p = shift;

        if (! $p->{module} or $p->{module} eq ''){
            return [];
        }

        (my $module_file = $p->{module}) =~ s|::|/|g;

        require "$module_file.pm"
          or croak "Module $p->{module} not found: $!";

        my $namespace = "$p->{module}::";

        my @subs;

        for my $sub (keys %$namespace){
            if (defined &{$namespace . $sub}){
                push @subs, $sub;
            }
        }

        return \@subs;
    };
}

1;

