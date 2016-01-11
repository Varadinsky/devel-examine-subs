#!perl 
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 6;

use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";

{
    my $rw = File::Edit::Portable->new;

    my $dir = 't';

    my @files = $rw->dir(
                    dir => $dir,
                    list => 1,
                );

    ok (@files >= 65, "with default extensions, the correct num of files is returned");

    @files = $rw->dir(
                    dir => $dir,
                    list => 1,
                    maxdepth => 1,
                );

    ok (@files >= 50 && @files <= 60, "things appear reasonable with maxdepth param set");

    @files = $rw->dir(
                dir => $dir,
                list => 1,
                types => [qw(*.t)],
            );

    is (@files, 53, "using *.t extension works properly");

    @files = $rw->dir(
                dir => $dir,
                list => 1,
                types => [qw(*.data)],
            );

    is (@files, 7, "using *.data extension works properly");

    @files = $rw->dir(
                dir => $dir,
                list => 1,
                types => [qw(*.data *.t)],
            );

    is (@files, 60, "using *.data and *.t extensions works properly");

}

